//
//  timestamp.h
//  Mac_iOSDemo
//
//  Created by Apple on 2020/10/4.
//  Copyright © 2020 JinTao. All rights reserved.
//

#ifndef timestamp_h
#define timestamp_h

/**
 tbr(time base of rate): 帧率, 从视频流中猜算得到, 帧率为25, 时间基为1/25
 tbn(time base of stream): 对应容器中的时间基。值是AVStream.time_base的倒数
 tbc(time base of codec): 对应编解码器中的时间基。值是AVCodecContext.time_base的倒数
 */


/**
 sonic: 音频处理的库, 如重采样, ffmpeg会变调, 这个可以实现不变调
 */

/**
 Xcode中忽略某个文件警告: BuildPhases -> CompileSources -> CompilerFlags 增加"-w"
 */


#endif /* timestamp_h */
