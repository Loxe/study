#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <libavcodec/avcodec.h>

#include <libavutil/channel_layout.h>
#include <libavutil/common.h>
#include <libavutil/frame.h>
#include <libavutil/samplefmt.h>

/* check that a given sample format is supported by the encoder */
static int check_sample_fmt(const AVCodec *codec, enum AVSampleFormat sample_fmt)
{
    const enum AVSampleFormat *p = codec->sample_fmts;
    
    while (*p != AV_SAMPLE_FMT_NONE) {
        if (*p == sample_fmt)
            return 1;
        p++;
    }
    return 0;
}

/* just pick the highest supported samplerate */
static int select_sample_rate(const AVCodec *codec)
{
    const int *p;
    int best_samplerate = 0;
    
    if (!codec->supported_samplerates)
        return 44100;
    
    p = codec->supported_samplerates;
    while (*p) {
        if (!best_samplerate || abs(44100 - *p) < abs(44100 - best_samplerate))
            best_samplerate = *p;
        p++;
    }
    return best_samplerate;
}

/* select layout with the highest channel count */
static int select_channel_layout(const AVCodec *codec)
{
    const uint64_t *p;
    uint64_t best_ch_layout = 0;
    int best_nb_channels   = 0;
    
    if (!codec->channel_layouts)
        return AV_CH_LAYOUT_STEREO;
    
    p = codec->channel_layouts;
    while (*p) {
        int nb_channels = av_get_channel_layout_nb_channels(*p);
        
        if (nb_channels > best_nb_channels) {
            best_ch_layout    = *p;
            best_nb_channels = nb_channels;
        }
        p++;
    }
    return (int)best_ch_layout;
}

int encode_audio(const char *filename)
{
    if (!filename) {
        printf("file name error, filenaem:%s\n", filename);
        return -1;
    }
    
    const AVCodec *codec;
    AVCodecContext *codecContext = NULL;
    AVFrame *frame;
    AVPacket pkt;
    int i, j, k, ret, got_output;
    FILE *file;
    uint16_t *samples;
    float t, tincr;
    
    /* register all the codecs */
    avcodec_register_all();
    
    /* find the MP2 encoder */
    codec = avcodec_find_encoder(AV_CODEC_ID_MP2);
    if (!codec) {
        fprintf(stderr, "Codec not found\n");
        return -1;
    }
    
    codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        fprintf(stderr, "Could not allocate audio codec context\n");
        return -1;
    }
    
    /* put sample parameters */
    codecContext->bit_rate = 64000;
    
    /* check that the encoder supports s16 pcm input */
    codecContext->sample_fmt = AV_SAMPLE_FMT_S16;
    if (!check_sample_fmt(codec, codecContext->sample_fmt)) {
        fprintf(stderr, "Encoder does not support sample format %s",
                av_get_sample_fmt_name(codecContext->sample_fmt));
        return -1;
    }
    
    /* select other audio parameters supported by the encoder */
    codecContext->sample_rate    = select_sample_rate(codec);
    codecContext->channel_layout = select_channel_layout(codec);
    codecContext->channels       = av_get_channel_layout_nb_channels(codecContext->channel_layout);
    
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
    
    /* frame containing input raw audio */
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate audio frame\n");
        return -1;
    }
    
    frame->nb_samples     = codecContext->frame_size;
    frame->format         = codecContext->sample_fmt;
    frame->channel_layout = codecContext->channel_layout;
    
    /* allocate the data buffers */
    ret = av_frame_get_buffer(frame, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not allocate audio data buffers\n");
        return -1;
    }
    
    /* encode a single tone sound */
    t = 0;
    tincr = 2 * M_PI * 440.0 / codecContext->sample_rate;
    for (i = 0; i < 200; i++) {
        //---------- 这里是自己造的数据, 数据是乱写的 begin -------------
        av_init_packet(&pkt);
        pkt.data = NULL; // packet data will be allocated by the encoder
        pkt.size = 0;
        
        /* make sure the frame is writable -- makes a copy if the encoder
         * kept a reference internally */
        ret = av_frame_make_writable(frame);
        if (ret < 0)
            return -1;
        samples = (uint16_t *)frame->data[0];
        
        for (j = 0; j < codecContext->frame_size; j++) {
            samples[2 * j] = (int)(sin(t) * 10000);
            
            for (k = 1; k < codecContext->channels; k++)
                samples[2*j + k] = samples[2*j];
            t += tincr;
        }
        //---------- 这里是自己造的数据, 数据是乱写的 end -------------
        
        /* encode the samples */
        ret = avcodec_encode_audio2(codecContext, &pkt, frame, &got_output);
        if (ret < 0) {
            fprintf(stderr, "Error encoding audio frame\n");
            return -1;
        }
        if (got_output) {
            fwrite(pkt.data, 1, pkt.size, file);
            av_packet_unref(&pkt);
        }
    }
    
    /* get the delayed frames */
    for (got_output = 1; got_output; i++) {
        ret = avcodec_encode_audio2(codecContext, &pkt, NULL, &got_output);
        if (ret < 0) {
            fprintf(stderr, "Error encoding frame\n");
            return -1;
        }
        
        if (got_output) {
            fwrite(pkt.data, 1, pkt.size, file);
            av_packet_unref(&pkt);
        }
    }
    fclose(file);
    
    av_frame_free(&frame);
    avcodec_free_context(&codecContext);
    
    return 0;
}
