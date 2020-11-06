#include <stdio.h>
#include <libavutil/log.h>
#include <libavformat/avio.h>


int ffmpeg_readFile(char *src_filename)
{
    int err_code;
    char errors[1024];
    
    AVIOContext *avio_ctx = NULL;
    
    int len;
    unsigned char buf[1024];
    
    av_log_set_level(AV_LOG_DEBUG);
    
    if(!src_filename){
        av_log(NULL, AV_LOG_DEBUG, "Invalid src filename\n");
        return -1;
    }
    
    if((err_code = avio_open(&avio_ctx, src_filename, AVIO_FLAG_READ)) < 0){
        av_log(NULL, AV_LOG_DEBUG, "Could not open file %s\n", src_filename);
        return -1;
    }
    
    len = avio_read(avio_ctx, buf, 1024);
    if(len < 0){
        av_strerror(len, errors, 1024);
        av_log(NULL, AV_LOG_ERROR, "Failed to read file %s\n", errors);
    }else {
        av_log(NULL, AV_LOG_DEBUG, "The length is %d(%s)\n", len, buf);
    }
    
    avio_close(avio_ctx);
    
    return 0;
}
