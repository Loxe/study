#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libavcodec/avcodec.h>

#include <libavutil/opt.h>
#include <libavutil/imgutils.h>

int encode_video(const char *filename, const char *codec_name)
{
    if (!filename || !codec_name) {
        printf("file name error, filenaem:%s codec_name:%s\n", filename, codec_name);
        return -1;
    }
    
    const AVCodec *codec;
    AVCodecContext *codecContext = NULL;
    int i, ret, x, y, got_output;
    FILE *file;
    AVFrame *frame;
    AVPacket pkt;
    uint8_t endcode[] = { 0, 0, 1, 0xb7 };
    
    avcodec_register_all();
    
    /* find the mpeg1video encoder */
    codec = avcodec_find_encoder_by_name(codec_name);
    if (!codec) {
        fprintf(stderr, "Codec not found\n");
        return -1;
    }
    
    codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        fprintf(stderr, "Could not allocate video codec context\n");
        return -1;
    }
    
    /* put sample parameters */
    codecContext->bit_rate = 400000;
    /* resolution must be a multiple of two */
    codecContext->width = 352;
    codecContext->height = 288;
    /* frames per second */
    codecContext->time_base = (AVRational){1, 25};
    codecContext->framerate = (AVRational){25, 1};
    
    /* emit one intra frame every ten frames
     * check frame pict_type before passing frame
     * to encoder, if frame->pict_type is AV_PICTURE_TYPE_I
     * then gop_size is ignored and the output of encoder
     * will always be I frame irrespective to gop_size
     */
    codecContext->gop_size = 10;
    codecContext->max_b_frames = 1;
    codecContext->pix_fmt = AV_PIX_FMT_YUV420P;
    
    if (codec->id == AV_CODEC_ID_H264)
        av_opt_set(codecContext->priv_data, "preset", "slow", 0);
    
    /* open it */
    if (avcodec_open2(codecContext, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        return -1;
    }
    
    file = fopen(filename, "wb");
    if (!file) {
        fprintf(stderr, "Could not open %s\n", filename);
        return -1;
    }
    
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        return -1;
    }
    frame->format = codecContext->pix_fmt;
    frame->width  = codecContext->width;
    frame->height = codecContext->height;
    
    ret = av_frame_get_buffer(frame, 32);
    if (ret < 0) {
        fprintf(stderr, "Could not allocate the video frame data\n");
        return -1;
    }
    
    /* encode 1 second of video */
    for (i = 0; i < 25; i++) {
        av_init_packet(&pkt);
        pkt.data = NULL;    // packet data will be allocated by the encoder
        pkt.size = 0;
        
        fflush(stdout);
        
        /* make sure the frame data is writable */
        ret = av_frame_make_writable(frame);
        if (ret < 0)
            return -1;
        
        /* prepare a dummy image */
        /* Y */
        for (y = 0; y < codecContext->height; y++) {
            for (x = 0; x < codecContext->width; x++) {
                frame->data[0][y * frame->linesize[0] + x] = x + y + i * 3;
            }
        }
        
        /* Cb and Cr */
        for (y = 0; y < codecContext->height/2; y++) {
            for (x = 0; x < codecContext->width/2; x++) {
                frame->data[1][y * frame->linesize[1] + x] = 128 + y + i * 2;
                frame->data[2][y * frame->linesize[2] + x] = 64 + x + i * 5;
            }
        }
        
        frame->pts = i;
        
        /* encode the image */
        ret = avcodec_encode_video2(codecContext, &pkt, frame, &got_output);
        if (ret < 0) {
            fprintf(stderr, "Error encoding frame\n");
            return -1;
        }
        
        if (got_output) {
            printf("Write frame %3d (size=%5d)\n", i, pkt.size);
            fwrite(pkt.data, 1, pkt.size, file);
            av_packet_unref(&pkt);
        }
    }
    
    /* get the delayed frames */
    for (got_output = 1; got_output; i++) {
        fflush(stdout);
        
        ret = avcodec_encode_video2(codecContext, &pkt, NULL, &got_output);
        if (ret < 0) {
            fprintf(stderr, "Error encoding frame\n");
            return -1;
        }
        
        if (got_output) {
            printf("Write frame %3d (size=%5d)\n", i, pkt.size);
            fwrite(pkt.data, 1, pkt.size, file);
            av_packet_unref(&pkt);
        }
    }
    
    /* add sequence end code to have a real MPEG file */
    fwrite(endcode, 1, sizeof(endcode), file);
    fclose(file);
    
    avcodec_free_context(&codecContext);
    av_frame_free(&frame);
    
    return 0;
}
