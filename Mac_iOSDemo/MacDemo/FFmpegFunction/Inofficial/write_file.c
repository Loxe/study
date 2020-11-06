#include <stdio.h>
#include <libavutil/log.h>
#include <libavformat/avio.h>


int ffmpeg_writeFile(char *src_filename)
{
    int err_code;
    AVIOContext *avio_ctx = NULL;
    
    unsigned char buf[] = "hello world!";
    
    av_log_set_level(AV_LOG_DEBUG);
    if(!src_filename){
        av_log(NULL, AV_LOG_DEBUG, "Invalid src filename\n");
        return -1;
    }
    
    if((err_code = avio_open(&avio_ctx, src_filename, AVIO_FLAG_WRITE)) < 0){
        av_log(NULL, AV_LOG_DEBUG, "Could not open file %s\n", src_filename);
        return -1;
    }
    
    avio_write(avio_ctx, buf, 12);
    
    avio_close(avio_ctx);
    
    return 0;
}
