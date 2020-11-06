#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <libavutil/frame.h>
#include <libavutil/mem.h>

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>

#define AUDIO_INBUF_SIZE 20480
#define AUDIO_REFILL_THRESH 4096
#define MAX_AUDIO_FRAME_SIZE 192000

int decode_audio(const char *filename, const char *outfilename)
{
    if (!filename || !outfilename) {
        printf("file name error, filenaem:%s outfilename:%s\n", filename, outfilename);
        return -1;
    }
    
    int i, ret;
    
    int err_code;
    char errors[1024];
    
    int audiostream_index = -1;
    
    AVFormatContext *pFormatCtx = NULL;
    
    const AVCodec *codec;
    AVCodecContext *codecContext= NULL;
    
    int len;
    FILE *outfile;
    //uint8_t inbuf[AUDIO_INBUF_SIZE + AV_INPUT_BUFFER_PADDING_SIZE];
    
    AVPacket avpkt;
    AVFrame *decoded_frame = NULL;
    
    /* register all the codecs */
    av_register_all();
    
    av_init_packet(&avpkt);
    
    /* open input file, and allocate format context */
    if ((err_code = avformat_open_input(&pFormatCtx, filename, NULL, NULL)) < 0) {
        av_strerror(err_code, errors, 1024);
        fprintf(stderr, "Could not open source file %s, %d(%s)\n", filename, err_code, errors);
        return -1;
    }
    
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx, NULL)<0)
        return -1; // Couldn't find stream information
    
    // Dump information about file onto standard error
    av_dump_format(pFormatCtx, 0, filename, 0);
    
    for(i = 0; i < pFormatCtx->nb_streams; i++) {
        if(pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
            audiostream_index = i;
        }
    }
    
    /* find the MPEG audio decoder */
    //codec = avcodec_find_decoder_by_name("libfdk_aac");
    //codec = avcodec_find_decoder(pFormatCtx->streams[audiostream_index]->codec->codec_id/*AV_CODEC_ID_MP2*/);
    /*
     if (!codec) {
     fprintf(stderr, "Codec not found\n");
     return -1;
     }
     */
    
    codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext) {
        fprintf(stderr, "Could not allocate audio codec context\n");
        return -1;
    }
    
    ret = avcodec_parameters_to_context(codecContext, pFormatCtx->streams[audiostream_index]->codecpar);
    if (ret < 0) {
        return -1;
    }
    
    codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec) {
        fprintf(stderr, "Codec not found\n");
        return -1;
    }
    
    //Out Audio Param
    uint64_t out_channel_layout = AV_CH_LAYOUT_STEREO;
    
    //AAC:1024  MP3:1152
    int out_nb_samples = codecContext->frame_size;
    //AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;
    int out_sample_rate = 44100;
    int out_channels = av_get_channel_layout_nb_channels(out_channel_layout);
    //Out Buffer Size
    int out_buffer_size = av_samples_get_buffer_size(NULL,
                                                     out_channels,
                                                     out_nb_samples,
                                                     AV_SAMPLE_FMT_S16,
                                                     1);
    
    uint8_t *out_buffer = (uint8_t *)av_malloc(MAX_AUDIO_FRAME_SIZE * 2);
    int64_t in_channel_layout = av_get_default_channel_layout(codecContext->channels);
    
    struct SwrContext *audio_convert_ctx;
    audio_convert_ctx = swr_alloc();
    audio_convert_ctx = swr_alloc_set_opts(audio_convert_ctx,
                                           out_channel_layout,
                                           AV_SAMPLE_FMT_S16,
                                           out_sample_rate,
                                           in_channel_layout,
                                           codecContext->sample_fmt,
                                           codecContext->sample_rate,
                                           0,
                                           NULL);
    swr_init(audio_convert_ctx);
    
    /* open it */
    if (avcodec_open2(codecContext, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        return -1;
    }
    
    /*
     f = fopen(filename, "rb");
     if (!f) {
     fprintf(stderr, "Could not open %s\n", filename);
     return -1;
     }
     */
    
    outfile = fopen(outfilename, "wb");
    if (!outfile) {
        av_free(codecContext);
        return -1;
    }
    
    /* decode until eof */
    /*
     avpkt.data = inbuf;
     avpkt.size = fread(inbuf, 1, AUDIO_INBUF_SIZE, f);
     */
    
    while (1) {
        int got_frame = 0;
        
        if (!decoded_frame) {
            if (!(decoded_frame = av_frame_alloc())) {
                fprintf(stderr, "Could not allocate audio frame\n");
                return -1;
            }
        }
        
        if(av_read_frame(pFormatCtx, &avpkt) < 0) {
            if(pFormatCtx->pb->error == 0) {
                usleep(100); /* no error; wait for user input */
                continue;
            } else {
                break;
            }
        }
        
        if(avpkt.stream_index != audiostream_index){
            av_packet_unref(&avpkt);
            continue;
        }
        
        len = avcodec_decode_audio4(codecContext, decoded_frame, &got_frame, &avpkt);
        if (len < 0) {
            av_strerror(len, errors, 1024);
            fprintf(stderr, "Error while decoding, err_code:%d, err:%s\n", len, errors);
            return -1;
        }
        if (got_frame) {
            /* if a frame has been decoded, output it */
            int data_size = av_get_bytes_per_sample(codecContext->sample_fmt);
            if (data_size < 0) {
                /* This should not occur, checking just for paranoia */
                fprintf(stderr, "Failed to calculate data size\n");
                return -1;
            }
            swr_convert(audio_convert_ctx,
                        &out_buffer,
                        MAX_AUDIO_FRAME_SIZE,
                        (const uint8_t **)decoded_frame->data,
                        decoded_frame->nb_samples);
            
            fwrite(out_buffer, 1, out_buffer_size, outfile);
            
            /*
             for (i=0; i<decoded_frame->nb_samples; i++)
             for (ch=0; ch<c->channels; ch++)
             fwrite(decoded_frame->data[ch] + data_size*i, 1, data_size, outfile);
             */
        }
        avpkt.size -= len;
        avpkt.data += len;
        avpkt.dts =
        avpkt.pts = AV_NOPTS_VALUE;
        
        //if (avpkt.size < AUDIO_REFILL_THRESH) {
        /* Refill the input buffer, to avoid trying to decode
         * incomplete frames. Instead of this, one could also use
         * a parser, or use a proper container format through
         * libavformat. */
        /*
         memmove(inbuf, avpkt.data, avpkt.size);
         avpkt.data = inbuf;
         len = fread(avpkt.data + avpkt.size, 1,
         AUDIO_INBUF_SIZE - avpkt.size, f);
         if (len > 0)
         avpkt.size += len;
         }
         */
    }
    
    fclose(outfile);
    //fclose(f);
    
    avcodec_free_context(&codecContext);
    av_frame_free(&decoded_frame);
    
    return 0;
}
