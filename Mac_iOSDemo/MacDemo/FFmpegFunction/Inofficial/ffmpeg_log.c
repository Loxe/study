#include <stdio.h>
#include <libavutil/log.h>

int ffmpeg_log()
{
    av_log_set_level(AV_LOG_DEBUG);
    
    av_log(NULL, AV_LOG_DEBUG, "hello world!\n");
    
    return 0;
}
