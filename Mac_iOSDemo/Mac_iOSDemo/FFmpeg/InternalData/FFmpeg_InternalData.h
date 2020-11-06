//
//  FFmpeg_InternalData.h
//  Mac_iOSDemo
//
//  Created by Apple on 2020/10/25.
//  Copyright © 2020 JinTao. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#include "bytestream.h"
#pragma clang diagnostic pop


#ifndef FFmpeg_InternalData_h
#define FFmpeg_InternalData_h

// 下面这些数据是ffmpeg源码里面的, 只是头文件没有, 在这再声明一下

#ifndef kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder
#  define kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder CFSTR("RequireHardwareAcceleratedVideoDecoder")
#endif

#define VIDEOTOOLBOX_ESDS_EXTRADATA_PADDING  12

#define AV_W8(p, v) *(p) = (v)

static av_always_inline void bytestream2_init_writer(PutByteContext *p, uint8_t *buf, int buf_size);

int ff_isom_write_avcc(AVIOContext *pb, const uint8_t *data, int len);

#endif /* FFmpeg_InternalData_h */
