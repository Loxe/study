//
//  HZFFmpegManager.m
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/18.
//  Copyright © 2020 JinTao. All rights reserved.
//


#import "HZFFmpegManager.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
// ffmpeg 用@import导入不了, 用脚本编译的没有model, 在工程设置中加入编译的头文件, 用常规方法导入
//@import FFmpeg;
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/imgutils.h"
#pragma clang diagnostic pop

#include "FFmpeg_InternalData.h"

#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>
#include <string.h>
#import "HZVideoToolboxDecoder.h"

#define HZFFMPEG_IMAGE_DEBUG 0


@interface HZFFmpegManager () <HZVideoToolboxDecoderDelegate> {
    //FFmpeg
    AVFormatContext    *_pFormatCtx;
    int                _videoindex;
    AVCodecContext    *_pCodecCtx;
    AVCodec            *_pCodec;
    AVFrame    *_pFrame;
    AVFrame    *_pTargetFrame;
    uint8_t *_targetBuffer;
    AVPacket *_packet;
    //AVPacket _flustPacket;
    struct SwsContext *_img_convert_ctx;
    
    CVPixelBufferRef _pixelBuffer;
    BOOL _stop;
    BOOL _lostIFrame;
}
@property (nonatomic, assign) NSInteger degreee;
@property (nonatomic, assign) HZMTKViewDrawMode drawMode;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) HZVideoToolboxDecoder *videoToolboxDecoder;

@end

@implementation HZFFmpegManager

/// rtcp 返回数据的回调函数
int rtcp_sr_cb(void *opaque, uint8_t *buf, int len) {
    HZFFmpegManager *ffmpegManager = (__bridge HZFFmpegManager *)(opaque);
    if (ffmpegManager.delegate && [ffmpegManager.delegate respondsToSelector:@selector(player:didReceiveRtcpSrData:)]) {
        NSData *data = [[NSData alloc] initWithBytes:buf length:len];
        [ffmpegManager.delegate player:ffmpegManager didReceiveRtcpSrData:data];
    }
    return 0;
}

// 下面的代码是从ffmpeg里面复制出来的
#pragma mark - ffmpeg源码 开始 ----------------------------

/// 获取视频数据, h264的sps和pps等
//static CFDictionaryRef videotoolbox_decoder_config_create(CMVideoCodecType codec_type,
//                                                          AVCodecContext *avctx)
//{
//    CFMutableDictionaryRef config_info = CFDictionaryCreateMutable(kCFAllocatorDefault,
//                                                                   0,
//                                                                   &kCFTypeDictionaryKeyCallBacks,
//                                                                   &kCFTypeDictionaryValueCallBacks);
//
//    CFDictionarySetValue(config_info,
//                         kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder,
//                         kCFBooleanTrue);
//
//    if (avctx->extradata_size) {
//        CFMutableDictionaryRef avc_info;
//        CFDataRef data = NULL;
//
//        avc_info = CFDictionaryCreateMutable(kCFAllocatorDefault,
//                                             1,
//                                             &kCFTypeDictionaryKeyCallBacks,
//                                             &kCFTypeDictionaryValueCallBacks);
//
//        switch (codec_type) {
//            case kCMVideoCodecType_MPEG4Video :
//                data = videotoolbox_esds_extradata_create(avctx);
//                if (data)
//                    CFDictionarySetValue(avc_info, CFSTR("esds"), data);
//                break;
//            case kCMVideoCodecType_H264 :
//                data = ff_videotoolbox_avcc_extradata_create(avctx);
//                if (data)
//                    CFDictionarySetValue(avc_info, CFSTR("avcC"), data);
//                break;
//            case kCMVideoCodecType_HEVC :
//                //data = ff_videotoolbox_hvcc_extradata_create(avctx);
//                if (data)
//                    CFDictionarySetValue(avc_info, CFSTR("hvcC"), data);
//                break;
//            default:
//                break;
//        }
//
//        CFDictionarySetValue(config_info,
//                             kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms,
//                             avc_info);
//
//        if (data)
//            CFRelease(data);
//
//        CFRelease(avc_info);
//    }
//    return config_info;
//}

static CFDataRef videotoolbox_esds_extradata_create(AVCodecContext *avctx)
{
    CFDataRef data;
    uint8_t *rw_extradata;
    PutByteContext pb;
    int full_size = 3 + 5 + 13 + 5 + avctx->extradata_size + 3;
    // ES_DescrTag data + DecoderConfigDescrTag + data + DecSpecificInfoTag + size + SLConfigDescriptor
    int config_size = 13 + 5 + avctx->extradata_size;
    int s;

    if (!(rw_extradata = av_mallocz(full_size + VIDEOTOOLBOX_ESDS_EXTRADATA_PADDING)))
        return NULL;

    bytestream2_init_writer(&pb, rw_extradata, full_size + VIDEOTOOLBOX_ESDS_EXTRADATA_PADDING);
    bytestream2_put_byteu(&pb, 0);        // version
    bytestream2_put_ne24(&pb, 0);         // flags

    // elementary stream descriptor
    bytestream2_put_byteu(&pb, 0x03);     // ES_DescrTag
    videotoolbox_write_mp4_descr_length(&pb, full_size);
    bytestream2_put_ne16(&pb, 0);         // esid
    bytestream2_put_byteu(&pb, 0);        // stream priority (0-32)

    // decoder configuration descriptor
    bytestream2_put_byteu(&pb, 0x04);     // DecoderConfigDescrTag
    videotoolbox_write_mp4_descr_length(&pb, config_size);
    bytestream2_put_byteu(&pb, 32);       // object type indication. 32 = AV_CODEC_ID_MPEG4
    bytestream2_put_byteu(&pb, 0x11);     // stream type
    bytestream2_put_ne24(&pb, 0);         // buffer size
    bytestream2_put_ne32(&pb, 0);         // max bitrate
    bytestream2_put_ne32(&pb, 0);         // avg bitrate

    // decoder specific descriptor
    bytestream2_put_byteu(&pb, 0x05);     ///< DecSpecificInfoTag
    videotoolbox_write_mp4_descr_length(&pb, avctx->extradata_size);

    bytestream2_put_buffer(&pb, avctx->extradata, avctx->extradata_size);

    // SLConfigDescriptor
    bytestream2_put_byteu(&pb, 0x06);     // SLConfigDescrTag
    bytestream2_put_byteu(&pb, 0x01);     // length
    bytestream2_put_byteu(&pb, 0x02);     //

    s = bytestream2_size_p(&pb);

    data = CFDataCreate(kCFAllocatorDefault, rw_extradata, s);

    av_freep(&rw_extradata);
    return data;
}

static void videotoolbox_write_mp4_descr_length(PutByteContext *pb, int length)
{
    int i;
    uint8_t b;

    for (i = 3; i >= 0; i--) {
        b = (length >> (i * 7)) & 0x7F;
        if (i != 0)
            b |= 0x80;

        bytestream2_put_byteu(pb, b);
    }
}

//CFDataRef ff_videotoolbox_avcc_extradata_create(AVCodecContext *avctx)
//{
//    H264Context *h     = avctx->priv_data;
//    CFDataRef data = NULL;
//    uint8_t *p;
//    int vt_extradata_size = 6 + 2 + h->ps.sps->data_size + 3 + h->ps.pps->data_size;
//    uint8_t *vt_extradata = av_malloc(vt_extradata_size);
//    if (!vt_extradata)
//        return NULL;
//
//    p = vt_extradata;
//
//    AV_W8(p + 0, 1); /* version */
//    AV_W8(p + 1, h->ps.sps->data[1]); /* profile */
//    AV_W8(p + 2, h->ps.sps->data[2]); /* profile compat */
//    AV_W8(p + 3, h->ps.sps->data[3]); /* level */
//    AV_W8(p + 4, 0xff); /* 6 bits reserved (111111) + 2 bits nal size length - 3 (11) */
//    AV_W8(p + 5, 0xe1); /* 3 bits reserved (111) + 5 bits number of sps (00001) */
//    AV_WB16(p + 6, h->ps.sps->data_size);
//    memcpy(p + 8, h->ps.sps->data, h->ps.sps->data_size);
//    p += 8 + h->ps.sps->data_size;
//    AV_W8(p + 0, 1); /* number of pps */
//    AV_WB16(p + 1, h->ps.pps->data_size);
//    memcpy(p + 3, h->ps.pps->data, h->ps.pps->data_size);
//
//    p += 3 + h->ps.pps->data_size;
//    av_assert0(p - vt_extradata == vt_extradata_size);
//
//    data = CFDataCreate(kCFAllocatorDefault, vt_extradata, vt_extradata_size);
//    av_free(vt_extradata);
//    return data;
//}

//CFDataRef ff_videotoolbox_hvcc_extradata_create(AVCodecContext *avctx)
//{
//    HEVCContext *h = avctx->priv_data;
//    const HEVCVPS *vps = (const HEVCVPS *)h->ps.vps_list[0]->data;
//    const HEVCSPS *sps = (const HEVCSPS *)h->ps.sps_list[0]->data;
//    int i, num_pps = 0;
//    const HEVCPPS *pps = h->ps.pps;
//    PTLCommon ptlc = vps->ptl.general_ptl;
//    VUI vui = sps->vui;
//    uint8_t parallelismType;
//    CFDataRef data = NULL;
//    uint8_t *p;
//    int vt_extradata_size = 23 + 5 + vps->data_size + 5 + sps->data_size + 3;
//    uint8_t *vt_extradata;
//
//    for (i = 0; i < MAX_PPS_COUNT; i++) {
//        if (h->ps.pps_list[i]) {
//            const HEVCPPS *pps = (const HEVCPPS *)h->ps.pps_list[i]->data;
//            vt_extradata_size += 2 + pps->data_size;
//            num_pps++;
//        }
//    }
//
//    vt_extradata = av_malloc(vt_extradata_size);
//    if (!vt_extradata)
//        return NULL;
//    p = vt_extradata;
//
//    /* unsigned int(8) configurationVersion = 1; */
//    AV_W8(p + 0, 1);
//
//    /*
//     * unsigned int(2) general_profile_space;
//     * unsigned int(1) general_tier_flag;
//     * unsigned int(5) general_profile_idc;
//     */
//    AV_W8(p + 1, ptlc.profile_space << 6 |
//          ptlc.tier_flag     << 5 |
//          ptlc.profile_idc);
//
//    /* unsigned int(32) general_profile_compatibility_flags; */
//    memcpy(p + 2, ptlc.profile_compatibility_flag, 4);
//
//    /* unsigned int(48) general_constraint_indicator_flags; */
//    AV_W8(p + 6, ptlc.progressive_source_flag    << 7 |
//          ptlc.interlaced_source_flag     << 6 |
//          ptlc.non_packed_constraint_flag << 5 |
//          ptlc.frame_only_constraint_flag << 4);
//    AV_W8(p + 7, 0);
//    AV_WN32(p + 8, 0);
//
//    /* unsigned int(8) general_level_idc; */
//    AV_W8(p + 12, ptlc.level_idc);
//
//    /*
//     * bit(4) reserved = ‘1111’b;
//     * unsigned int(12) min_spatial_segmentation_idc;
//     */
//    AV_W8(p + 13, 0xf0 | (vui.min_spatial_segmentation_idc >> 4));
//    AV_W8(p + 14, vui.min_spatial_segmentation_idc & 0xff);
//
//    /*
//     * bit(6) reserved = ‘111111’b;
//     * unsigned int(2) parallelismType;
//     */
//    if (!vui.min_spatial_segmentation_idc)
//        parallelismType = 0;
//    else if (pps->entropy_coding_sync_enabled_flag && pps->tiles_enabled_flag)
//        parallelismType = 0;
//    else if (pps->entropy_coding_sync_enabled_flag)
//        parallelismType = 3;
//    else if (pps->tiles_enabled_flag)
//        parallelismType = 2;
//    else
//        parallelismType = 1;
//    AV_W8(p + 15, 0xfc | parallelismType);
//
//    /*
//     * bit(6) reserved = ‘111111’b;
//     * unsigned int(2) chromaFormat;
//     */
//    AV_W8(p + 16, sps->chroma_format_idc | 0xfc);
//
//    /*
//     * bit(5) reserved = ‘11111’b;
//     * unsigned int(3) bitDepthLumaMinus8;
//     */
//    AV_W8(p + 17, (sps->bit_depth - 8) | 0xfc);
//
//    /*
//     * bit(5) reserved = ‘11111’b;
//     * unsigned int(3) bitDepthChromaMinus8;
//     */
//    AV_W8(p + 18, (sps->bit_depth_chroma - 8) | 0xfc);
//
//    /* bit(16) avgFrameRate; */
//    AV_WB16(p + 19, 0);
//
//    /*
//     * bit(2) constantFrameRate;
//     * bit(3) numTemporalLayers;
//     * bit(1) temporalIdNested;
//     * unsigned int(2) lengthSizeMinusOne;
//     */
//    AV_W8(p + 21, 0                             << 6 |
//          sps->max_sub_layers           << 3 |
//          sps->temporal_id_nesting_flag << 2 |
//          3);
//
//    /* unsigned int(8) numOfArrays; */
//    AV_W8(p + 22, 3);
//
//    p += 23;
//    /* vps */
//    /*
//     * bit(1) array_completeness;
//     * unsigned int(1) reserved = 0;
//     * unsigned int(6) NAL_unit_type;
//     */
//    AV_W8(p, 1 << 7 |
//          HEVC_NAL_VPS & 0x3f);
//    /* unsigned int(16) numNalus; */
//    AV_WB16(p + 1, 1);
//    /* unsigned int(16) nalUnitLength; */
//    AV_WB16(p + 3, vps->data_size);
//    /* bit(8*nalUnitLength) nalUnit; */
//    memcpy(p + 5, vps->data, vps->data_size);
//    p += 5 + vps->data_size;
//
//    /* sps */
//    AV_W8(p, 1 << 7 |
//          HEVC_NAL_SPS & 0x3f);
//    AV_WB16(p + 1, 1);
//    AV_WB16(p + 3, sps->data_size);
//    memcpy(p + 5, sps->data, sps->data_size);
//    p += 5 + sps->data_size;
//
//    /* pps */
//    AV_W8(p, 1 << 7 |
//          HEVC_NAL_PPS & 0x3f);
//    AV_WB16(p + 1, num_pps);
//    p += 3;
//    for (i = 0; i < MAX_PPS_COUNT; i++) {
//        if (h->ps.pps_list[i]) {
//            const HEVCPPS *pps = (const HEVCPPS *)h->ps.pps_list[i]->data;
//            AV_WB16(p, pps->data_size);
//            memcpy(p + 2, pps->data, pps->data_size);
//            p += 2 + pps->data_size;
//        }
//    }
//
//    av_assert0(p - vt_extradata == vt_extradata_size);
//
//    data = CFDataCreate(kCFAllocatorDefault, vt_extradata, vt_extradata_size);
//    av_free(vt_extradata);
//    return data;
//}
#pragma mark ffmpeg源码 结束 ----------------------------

#pragma mark - IJK源码 开始 -------------------------------
CFDataRef videotoolbox_getH264OrHEVCData(AVCodecParameters *codecpar) {
    int width           = codecpar->width;
    int height          = codecpar->height;
    int sps_level       = 0;
    int sps_profile     = 0;
    int extrasize       = codecpar->extradata_size;
    int codec           = codecpar->codec_id;
    uint8_t* extradata  = codecpar->extradata;
    
    bool isHevcSupported = false;
    CMVideoCodecType format_id = 0;
    
    if (width < 0 || height < 0) {
        return NULL;
    }
    
    if (extrasize < 7 || extradata == NULL) {
        NSLog(@"%s - avcC or hvcC atom data too small or missing", __FUNCTION__);
        return NULL;
    }
    
    switch (codec) {
        case AV_CODEC_ID_HEVC:
            format_id = kCMVideoCodecType_HEVC;
            if (@available(iOS 11.0, *)) {
                isHevcSupported = VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC);
            } else {
                isHevcSupported = false;
            }
            if (!isHevcSupported) {
                return NULL;
            }
            break;
            
        case AV_CODEC_ID_H264:
            format_id = kCMVideoCodecType_H264;
            break;
            
        default:
            return NULL;
    }
    
    if (extradata[0] == 1) {
        
        if (extradata[4] == 0xFE) {
            extradata[4] = 0xFF;
        }
        CFDataRef data = CFDataCreate(kCFAllocatorDefault, extradata, extrasize);
        return data;
    } else {
        if ((extradata[0] == 0 && extradata[1] == 0 && extradata[2] == 0 && extradata[3] == 1) ||
            (extradata[0] == 0 && extradata[1] == 0 && extradata[2] == 1)) {
            AVIOContext *pb;
            if (avio_open_dyn_buf(&pb) < 0) {
                return NULL;
            }
            
            ff_isom_write_avcc(pb, extradata, extrasize);
            extradata = NULL;
            
            extrasize = avio_close_dyn_buf(pb, &extradata);
            
            if (!validate_avcC_spc(extradata, extrasize, &sps_level, &sps_profile)) {
                av_free(extradata);
                return NULL;
            }
            
            av_free(extradata);
            
            CFDataRef data = CFDataCreate(kCFAllocatorDefault, extradata, extrasize);
            return data;
        } else {
            NSLog(@"%s - invalid avcC atom data", __FUNCTION__);
            return NULL;
        }
    }
    
    return NULL;
}

static bool validate_avcC_spc(uint8_t *extradata, uint32_t extrasize, int *level, int *profile) {
    // check the avcC atom's sps for number of reference frames and
    // bail if interlaced, VDA does not handle interlaced h264.
    bool interlaced = true;
    uint8_t *spc = extradata + 6;
    uint32_t sps_size = AV_RB16(spc);
    if (sps_size)
        parseh264_sps(spc+3, sps_size-1, level, profile, &interlaced);
    if (interlaced)
        return false;
    return true;
}


typedef struct
{
    const uint8_t *data;
    const uint8_t *end;
    int head;
    uint64_t cache;
} nal_bitstream;

typedef struct {
    uint64_t profile_idc;
    uint64_t level_idc;
    uint64_t sps_id;

    uint64_t chroma_format_idc;
    uint64_t separate_colour_plane_flag;
    uint64_t bit_depth_luma_minus8;
    uint64_t bit_depth_chroma_minus8;
    uint64_t qpprime_y_zero_transform_bypass_flag;
    uint64_t seq_scaling_matrix_present_flag;

    uint64_t log2_max_frame_num_minus4;
    uint64_t pic_order_cnt_type;
    uint64_t log2_max_pic_order_cnt_lsb_minus4;

    uint64_t max_num_ref_frames;
    uint64_t gaps_in_frame_num_value_allowed_flag;
    uint64_t pic_width_in_mbs_minus1;
    uint64_t pic_height_in_map_units_minus1;

    uint64_t frame_mbs_only_flag;
    uint64_t mb_adaptive_frame_field_flag;

    uint64_t direct_8x8_inference_flag;

    uint64_t frame_cropping_flag;
    uint64_t frame_crop_left_offset;
    uint64_t frame_crop_right_offset;
    uint64_t frame_crop_top_offset;
    uint64_t frame_crop_bottom_offset;
} sps_info_struct;

static void
nal_bs_init(nal_bitstream *bs, const uint8_t *data, size_t size) {
    bs->data = data;
    bs->end  = data + size;
    bs->head = 0;
    // fill with something other than 0 to detect
    //  emulation prevention bytes
    bs->cache = 0xffffffff;
}

static uint64_t
nal_bs_read(nal_bitstream *bs, int n)
{
    uint64_t res = 0;
    int shift;

    if (n == 0)
        return res;

    // fill up the cache if we need to
    while (bs->head < n) {
        uint8_t a_byte;
        bool check_three_byte;

        check_three_byte = true;
    next_byte:
        if (bs->data >= bs->end) {
            // we're at the end, can't produce more than head number of bits
            n = bs->head;
            break;
        }
        // get the byte, this can be an emulation_prevention_three_byte that we need
        // to ignore.
        a_byte = *bs->data++;
        if (check_three_byte && a_byte == 0x03 && ((bs->cache & 0xffff) == 0)) {
            // next byte goes unconditionally to the cache, even if it's 0x03
            check_three_byte = false;
            goto next_byte;
        }
        // shift bytes in cache, moving the head bits of the cache left
        bs->cache = (bs->cache << 8) | a_byte;
        bs->head += 8;
    }

    // bring the required bits down and truncate
    if ((shift = bs->head - n) > 0)
        res = bs->cache >> shift;
    else
        res = bs->cache;

    // mask out required bits
    if (n < 32)
        res &= (1 << n) - 1;

    bs->head = shift;

    return res;
}

static bool
nal_bs_eos(nal_bitstream *bs)
{
    return (bs->data >= bs->end) && (bs->head == 0);
}

static int64_t
nal_bs_read_ue(nal_bitstream *bs)
{
    int i = 0;

    while (nal_bs_read(bs, 1) == 0 && !nal_bs_eos(bs) && i < 32)
        i++;

    return ((1 << i) - 1 + nal_bs_read(bs, i));
}

static void parseh264_sps(uint8_t *sps, uint32_t sps_size,  int *level, int *profile, bool *interlaced) {
    nal_bitstream bs;
    sps_info_struct sps_info = {0};

    nal_bs_init(&bs, sps, sps_size);

    sps_info.profile_idc  = nal_bs_read(&bs, 8);
    nal_bs_read(&bs, 1);  // constraint_set0_flag
    nal_bs_read(&bs, 1);  // constraint_set1_flag
    nal_bs_read(&bs, 1);  // constraint_set2_flag
    nal_bs_read(&bs, 1);  // constraint_set3_flag
    nal_bs_read(&bs, 4);  // reserved
    sps_info.level_idc    = nal_bs_read(&bs, 8);
    sps_info.sps_id       = nal_bs_read_ue(&bs);

    if (sps_info.profile_idc == 100 ||
        sps_info.profile_idc == 110 ||
        sps_info.profile_idc == 122 ||
        sps_info.profile_idc == 244 ||
        sps_info.profile_idc == 44  ||
        sps_info.profile_idc == 83  ||
        sps_info.profile_idc == 86)
    {
            sps_info.chroma_format_idc                    = nal_bs_read_ue(&bs);
            if (sps_info.chroma_format_idc == 3)
                sps_info.separate_colour_plane_flag         = nal_bs_read(&bs, 1);
            sps_info.bit_depth_luma_minus8                = nal_bs_read_ue(&bs);
            sps_info.bit_depth_chroma_minus8              = nal_bs_read_ue(&bs);
            sps_info.qpprime_y_zero_transform_bypass_flag = nal_bs_read(&bs, 1);

            sps_info.seq_scaling_matrix_present_flag = nal_bs_read (&bs, 1);
            if (sps_info.seq_scaling_matrix_present_flag)
            {
                /* TODO: unfinished */
            }
    }
    sps_info.log2_max_frame_num_minus4 = nal_bs_read_ue(&bs);
    if (sps_info.log2_max_frame_num_minus4 > 12) {
        // must be between 0 and 12
        // don't early return here - the bits we are using (profile/level/interlaced/ref frames)
        // might still be valid - let the parser go on and pray.
        //return;
    }

    sps_info.pic_order_cnt_type = nal_bs_read_ue(&bs);
    if (sps_info.pic_order_cnt_type == 0) {
        sps_info.log2_max_pic_order_cnt_lsb_minus4 = nal_bs_read_ue(&bs);
    }
    else if (sps_info.pic_order_cnt_type == 1) { // TODO: unfinished
        /*
         delta_pic_order_always_zero_flag = gst_nal_bs_read (bs, 1);
         offset_for_non_ref_pic = gst_nal_bs_read_se (bs);
         offset_for_top_to_bottom_field = gst_nal_bs_read_se (bs);

         num_ref_frames_in_pic_order_cnt_cycle = gst_nal_bs_read_ue (bs);
         for( i = 0; i < num_ref_frames_in_pic_order_cnt_cycle; i++ )
         offset_for_ref_frame[i] = gst_nal_bs_read_se (bs);
         */
    }

    sps_info.max_num_ref_frames             = nal_bs_read_ue(&bs);
    sps_info.gaps_in_frame_num_value_allowed_flag = nal_bs_read(&bs, 1);
    sps_info.pic_width_in_mbs_minus1        = nal_bs_read_ue(&bs);
    sps_info.pic_height_in_map_units_minus1 = nal_bs_read_ue(&bs);

    sps_info.frame_mbs_only_flag            = nal_bs_read(&bs, 1);
    if (!sps_info.frame_mbs_only_flag)
        sps_info.mb_adaptive_frame_field_flag = nal_bs_read(&bs, 1);

    sps_info.direct_8x8_inference_flag      = nal_bs_read(&bs, 1);

    sps_info.frame_cropping_flag            = nal_bs_read(&bs, 1);
    if (sps_info.frame_cropping_flag) {
        sps_info.frame_crop_left_offset       = nal_bs_read_ue(&bs);
        sps_info.frame_crop_right_offset      = nal_bs_read_ue(&bs);
        sps_info.frame_crop_top_offset        = nal_bs_read_ue(&bs);
        sps_info.frame_crop_bottom_offset     = nal_bs_read_ue(&bs);
    }

    *level = (int)sps_info.level_idc;
    *profile = (int)sps_info.profile_idc;
    *interlaced = (int)!sps_info.frame_mbs_only_flag;
}
#pragma mark IJK源码 结束 -------------------------------

#pragma mark - ffmpeg官方案例源码

static AVBufferRef *hw_device_ctx = NULL;
static enum AVPixelFormat hw_pix_fmt = AV_PIX_FMT_VIDEOTOOLBOX;

static int hw_decoder_init(AVCodecContext *ctx, const enum AVHWDeviceType type) {
    int err = 0;
    if ((err = av_hwdevice_ctx_create(&hw_device_ctx, type, NULL, NULL, 0)) < 0) {
        NSLog(@"硬件加速: 创建给定的硬件设备失败");
        return err;
    }
    ctx->hw_device_ctx = av_buffer_ref(hw_device_ctx);
    return err;
}

static enum AVPixelFormat get_hw_format(AVCodecContext *ctx, const enum AVPixelFormat *pix_fmts) {
    const enum AVPixelFormat *p;
    for (p = pix_fmts; *p != -1; p++) {
        if (*p == hw_pix_fmt)
            return *p;
    }
    NSLog(@"硬件加速: 获取 HW surface format 失败");
    return AV_PIX_FMT_VIDEOTOOLBOX;
}

#pragma mark -
- (void)dealloc {
    
}

- (instancetype)init {
    if (self = [super init]) {
        self.queue = dispatch_queue_create("hz.ffmpeg.queue", DISPATCH_QUEUE_SERIAL);
        self.useVideoToolboxToDecode = YES;
        self.videoToolboxDecoder = [[HZVideoToolboxDecoder alloc] init];
        self.videoToolboxDecoder.delegate = self;
#if FFMPEG_RENDER_METHOD_METAL
        self.displayLayer = [[HZMTKView alloc] initWithFrame:CGRectMake(0, 0, 1.0f, 1.0f)];
#else
        self.displayLayer = [HZSampleBufferDisplayLayer layer];
#endif
    }
    return self;
}

- (void)stop {
    _stop = YES;
}

- (BOOL)isRecording {
#if FFMPEG_RENDER_METHOD_METAL
    return self.displayLayer.assetWriteManager.isRecording;
#else
    return NO;
#endif
}

- (void)screenShotWithFilePath:(NSString *)filePath withCompletionHandler:(void (^)(UIImage * _Nullable image))completionHandler {
#if FFMPEG_RENDER_METHOD_METAL
    [self.displayLayer screenShotWithFilePath:filePath withCompletionHandler:completionHandler];
#endif
}

- (void)startRecordWithFilePath:(NSString *)filePath {
#if FFMPEG_RENDER_METHOD_METAL
    [self.displayLayer startRecordWithFilePath:filePath];
#endif
}

- (void)stopRecord {
#if FFMPEG_RENDER_METHOD_METAL
    [self.displayLayer stopRecord];
#endif
}

- (void)freeData:(HZFFmpegFinishResult)result {
    NSLog(@"释放ffmpeg数据");
    
    avformat_network_deinit();
    
    if (_pCodecCtx) {
        //avcodec_flush_buffers(_pCodecCtx);
        avcodec_close(_pCodecCtx);
    }
    
    if (_pFormatCtx) {
        avformat_close_input(&_pFormatCtx);//里面调用了avformat_free_context;
        //avformat_free_context(_pFormatCtx);
        _pCodec = NULL;
        _pCodecCtx = NULL;
        _pFormatCtx = NULL;
    }
    
    if (_pFrame) {
        av_frame_free(&_pFrame);
        _pFrame = NULL;
    }
    if (_targetBuffer) {
        free(_targetBuffer);
        _targetBuffer = NULL;
    }
    if (_pTargetFrame) {
        av_frame_free(&_pTargetFrame);
        _pTargetFrame = NULL;
    }
    
    if (_packet) {
        av_free(_packet);
        _packet = NULL;
    }
    
    if (_img_convert_ctx) {
        sws_freeContext(_img_convert_ctx);
        _img_convert_ctx = NULL;
    }
    
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
#if FFMPEG_RENDER_METHOD_METAL
    [self.displayLayer freePictureData];
#endif
    
    self.videoToolboxDecoder = nil;
    
    _playState = HZFFmpegPlayStateStoped;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(moviePlayBackDidFinish:)]) {
        [self.delegate moviePlayBackDidFinish:result];
    }
}

- (void)printError:(int)error {
    char errorString[100] = {0};
    av_make_error_string(errorString, sizeof(errorString), error);
    NSLog(@"错误 %d: %s", error, errorString);
}

- (void)playWithFilePath:(NSString *)filePath {
    _playState = HZFFmpegPlayStateLoading;
    _filePath = filePath;
    
    HZFFmpegFinishResult result = HZFFmpegFinishResultNoResult;
    
    _stop = NO;
    _lostIFrame = NO;
    self.drawMode = HZMTKViewDrawModeDrawAsCircle;
    
    //av_register_all();
    avformat_network_init();
    _pFormatCtx = avformat_alloc_context();
    /* //之前公司的代码
    // 内部解析jpeg用的方法, 只有rtsp协议开头的用到, 就是之前客户没给源码的那个文件
    _pFormatCtx->rtp_jpeg_parse_packet_method = 1;
    // rtsp数据
    _pFormatCtx->rtcp_sr_cb.callback = rtcp_sr_cb;
    _pFormatCtx->rtcp_sr_cb.opaque = (__bridge void *)(self);*/
    
    char *cFilePath = (char *)[filePath UTF8String];
    AVDictionary *options = NULL;
    char *transport = self.useTcp ? "tcp" : "udp";
    av_dict_set(&options, "rtsp_transport", transport, 0);
    av_dict_set(&options, "stimeout", "9000000", 0);
    //av_dict_set(&options, "scan_all_pmts", "1", 0);
    //av_dict_set(&options, "ijkapplication", "5534753888", 0);
    //av_dict_set(&options, "ijkiomanager", "10764161200", 0);
    //av_dict_set(&options, "probesize", "20480", 0);
    //av_dict_set(&options, "analyzeduration", "6000000", 0);
    //av_dict_set(&options, "auto_convert", "0", 0);
    //av_dict_set(&options, "safe", "0", 0);
    //av_dict_set(&options, "user-agent", "ijkplayer", 0);
    //av_dict_set(&options, "reconnect", "0", 0);
    /*
     // ffmpeg源码
     #define UDP_TX_BUF_SIZE 32768
     #define UDP_MAX_PKT_SIZE 65536
     #define UDP_HEADER_SIZE 8
     s->buffer_size = is_output ? UDP_TX_BUF_SIZE : UDP_MAX_PKT_SIZE;
     */
    //av_dict_set(&options, "buffer_size", "1024000", 0);
    //av_dict_set(&options, "reorder_queue_size", "500", 0); // ffmpeg默认为500 #define RTP_REORDER_QUEUE_DEFAULT_SIZE 500
    /**
     srt:
     recv_buffer_size=bytes
     Set UDP receive buffer size, expressed in bytes.
     send_buffer_size=bytes
     Set UDP send buffer size, expressed in bytes.
     UDP:
     buffer_size=size
     Set the UDP maximum socket buffer size in bytes. This is used to set either the receive or send buffer size, depending on what the socket is used for. Default is 32 KB for output, 384 KB for input. See also fifo_size.
     fifo_size=units
     Set the UDP receiving circular buffer size, expressed as a number of packets with size of 188 bytes. If not specified defaults to 7*4096.
     "rtbufsize", "max memory used for buffering real-time frames"
     */
    AVInputFormat *format = NULL;
    /* //之前公司的代码
    if (strstr(cFilePath, "udp:")) {
        format = av_find_input_format("mjpeg");
    }*/
    NSLog(@"开始打开文件: %@", filePath);
    int ret = avformat_open_input(&_pFormatCtx, cFilePath, format, &options);
    if (options) {
        av_dict_free(&options);
        options = NULL;
    }
    if (ret != 0) {
        NSLog(@"avformat_open_input error");
        [self printError:ret];
        if (ret == -61 // 连接拒绝
            || ret == -60) { // 连接超时
            result |= HZFFmpegFinishResultConnectionProblem;
        }
        [self freeData:result];
        return;
    }
    //AVDictionary *opts = NULL;
    //av_dict_set(&opts, "skip_frame", "0", 0);
    if (avformat_find_stream_info(_pFormatCtx, NULL) < 0) {
        NSLog(@"avformat_find_stream_info error");
        [self freeData:result];
        return;
    }
    //if (opts) {
    //    av_dict_free(&opts);
    //    options = NULL;
    //}
    _videoindex = -1;
    ret = av_find_best_stream(_pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &_pCodec, 0);
    if (ret < 0) {
        NSLog(@"av_find_best_stream error");
        [self printError:ret];
        [self freeData:result];
        return;
    }
    _videoindex = ret;
    
    _pCodecCtx = avcodec_alloc_context3(_pCodec);
    if (!_pCodecCtx) {
        NSLog(@"Could not allocate video codec context");
        [self freeData:result];
        return;
    }
    /* Copy codec parameters from input stream to output codec context */
    ret = avcodec_parameters_to_context(_pCodecCtx, _pFormatCtx->streams[_videoindex]->codecpar);
    if (ret < 0) {
        NSLog(@"Failed to copy %s codec parameters to decoder context", av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        [self printError:ret];
        [self freeData:result];
        return;
    }
    
    if (self.useVideoToolboxToDecode && _pCodecCtx->codec_id != AV_CODEC_ID_MJPEG) {
        _pCodecCtx->get_format = get_hw_format;
        //av_opt_set_int(_pCodecCtx, "refcounted_frames", 1, 0);
        if (hw_decoder_init(_pCodecCtx, AV_HWDEVICE_TYPE_VIDEOTOOLBOX) < 0) {
            NSLog(@"hw_decoder_init error.");
            [self freeData:result];
            return;
        }
    } else {
        _pCodec = avcodec_find_decoder(_pCodecCtx->codec_id);
        if (_pCodec == NULL) {
            NSLog(@"Codec not found.");
            [self freeData:result];
            return;
        }
    }
    
    ret = avcodec_open2(_pCodecCtx, _pCodec, NULL);
    if (ret < 0) {
        NSLog(@"Could not open codec.");
        [self printError:ret];
        [self freeData:result];
        return;
    }
    
    _pCodecCtx->pkt_timebase = _pFormatCtx->streams[_videoindex]->time_base; // 这句要不要加, 还没验证过
    
    int width = _pCodecCtx->width;
    int height = _pCodecCtx->height;
    if (width <= 0 || height <= 0) {
        NSLog(@"Width or height error.");
        [self freeData:result];
        return;
    }
    if (_pCodecCtx->pix_fmt == AV_PIX_FMT_NONE) {
        NSLog(@"Pixel format error.");
        [self freeData:result];
        return;
    }
    //frame
    _pFrame = av_frame_alloc();
    //packet
    _packet = av_packet_alloc();
    //av_init_packet(&_flustPacket);
    //_flustPacket.data = NULL;
    //framerate
    AVRational frameRateRational = _pFormatCtx->streams[_videoindex]->avg_frame_rate;
    NSLog(@"------------- File Information ------------------");
    av_dump_format(_pFormatCtx, 0, cFilePath, 0);
    NSLog(@"-------------------------------------------------");
    //------------------------------
    for (;;) {
        if (_stop) {
            result |= HZFFmpegFinishResultUserStoped;
            NSLog(@"%s lien:%d 退出", __func__, __LINE__);
            break;
        }
        //AVPacket *packet = av_packet_alloc();
        ret = av_read_frame(_pFormatCtx, _packet);
        //NSLog(@"av_read_frame %d", readFrameRet);
        if (_packet->stream_index == _videoindex) {
            
            if (ret < 0) {
                NSLog(@"av_read_frame error");
                [self printError:ret];
                if (ret == AVERROR_EOF) { // 文件读完了, -541478725
                result |= HZFFmpegFinishResultEndOfFile;
                result |= HZFFmpegFinishResultShouldReplay;
                    break;
                } else if (ret == -60) { // 超时
                    break;
                } else { // 其它错误
                    continue;
                }
            }
            
            BOOL lostPacket = NO;
            /*// 之前公司的代码
            if (_packet->nIsLostPackets) {
                NSLog(@"收到一个不完整的包1 %d", _packet->flags);
                lostPacket = YES;
            }*/
            //NSLog(@"ibp调试 flag:%d", _packet->flags);
            if (_packet->flags & 0x0100) { // 包是不连续的
                NSLog(@"收到一个不完整的包2");
                lostPacket = YES;
            }
            if (lostPacket) {
                if (_packet->flags & 0x1) { // 是I帧
                    _lostIFrame = YES;
                }
                continue;
            } else {
                if (_packet->flags & 0x1) { // 是I帧
                    _lostIFrame = NO;
                }
            }
            if (_lostIFrame) {
                continue;
            }
            
            if (![self handleDataWithCFilePath:cFilePath withPacket:_packet]) {
                continue;
            }
            
            if (self.useVideoToolboxToDecode) {
                if (_pCodecCtx->codec_id == AV_CODEC_ID_MJPEG) {
                    [self decodePacketUseVideoToolbox:_packet withWidth:width height:height];
                } else {
                    [self decodePacketUseHWAccel:_packet withWidth:width height:height];
                }
            } else {
                [self decodePacket:_packet withWidth:width height:height];
            }
            
            if (frameRateRational.num > 0) {
                useconds_t sleepTime = (useconds_t)(0.90f * 1000000.0f * frameRateRational.den / frameRateRational.num);
                usleep(sleepTime);
            }
        }
        av_packet_unref(_packet);
    }
    NSLog(@"读完数据了");
    
    [self freeData:result];
}

// ffmpeg 硬件加速功能, 就是用Videotoolbox解码, decodePacketUseVideoToolbox方法有些流解不了
- (void)decodePacketUseHWAccel:(AVPacket *)packet withWidth:(int)width height:(int)height {
    int ret = avcodec_send_packet(_pCodecCtx, packet);
    //NSLog(@"发送一个packet");
    if (ret < 0) {
        NSLog(@"avcodec_sendpacket failed.");
        return;
    }
    for (;;) {
        AVFrame *frame = av_frame_alloc();
        if (!frame) {
            return;
        }
        ret = avcodec_receive_frame(_pCodecCtx, frame); // 读出来的帧, 有b帧的时候, 时间顺序也是正常的
        //NSLog(@"接收一个frame");
        if (ret != 0) {
            //NSLog(@"avcodec_receive_frame error.");
            //[self printError:ret];
            break;
        } else {
            if (frame->format == hw_pix_fmt) {
                if ((ret = av_hwframe_transfer_data(_pFrame, frame, 0)) < 0) {
                    NSLog(@"硬件加速: frame转换出错");
                    break;;
                }
            } else {
                av_frame_copy(_pFrame, frame);
            }
            av_frame_free(&frame);
            //NSLog(@"帧类型:%c %lld %lld", av_get_picture_type_char(_pFrame->pict_type), av_frame_get_best_effort_timestamp(_pFrame), _pFrame->pts);
            //NSLog(@"decode ");
            //AVFrameSideData **sideData = _pFrame->side_data;
            //AVDictionary *metaData = _pFrame->metadata;
            //NSLog(@"sideData: %p metaData: %p", sideData, metaData);
            enum AVPixelFormat targetPixelFormat = AV_PIX_FMT_NV12;//NV12为YUV420SP UV排列, NV21为YUV420SP VU排列
            // 要用这个宽度去做scale才不会出问题
            // IJK里面的宽度计算方式为 1 << (sizeof(int) * 8 - __builtin_clz(width))
            if (_pFrame->format != targetPixelFormat) {
                int targetWidth = _pFrame->linesize[0];
                if (!_pTargetFrame) {
                    _pTargetFrame = av_frame_alloc();
                    int bufferSize = av_image_get_buffer_size(targetPixelFormat, targetWidth, height, 1);
                    _targetBuffer = (uint8_t *)av_malloc(bufferSize);
                    //avpicture_fill((AVPicture *)_pTargetFrame, _targetBuffer, targetPixelFormat, width, height);
                    _pTargetFrame->format = targetPixelFormat;
                    _pTargetFrame->width = targetWidth;
                    _pTargetFrame->height = height;
                    av_image_fill_arrays(_pTargetFrame->data, _pTargetFrame->linesize, _targetBuffer, targetPixelFormat, targetWidth, height, 1);
                }
                _img_convert_ctx = sws_getCachedContext(_img_convert_ctx, width, height,  _pCodecCtx->pix_fmt, targetWidth, height, targetPixelFormat, SWS_BILINEAR, NULL, NULL, NULL);
                ret = sws_scale(_img_convert_ctx, (const uint8_t* const*)_pFrame->data, _pFrame->linesize, 0, height, _pTargetFrame->data, _pTargetFrame->linesize);
                //NSLog(@"scale: %d", ret);
            } else {
                int targetWidth = _pFrame->width;
                if (!_pTargetFrame) {
                    _pTargetFrame = av_frame_alloc();
                    int bufferSize = av_image_get_buffer_size(targetPixelFormat, targetWidth, height, 1);
                    _targetBuffer = (uint8_t *)av_malloc(bufferSize);
                    //avpicture_fill((AVPicture *)_pTargetFrame, _targetBuffer, targetPixelFormat, width, height);
                    _pTargetFrame->format = targetPixelFormat;
                    _pTargetFrame->width = targetWidth;
                    _pTargetFrame->height = height;
                    av_image_fill_arrays(_pTargetFrame->data, _pTargetFrame->linesize, _targetBuffer, targetPixelFormat, targetWidth, height, 1);
                }
                av_frame_copy(_pTargetFrame, _pFrame);
            }
            
            //av_frame_unref(_pFrame);
            if (!_pixelBuffer) {
                CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                                           NULL,
                                                           NULL,
                                                           0,
                                                           &kCFTypeDictionaryKeyCallBacks,
                                                           &kCFTypeDictionaryValueCallBacks);
                CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                         1,
                                                                         &kCFTypeDictionaryKeyCallBacks,
                                                                         &kCFTypeDictionaryValueCallBacks);
                CFDictionarySetValue(attrs,
                                     kCVPixelBufferIOSurfacePropertiesKey,
                                     empty);
                CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                                   kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                   attrs,
                                                   &_pixelBuffer);
                if (ret != kCVReturnSuccess) {
                    NSLog(@"%s CVPixelBuffer创建失败", __func__);
                }
            }
            CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
            void* base = CVPixelBufferGetBaseAddressOfPlane(_pixelBuffer, 0);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(_pixelBuffer, 0);
            size_t heightOfPlane = CVPixelBufferGetHeightOfPlane(_pixelBuffer, 0);
            for (int i = 0; i < heightOfPlane; i++) {
                memcpy(base + bytesPerRow * i, _pTargetFrame->data[0] + _pTargetFrame->linesize[0] * i, width);
            }
            base = CVPixelBufferGetBaseAddressOfPlane(_pixelBuffer, 1);
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(_pixelBuffer, 1);
            heightOfPlane = CVPixelBufferGetHeightOfPlane(_pixelBuffer, 1);
            for (int i = 0; i < heightOfPlane; i++) {
                memcpy(base + bytesPerRow * i, _pTargetFrame->data[1] + _pTargetFrame->linesize[1] * i, width);
            }
            CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
            
            [self drawDecodedImage:_pixelBuffer];
        }
    }
}

- (void)decodePacketUseVideoToolbox:(AVPacket *)packet withWidth:(int)width height:(int)height {
    // http://www.ffmpeg.org/doxygen/3.4/hw_decode_8c-example.html
    // 下面的方法有些流创建videotoolbox不成功, 还是要参考ffmpeg官方源码, 编译时要加上 "--enable-hwaccel=h264_videotoolbox" "--enable-hwaccel=hevc_videotoolbox" "--enable-hwaccel=mpeg4_videotoolbox"
    AVStream *stream = _pFormatCtx->streams[_videoindex];
    HZVideoInfoData videoInfo = {};
    CMVideoCodecType codecType = 0;
    if (stream->codecpar->codec_id == AV_CODEC_ID_MJPEG) {
        codecType = kCMVideoCodecType_JPEG;
    } else if (stream->codecpar->codec_id == AV_CODEC_ID_H264) {
        codecType = kCMVideoCodecType_H264;
    } else if (stream->codecpar->codec_id == AV_CODEC_ID_HEVC) {
        codecType = kCMVideoCodecType_HEVC;
    } else if (stream->codecpar->codec_id == AV_CODEC_ID_MPEG4) {
        codecType = kCMVideoCodecType_MPEG4Video;
    }
    videoInfo.codecType = codecType;
    videoInfo.hasSPSAndPPS = packet->flags & 0x1;
    CFMutableDictionaryRef videoDecoderSpecification = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (videoInfo.hasSPSAndPPS) {
        CFMutableDictionaryRef avc_info = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDataRef data = NULL;
        if (codecType == kCMVideoCodecType_MPEG4Video) {
            // ffmpeg源码
            data = videotoolbox_esds_extradata_create(_pCodecCtx);
            if (data) {
                CFDictionarySetValue(avc_info, CFSTR("esds"), data);
                CFRelease(data);
            }
        } else if (codecType == kCMVideoCodecType_H264 || codecType == kCMVideoCodecType_HEVC) {
            // ffmpeg源码源码编译不过, 用了IJK里的代码
            AVCodecParameters *codecpar = avcodec_parameters_alloc();
            if (codecpar) {
                int ret = avcodec_parameters_from_context(codecpar, _pCodecCtx);
                if (ret == 0) {
                    data = videotoolbox_getH264OrHEVCData(codecpar);
                    if (data) {
                        CFStringRef typeString = codecType == kCMVideoCodecType_H264 ? CFSTR("avcC") : CFSTR("hvcC");
                        CFDictionarySetValue(avc_info, typeString, data);
                        CFRelease(data);
                    }
                }
            }
            avcodec_parameters_free(&codecpar);
        }
        CFDictionarySetValue(videoDecoderSpecification, kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms, avc_info);
        CFRelease(avc_info);
        
        // LLDB指令: m read/4wd 或 x/4bx
        //uint8_t *extraData = stream->codecpar->extradata;
        /**
         b ：byte 代表1个字节
         h ：half word 代表2个字节
         w ：word 代表4个字节
         g ：giant word 代表8个字节
         */
        // 将用不上的字节替换掉，在SPS和PPS前添加开始码
        // 假设extradata数据为 0x01 64 00 0A FF E1 00 19 67 64 00 00...其中67开始为SPS数据
        //  则替换后为0x00 00 00 01 67 64...
        
        // 使用FFMPEG提供的方法。
        // 我一开始以为FFMPEG的这个方法会直接获取到SPS和PPS，谁知道只是替换掉开始码。
        // 要注意的是，这段代码会一直报**Packet header is not contained in global extradata, corrupted stream or invalid MP4/AVCC bitstream**。可是貌似对数据获取没什么影响。我就直接忽略了
        /*uint8_t *dummy = NULL;
        int dummy_size;
        AVBitStreamFilterContext* bsfc =  av_bitstream_filter_init("h264_mp4toannexb");
        av_bitstream_filter_filter(bsfc, _pCodecCtx, NULL, &dummy, &dummy_size, NULL, 0, 0);
        av_bitstream_filter_close(bsfc);
        
        // 获取SPS和PPS的数据和长度
        int startCodeSPSIndex = 0;
        int startCodePPSIndex = 0;
        uint8_t *extradata = _pCodecCtx->extradata;
        for (int i = 3; i < _pCodecCtx->extradata_size; i++) {
            if (extradata[i] == 0x01 &&
                extradata[i - 1] == 0x00 &&
                extradata[i - 2] == 0x00 &&
                extradata[i - 3] == 0x00) {
                if (startCodeSPSIndex == 0) startCodeSPSIndex = i + 1;
                if (i > startCodeSPSIndex) {
                    startCodePPSIndex = i + 1;
                    break;
                }
            }
        }
        // 这里减4是因为需要减去PPS的开始码的4个字节
        int spsLength = startCodePPSIndex - 4 - startCodeSPSIndex;
        int ppsLength = _pCodecCtx->extradata_size - startCodePPSIndex;*/
    }
    videoInfo.videoDecoderSpecification = videoDecoderSpecification;
    videoInfo.width = width;
    videoInfo.height = height;
    videoInfo.packetDataSize = packet->size;
    videoInfo.packetData = malloc(videoInfo.packetDataSize);
    memcpy(videoInfo.packetData, packet->data, videoInfo.packetDataSize);
    
    CMSampleTimingInfo timingInfo;
    timingInfo.presentationTimeStamp = CMTimeMakeWithSeconds(packet->pts * stream->time_base.num, stream->time_base.den);
    timingInfo.presentationTimeStamp = CMTimeMakeWithSeconds(packet->dts * stream->time_base.num, stream->time_base.den);
    videoInfo.timingInfo = timingInfo;
    [self.videoToolboxDecoder decodeVideoWithVideoInfoData:videoInfo];
    free(videoInfo.packetData);
    CFRelease(videoDecoderSpecification);
}

- (void)decodePacket:(AVPacket *)packet withWidth:(int)width height:(int)height {
#if HZFFMPEG_IMAGE_DEBUG
    static BOOL shouldSavePicture = YES;
    if (shouldSavePicture && _pFormatCtx->streams[_videoindex]->codecpar->codec_id == AV_CODEC_ID_MJPEG) {
        NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *fileName = [NSString stringWithFormat:@"%.0f.jpeg", [NSDate date].timeIntervalSince1970];
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        NSLog(@"保存图片: %@", filePath);
        NSData *jpegData = [NSData dataWithBytes:packet->data length:packet->size];
        [jpegData writeToFile:filePath atomically:NO];
    }
#endif
    
    //ret = avcodec_decode_video2(_pCodecCtx, _pFrame, &got_picture, packet);
    int ret = avcodec_send_packet(_pCodecCtx, packet);
    //NSLog(@"发送一个packet");
    if (ret != 0) {
        NSLog(@"avcodec_sendpacket failed.");
        return;
    }
    for (;;) {
        ret = avcodec_receive_frame(_pCodecCtx, _pFrame); // 读出来的帧, 有b帧的时候, 时间顺序也是正常的
        //NSLog(@"接收一个frame");
        if (ret != 0) {
            //NSLog(@"avcodec_receive_frame error.");
            //[self printError:ret];
            break;
        } else {
#if HZFFMPEG_IMAGE_DEBUG
            if (shouldSavePicture) {
                NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
                NSString *fileName = [NSString stringWithFormat:@"%s_%.0f.yuv", av_get_pix_fmt_name(_pFrame->format), [NSDate date].timeIntervalSince1970];
                NSString *filePath = [directory stringByAppendingPathComponent:fileName];
                NSLog(@"保存图片: %@", filePath);
                NSMutableData *yuvData = [NSMutableData data];
                [yuvData appendBytes:_pFrame->data[0] length:_pFrame->linesize[0] * height];
                int h = height / 2; // 默认是 YUV420p的, 其实应该叫YUV411p才准确
                if (_pFrame->format == AV_PIX_FMT_YUVJ422P) {
                    h = height;
                }
                [yuvData appendBytes:_pFrame->data[1] length:_pFrame->linesize[1] * h];
                [yuvData appendBytes:_pFrame->data[2] length:_pFrame->linesize[2] * h];
                [yuvData writeToFile:filePath atomically:YES];
            }
#endif
            
            //NSLog(@"帧类型:%c %lld %lld", av_get_picture_type_char(_pFrame->pict_type), av_frame_get_best_effort_timestamp(_pFrame), _pFrame->pts);
            //NSLog(@"decode ");
            //AVFrameSideData **sideData = _pFrame->side_data;
            //AVDictionary *metaData = _pFrame->metadata;
            //NSLog(@"sideData: %p metaData: %p", sideData, metaData);
            enum AVPixelFormat targetPixelFormat = AV_PIX_FMT_NV12;//NV12为YUV420SP UV排列, NV21为YUV420SP VU排列
            // 要用这个宽度去做scale才不会出问题
            // IJK里面的宽度计算方式为 1 << (sizeof(int) * 8 - __builtin_clz(width))
            int targetWidth = _pFrame->linesize[0];
            if (!_pTargetFrame) {
                _pTargetFrame = av_frame_alloc();
                int bufferSize = av_image_get_buffer_size(targetPixelFormat, targetWidth, height, 1);
                _targetBuffer = (uint8_t *)av_malloc(bufferSize);
                //avpicture_fill((AVPicture *)_pTargetFrame, _targetBuffer, targetPixelFormat, width, height);
                _pTargetFrame->format = targetPixelFormat;
                _pTargetFrame->width = targetWidth;
                _pTargetFrame->height = height;
                av_image_fill_arrays(_pTargetFrame->data, _pTargetFrame->linesize, _targetBuffer, targetPixelFormat, targetWidth, height, 1);
            }
            _img_convert_ctx = sws_getCachedContext(_img_convert_ctx, width, height,  _pCodecCtx->pix_fmt, targetWidth, height, targetPixelFormat, SWS_BILINEAR, NULL, NULL, NULL);
            ret = sws_scale(_img_convert_ctx, (const uint8_t* const*)_pFrame->data, _pFrame->linesize, 0, height, _pTargetFrame->data, _pTargetFrame->linesize);
            //NSLog(@"scale: %d", ret);
#if HZFFMPEG_IMAGE_DEBUG
            if (shouldSavePicture) {
                NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
                NSString *fileName = [NSString stringWithFormat:@"%s_%.0f.yuv", av_get_pix_fmt_name(_pTargetFrame->format), [NSDate date].timeIntervalSince1970];
                NSString *filePath = [directory stringByAppendingPathComponent:fileName];
                NSLog(@"保存图片: %@", filePath);
                NSMutableData *yuv420spData = [NSMutableData data];
                [yuv420spData appendBytes:_pTargetFrame->data[0] length:_pTargetFrame->linesize[0] * height];
                [yuv420spData appendBytes:_pTargetFrame->data[1] length:_pTargetFrame->linesize[0] * height / 2];
                [yuv420spData writeToFile:filePath atomically:NO];
                
                shouldSavePicture = NO;
                dispatch_time_t dipatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
                dispatch_after(dipatchTime, dispatch_get_main_queue(), ^{
                    NSLog(@"保存图片标识改变");
                    shouldSavePicture = YES;
                });
            }
#endif
            
            //av_frame_unref(_pFrame);
            if (!_pixelBuffer) {
                CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                                           NULL,
                                                           NULL,
                                                           0,
                                                           &kCFTypeDictionaryKeyCallBacks,
                                                           &kCFTypeDictionaryValueCallBacks);
                CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                         1,
                                                                         &kCFTypeDictionaryKeyCallBacks,
                                                                         &kCFTypeDictionaryValueCallBacks);
                CFDictionarySetValue(attrs,
                                     kCVPixelBufferIOSurfacePropertiesKey,
                                     empty);
                CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                                   kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                   attrs,
                                                   &_pixelBuffer);
                if (ret != kCVReturnSuccess) {
                    NSLog(@"%s CVPixelBuffer创建失败", __func__);
                }
            }
            CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
            void* base = CVPixelBufferGetBaseAddressOfPlane(_pixelBuffer, 0);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(_pixelBuffer, 0);
            size_t heightOfPlane = CVPixelBufferGetHeightOfPlane(_pixelBuffer, 0);
            for (int i = 0; i < heightOfPlane; i++) {
                memcpy(base + bytesPerRow * i, _pTargetFrame->data[0] + _pTargetFrame->linesize[0] * i, width);
            }
            base = CVPixelBufferGetBaseAddressOfPlane(_pixelBuffer, 1);
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(_pixelBuffer, 1);
            heightOfPlane = CVPixelBufferGetHeightOfPlane(_pixelBuffer, 1);
            for (int i = 0; i < heightOfPlane; i++) {
                memcpy(base + bytesPerRow * i, _pTargetFrame->data[1] + _pTargetFrame->linesize[1] * i, width);
            }
            CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
            
            [self drawDecodedImage:_pixelBuffer];
        }
    }
}

- (void)playInNewThreadWithFilePath:(NSString *)filePath {
    if (!filePath) {
        NSLog(@"filePath 为 nil");
        return;
    }
    if (self.playState != HZFFmpegPlayStateStoped) {
        NSLog(@"正在播放");
        return;
    }
    dispatch_async(self.queue, ^{
        [self playWithFilePath:filePath];
    });
}

- (CMSampleBufferRef)convertCVImageBufferRefToCMSampleBufferRef:(CVImageBufferRef)pixelBuffer withPresentationTimeStamp:(CMTime)presentationTimeStamp {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CMSampleBufferRef newSampleBuffer = NULL;
    OSStatus res = 0;
    
    CMSampleTimingInfo timingInfo;
    timingInfo.duration              = kCMTimeInvalid;
    timingInfo.decodeTimeStamp       = presentationTimeStamp;
    timingInfo.presentationTimeStamp = presentationTimeStamp;
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    res = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    if (res != 0) {
        NSLog(@"%s: Create video format description failed!", __func__);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return NULL;
    }
    
    // 内部引用(不是复制)了pixelBuffer
    res = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                             pixelBuffer,
                                             true,
                                             NULL,
                                             NULL,
                                             videoInfo,
                                             &timingInfo,
                                             &newSampleBuffer);
    
    CFRelease(videoInfo);
    if (res != 0) {
        NSLog(@"%s: Create sample buffer failed!", __func__);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return NULL;
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(newSampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    return newSampleBuffer;
}

int is_in(char *s, char *c) {
    int i = 0, j = 0, flag = -1;
    while(i < strlen(s) && j < strlen(c)) {
        if (s[i] == c[j]) { //如果字符相同则两个字符都增加
            i++;
            j++;
        } else {
            i = i- j + 1; //主串字符回到比较最开始比较的后一个字符
            j = 0;     //字串字符重新开始
        }
        if(j == strlen(c)) { //如果匹配成功
            flag = 1;  //字串出现
            break;
        }
    }
    return flag;
}

int useCos(int16_t x, int16_t y,int16_t z) {
    if (z < 0x480) {
        if (x > 0x450) {
            if (z > 0x404)    //1046
                z = 0x404;
            //z = (float) (z / 0x404);
            z = 360 - acos(((float)z / 0x404)) * 180 / M_PI;
        } else {
            if (z > 0x404)
                z = 0x404;
            //z = (float) (z / 0x404);
            z = acos( ((float)z / 0x404)) * 180 / M_PI;
        }
    } else { //if(z > 0xC12)
        z = 4090 - z;
        if (x < 0x430) {
            //z  = (float)((z*t)/1000)+90;
            if (z > 990)//3de
                z = 990;
            //z = (float) (z / 990);
            z = 180 - acos(((float)z / 990)) * 180 / M_PI;
        } else {
            if (z > 990)
                z = 990;
            // z = (float) (z / 990);
            z = 180 + acos(((float)z / 990)) * 180 / M_PI;
        }
    }
    return z;
}
int useCos5(int16_t x, int16_t y, int16_t z) {
    if (z < 2048) {
        if (x >= 2048) {
            if (z >= 2048)    //1046
                z = 4096-z;
            //z = (float) (z / 0x404);
            z = 360 - acos(((float)z / 2048)) * 180 / M_PI;
        } else {
            if (z >= 2048)
                z = 4096-z;
            //z = (float) (z / 0x404);
            z = acos( ((float)z / 2048)) * 180 / M_PI;
        }
    } else { //if(z > 0xC12)
        if (x < 2048) {
            //z  = (float)((z*t)/1000)+90;
            if (z >= 2048)//3de
                z = z-2048;
            //z = (float) (z / 990);
            z = 90+acos(((float)z / 2048)) * 180 /M_PI;
        } else {
            if (z >= 2048)
                z = 4096-z;
            // z = (float) (z / 990);
            z = 180 + acos(((float)z / 2048)) * 180 / M_PI;
        }
    }
    return z;
}
float transformvalue(float value) {
    if(value > 128 * 256 / 16) {
        return value - 16 * 256;
    } else {
        return value;
    }
}
int useTan(int16_t x, int16_t y,int16_t z) {
    /* if(x>3000)
     x = 3000-x;
     if(z>3000)
     z = 3000-z;*/
    //float degree2 = atan((float)y /sqrt(x * x + y * y)) * 180 / M_PI;
    //float degree3 = atan((float)z /sqrt(x * x + y * y)) * 180 / M_PI;
    int degree;
    float x1 = transformvalue(x);
    //float y1 = transformvalue(y);
    float z1 = transformvalue(z);
    float degree1 = atan(x1 / sqrt(z1 * z1)) * 180 / M_PI;
    // float degree1= atan(x1/sqrt(y1*y1+z1*z1))* 180 / M_PI;
    if(z1 > 0) {
        if(x1 > 0) {
            degree = (int)degree1;
        } else {
            degree = (int)degree1 + 360;
        }
    } else {
        degree = 180 - (int)degree1;
    }
    return degree;
}
int useTan5(int16_t x, int16_t y, int16_t z) {
    if(x >= 2048)
     x = x - 4096;
    if(y >= 2048)
        y = y - 4096;
     if(z >= 2048)
     z = z - 4096;
    
    //float degree2 = atan((float)y /sqrt(x * x + y * y)) * 180 / M_PI;
    //float degree3 = atan((float)z /sqrt(x * x + y * y)) * 180 / M_PI;
    int degree;
    float x1 = transformvalue(x);
    //float y1 = transformvalue(y);
    float z1 = transformvalue(z);
    float degree1= atan(x1/sqrt(z1*z1))* 180 / M_PI;
    //float degree1= atan(x1/sqrt(y1*y1+z1*z1))* 180 / M_PI;
    if (z1 > 0) {
        if(x1 > 0) {
            degree = (int)degree1;
        } else {
            degree = (int)degree1 + 360;
        }
    } else {
        degree = 180 - (int)degree1;
    }
    return degree;
}
int computeDegree(float x, float y,float z) {
    int degree = useCos(x, y, z);
    if((degree > 70 &&degree < 95) || (degree > 250 && degree < 260)) {
        //return degree;
    }
    degree = useTan(x, y, z);
    return degree;
}
int computeDegree5(float x, float y, float z) {
    int degree = useCos5(x, y, z);
    if((degree > 70 && degree < 90)) { //
        //return degree;
    }
    degree = useTan5(x, y, z);
    return degree;
}
int computeDegree3(float x, float y, float z) {
    int degree = useCos(x, y, z);
    
    if((degree > 70 && degree < 80)) { //
        //return degree;
    }
    degree = useTan(x, y, z);
    return degree;
}
int old_degreee = 0;

#define JPEG_COM         0xff
#define JPEG_HDR         0xd8
#define JPEG_TLR         0xd9

typedef enum {
    SJPG_NONONE,
    SJPG_DCT_HDRCOM,
    SJPG_DCT_HDR,
    SJPG_DCT_TLRCOM,
    SJPG_DCT_TLR,
    SJPG_DCT_CRC,
    SJPG_PROCESSING
} DJPG_STA;

typedef struct dct_jpeg_st {
    DJPG_STA sta;
    unsigned int jpeg_len;
    unsigned int jpeg_crc_len;
    unsigned char *jpeg_table;
    unsigned int jpeg_start;
} DCT_JPEG_ST, *DCT_JPEG_PTR;

DCT_JPEG_ST djpeg_st;
char m_imagbuf[100*1024];

- (BOOL)handleDataWithCFilePath:(char *)cFilePath withPacket:(AVPacket *)packet {
    //rtsp://192.168.1.1:554/264_rt/XXX.sd
    if(cFilePath == NULL || !strstr(cFilePath, ":") || strstr(cFilePath, "file:")) { //本地目录
        self.drawMode = HZMTKViewDrawModeUnknow;
    } else if (self.useTcp) { // 公司的设备都用udp协议
        self.drawMode = HZMTKViewDrawModeUnknow;
    } else if (is_in(cFilePath, "264_rt/XXX") == 1) {//节理
        self.drawMode = HZMTKViewDrawModeUnknow;
    } else if (is_in(cFilePath, "udp://192.168.1.1:7070") == 1) {//博通
        // add crc check mjpeg
        //TV_HDR_PTR node_tv_har=(TV_HDR_PTR)pkt->side_data->data;
        //av_log(ffp, AV_LOG_ERROR, "#########node_tv_har1 id:0x%x,is_eof:0x%x,pkt_cnt:0x%x..\n",node_tv_har->id,node_tv_har->is_eof,node_tv_har->pkt_cnt);
        //TV_HDR_PTR node_tv_har=(TV_HDR_PTR)pkt->buf->data;
        //av_log(ffp, AV_LOG_ERROR, "#########node_tv_har2 id:0x%x,is_eof:0x%x,pkt_cnt:0x%x..\n",node_tv_har->id,node_tv_har->is_eof,node_tv_har->pkt_cnt);
        //#if 1   //lgh
        memset(&djpeg_st, 0, sizeof(DCT_JPEG_ST));
        djpeg_st.sta = SJPG_NONONE;
        int ci;
        int crc_type = 0;
        //av_log(ffp, AV_LOG_ERROR, "########pktdata pts:%d,dts:%d\n",pkt->pts,pkt->dts);
        //av_log(ffp, AV_LOG_ERROR, "########pktdata star########\n");
        //pkt->size=pkt->size-6;
        //for(ci = 0; ci < packet->size; ci++) {
            // av_log(ffp, AV_LOG_ERROR, ",0x%x",pkt->data[ci]);
        //}
        //av_log(ffp, AV_LOG_ERROR, "########pktdata end########\n");
        
        for (ci = 0; ci < packet->size; ) {
            unsigned char add_i = 1;
            switch (djpeg_st.sta) {
                case SJPG_NONONE:
                    if (packet->data[ci] == JPEG_COM) {
                        djpeg_st.sta = SJPG_DCT_HDRCOM;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_NONONE..\n");
                    }
                    break;
                    
                case SJPG_DCT_HDRCOM:
                    if (packet->data[ci] == JPEG_HDR) {
                        djpeg_st.sta = SJPG_DCT_HDR;
                        djpeg_st.jpeg_table = (unsigned char *)m_imagbuf;
                        djpeg_st.jpeg_table[0] = JPEG_COM;
                        djpeg_st.jpeg_len = 1;
                        djpeg_st.jpeg_start = 1;
                        djpeg_st.jpeg_crc_len = 0;
                        //av_log(ffp, AV_LOG_ERROR, "########SJPG_DCT_HDRCOM:%d..1 \n",ci);
                    } else if (packet->data[ci] == JPEG_COM) {
                        djpeg_st.sta = SJPG_DCT_HDRCOM;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_HDRCOM..2 \n");
                    } else {
                        djpeg_st.sta = SJPG_NONONE;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_HDRCOM..3 \n");
                    }
                    break;
                    
                case SJPG_DCT_HDR:
                    if(packet->data[ci] == JPEG_COM) {
                        djpeg_st.sta = SJPG_DCT_TLRCOM;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_HDR.. \n");
                    }
                    break;
                    
                case SJPG_DCT_TLRCOM:
                    if (packet->data[ci] == JPEG_TLR) {
                        djpeg_st.sta = SJPG_DCT_TLR;
                        //av_log(ffp, AV_LOG_ERROR, "########SJPG_DCT_TLRCOM：%d,%d..1 \n",ci,pkt->size);
                    } else if(packet->data[ci] == JPEG_COM) {
                        djpeg_st.sta = SJPG_DCT_TLRCOM;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_TLRCOM..2 \n");
                    } else {
                        djpeg_st.sta = SJPG_DCT_HDR;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_TLRCOM:0x%x..3 \n",pkt->data[ci]);
                    }
                    break;
                    
                case SJPG_DCT_TLR: {
                    djpeg_st.jpeg_start = 0;
                    //m_TolFramPerIntv++;
                    djpeg_st.sta = SJPG_DCT_CRC;
                    add_i = 0;
                    //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_TLR.. \n");
                }
                    break;
                    
                case SJPG_DCT_CRC: {
                    static unsigned char crc_cnt = 0;
                    djpeg_st.jpeg_crc_len += (packet->data[ci] << (crc_cnt * 8));
                    crc_cnt++;
                    //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_CRC.. cnt:0x%0x,data:0x%x\n",djpeg_st.jpeg_crc_len,pkt->data[ci]);
                    if(crc_cnt >= 4) {
                        crc_cnt = 0;
                        djpeg_st.jpeg_crc_len = djpeg_st.jpeg_crc_len >> 8;
                        //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_CRC.%d,%d. \n",djpeg_st.jpeg_crc_len,djpeg_st.jpeg_len);
                        if(djpeg_st.jpeg_crc_len == djpeg_st.jpeg_len) {
                            djpeg_st.sta = SJPG_PROCESSING;
                            //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_CRC..ok \n");
                        } else {
                            djpeg_st.sta = SJPG_NONONE;
                            //av_log(ffp, AV_LOG_ERROR, "SJPG_DCT_CRC..2 \n");
                            // return 0;
                            //goto fail;
                            // crc_type=1;
                            ci = packet->size;
                        }
                    }
                }
                    break;
                    
                case SJPG_PROCESSING:
                    // do something
                    add_i = 0;
                    djpeg_st.sta = SJPG_NONONE;
                    djpeg_st.jpeg_start = 0;
                    //av_log(ffp, AV_LOG_ERROR, "SJPG_PROCESSING.. \n");
                    crc_type = 1;
                    break;
                    
                default:
                    break;
            }
            if (djpeg_st.jpeg_start) {
                if (djpeg_st.jpeg_len >= 100 * 1024) {
                    djpeg_st.jpeg_len = 100 * 1024 - 1;
                    //av_log(ffp, AV_LOG_ERROR, "jpeg_len error*******%d**************\n", djpeg_st.jpeg_len);
                }
                djpeg_st.jpeg_table[djpeg_st.jpeg_len] = packet->data[ci];
                djpeg_st.jpeg_len++;
            }
            if(add_i) {
                ci++;
            }
        }
        if(crc_type != 1) {
            crc_type = 0;
            NSLog(@"收到一个不完整的包3");
            //if (is->video_stream >= 0)
            //packet_queue_put(&is->videoq, &flush_pkt);
            //av_log(ffp, AV_LOG_ERROR, "pke error*********************\n");
            //continue;
            return NO;
        }
        //av_log(ffp, AV_LOG_ERROR, "djpeg_st.jpeg_len:%d.. \n",djpeg_st.jpeg_len);
        memcpy(packet->data, djpeg_st.jpeg_table, djpeg_st.jpeg_len);
        //#endif
        
        //替换图片吧 这个地方啊 替换掉PKT的数据吧
        int j = 0;
        int tableindex = 0;
        for (j = 0; j < packet->size - 1; j++) {
            if(packet->data[j] == 0xff && packet->data[j + 1] == 0xc4) {
                tableindex++;
                if(tableindex == 2)
                    break;
            }
        }
        
        //0x03的位置 j + 8
        int tempid = j + 8;
        int degreee = 0;
        
        if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x02){//博通test
            //*
            //av_log(ffp, AV_LOG_ERROR, "线路二，0x%x，0x%x，0x%x，0x%x，0x%x，0x%x\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5]);
            
            int tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            //*/
            /*
             double tempidx = (pkt->data[tempid+1]<<4)|pkt->data[tempid]>>4;
             double tempidy = (pkt->data[tempid+3]<<4)|pkt->data[tempid+2]>>4;
             double tempidz = (pkt->data[tempid+5]<<4)|pkt->data[tempid+4]>>4;
             */
            //av_log(ffp, AV_LOG_ERROR, "线路二，现在x：(%x),y:%x,z:%x..\n", tempidx,tempidy,tempidz);
            //test
            //degreee = computeDegree(673,18,3665);
            // av_log(ffp, AV_LOG_ERROR, "test1，现在度数：(%d)..\n", degreee);
            //degreee = computeDegree(3472,36,831);
            //av_log(ffp, AV_LOG_ERROR, "test2，现在度数：(%d)..\n", degreee);
            
            degreee = computeDegree(tempidx, tempidy, tempidz) - 90;
            if(degreee < 0) {
                degreee = degreee + 360;
            }
            //av_log(ffp, AV_LOG_ERROR, "博通2，现在度数1：(%d)..\n", degreee);
            if((degreee - old_degreee > 2) || ((old_degreee - degreee) > 2)) {
                old_degreee = degreee;
            } else {
                degreee = old_degreee;
            }
            
            //av_log(ffp, AV_LOG_ERROR, "博通2，现在度数2：(%d)..\n", degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 2, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:2];
            }
        } else if (packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x09) { //博通A1se
            //*
            //av_log(ffp, AV_LOG_ERROR, "线路二，0x%x，0x%x，0x%x，0x%x，0x%x，0x%x\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5]);
            
            int tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3]<< 8) >> 4;
            int tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5]<< 8) >> 4;
            //*/
            /*
             double tempidx = (pkt->data[tempid+1]<<4)|pkt->data[tempid]>>4;
             double tempidy = (pkt->data[tempid+3]<<4)|pkt->data[tempid+2]>>4;
             double tempidz = (pkt->data[tempid+5]<<4)|pkt->data[tempid+4]>>4;
             */
            //av_log(ffp, AV_LOG_ERROR, "线路二，现在x：(%x),y:%x,z:%x..\n", tempidx,tempidy,tempidz);
            //test
            //degreee = computeDegree(673,18,3665);
            // av_log(ffp, AV_LOG_ERROR, "test1，现在度数：(%d)..\n", degreee);
            //degreee = computeDegree(3472,36,831);
            //av_log(ffp, AV_LOG_ERROR, "test2，现在度数：(%d)..\n", degreee);
            //av_log(ffp, AV_LOG_ERROR, test2 degree degree tempic dizp mingtian);
            
            degreee = computeDegree(tempidx, tempidy, tempidz) - 90;
            if(degreee < 0) {
                degreee = degreee + 360;
            }
            //av_log(ffp, AV_LOG_ERROR, "博通9，现在度数1：(%d)..\n", degreee);
            if((degreee - old_degreee > 0) || ((old_degreee - degreee) > 0)) {
                old_degreee = degreee;
            } else {
                degreee = old_degreee;
            }
            
            //av_log(ffp, AV_LOG_ERROR, "博通9，现在度数2：(%d)..\n", degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 9, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:9];
            }
        } else if (packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x0a){//博通A3
            //*
            //av_log(ffp, AV_LOG_ERROR, "线路二，0x%x，0x%x，0x%x，0x%x，0x%x，0x%x\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5]);
            
            int tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            
            //*/
            /*
             double tempidx = (pkt->data[tempid+1]<<4)|pkt->data[tempid]>>4;
             double tempidy = (pkt->data[tempid+3]<<4)|pkt->data[tempid+2]>>4;
             double tempidz = (pkt->data[tempid+5]<<4)|pkt->data[tempid+4]>>4;
             */
            //av_log(ffp, AV_LOG_ERROR, "线路二，现在x：(%x),y:%x,z:%x..\n", tempidx,tempidy,tempidz);
            //test
            //degreee = computeDegree(673,18,3665);
            // av_log(ffp, AV_LOG_ERROR, "test1，现在度数：(%d)..\n", degreee);
            //degreee = computeDegree(3472,36,831);
            //av_log(ffp, AV_LOG_ERROR, "test2，现在度数：(%d)..\n", degreee);
            
            //degreee = computeDegree(tempidx,tempidy,tempidz)-90;
            //if(degreee<0)
            //{
            //    degreee=degreee+360;
            //}
            //degreee=360-degreee;
            degreee = computeDegree(tempidx, tempidy, tempidz) + 90;
            if (degreee < 0) {
                degreee = degreee + 360;
            }
            
            //av_log(ffp, AV_LOG_ERROR, "A3，现在度数1：(%d)..\n", degreee);
            if((degreee - old_degreee > 0) || ((old_degreee - degreee) > 0)) {
                old_degreee = degreee;
            } else {
                degreee = old_degreee;
            }
            degreee = 360 - degreee;
            
            //av_log(ffp, AV_LOG_ERROR, "A3，现在度数2：(%d)..\n", degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 0x0a, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:0x0a];
            }
        } else if (packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x07) { //博通A3pro
            //*
            //av_log(ffp, AV_LOG_ERROR, "线路二，0x%x，0x%x，0x%x，0x%x，0x%x，0x%x\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5]);
            
            int tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int tempidy = (packet->data[tempid+2] | packet->data[tempid + 3] << 8) >> 4;
            int tempidz = (packet->data[tempid+4] | packet->data[tempid + 5] << 8) >> 4;
            //*/
            /*
             double tempidx = (pkt->data[tempid+1]<<4)|pkt->data[tempid]>>4;
             double tempidy = (pkt->data[tempid+3]<<4)|pkt->data[tempid+2]>>4;
             double tempidz = (pkt->data[tempid+5]<<4)|pkt->data[tempid+4]>>4;
             */
            //av_log(ffp, AV_LOG_ERROR, "线路二，现在x：(%x),y:%x,z:%x..\n", tempidx,tempidy,tempidz);
            //test
            //degreee = computeDegree(673,18,3665);
            // av_log(ffp, AV_LOG_ERROR, "test1，现在度数：(%d)..\n", degreee);
            //degreee = computeDegree(3472,36,831);
            //av_log(ffp, AV_LOG_ERROR, "test2，现在度数：(%d)..\n", degreee);
            
            
            //                        degreee = computeDegree(tempidx,tempidy,tempidz)+90;
            //                       if(degreee>360)
            //                       {
            //                           degreee=degreee-360;
            //                       }
            //                       degreee=360-degreee;
            
            degreee = computeDegree(tempidx, tempidy, tempidz) + 90;
            if (degreee < 0) {
                degreee = degreee + 360;
            }
            
            //av_log(ffp, AV_LOG_ERROR, "A3pro，现在度数1：(%d)..\n", degreee);
            if((degreee - old_degreee > 0) || ((old_degreee - degreee) > 0)) {
                old_degreee = degreee;
            } else {
                degreee = old_degreee;
            }
            degreee = 360 - degreee;
            
            //av_log(ffp, AV_LOG_ERROR, "A3pro，现在度数2：(%d)..\n", degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 7, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:7];
            }
        }
        //unsigned char origin[12] = {0x03,0x03,0x02,0x04,0x03,0x05,0x05,0x04,0x04,0x00,0x00,0x01};
        unsigned char origin[12] = {0x01, 0x01 , 0x01 , 0x01 , 0x01 , 0x01 , 0x01 , 0x01 , 0x00 , 0x00 , 0x00 , 0x00 };
        memcpy(&packet->data[j+8], origin, 12);
    } else { // rtsp开头的地址
        //替换图片吧 这个地方啊 替换掉PKT的数据吧
        int j = 0;
        int tableindex = 0;
        for(j = 0; j < packet->size - 1; j++) {
            if(packet->data[j] == 0xff && packet->data[j + 1] == 0xc4){
                tableindex++;
                /*
                 av_log(ffp,AV_LOG_ERROR,"%d+++++++++++++++++picdata:\n",tableindex);
                 for(int ff=j;ff<j+20;ff++)
                 {
                 av_log(ffp,AV_LOG_ERROR,",0x%x\n",pkt->data[ff]);
                 
                 }
                 av_log(ffp,AV_LOG_ERROR,"+++++++++++++++++picdata end\n");
                 //*/
                if(tableindex == 2)
                    break;
            }
        }
        //0x03的位置 j + 8
        
        int tempid = j + 8;
        int degreee = 0;
        //av_log(ffp,AV_LOG_ERROR,"+++++++++++++++++tempid :0x%x\n",tempid);
        
        if (packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x01) {//维特
            degreee = packet->data[tempid] | packet->data[tempid + 1] << 8;
            //av_log(ffp, AV_LOG_ERROR, "线路一，现在度数：(%d)..\n", degreee);
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 1, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:1];
            }
        } else if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x02) {//G Sensor
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3]<< 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5]<< 8) >> 4;
            
            //tempidx=tempidx-480;
            //tempidy=tempidy-146;
            //tempidz=tempidz+2970;
            degreee = computeDegree(tempidx, tempidy, tempidz);
            //av_log(ffp,AV_LOG_ERROR,"_______________tempid:%d \n",tempid);
            //av_log(ffp,AV_LOG_ERROR,"+++++++++++++++x:%x++++++++useCos:%d，useTan:%d d:%d,od:%d\n",tempidx,useCos(tempidx,tempidy,tempidz),useTan(tempidx,tempidy,tempidz),degreee,old_degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            //av_log(ffp,AV_LOG_ERROR,"y_h:%x \n",pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z_l:%x \n",pkt->data[tempid+4]>>4);
            //av_log(ffp,AV_LOG_ERROR,"z_h:%x \n",pkt->data[tempid+5]);
            
            /*
             av_log(ffp, AV_LOG_ERROR, "线路二data：(0x%x),(0x%x),(0x%x),(0x%x),(0x%x),(0x%x).tempidx:0x%x,tempidy:0x%x,tempidz:0x%x=%d\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5],tempidx,tempidy,tempidz,degreee);
             */
            if(((tempidy > 810) && (tempidy < 1080)) || ((tempidy > 2800) && (tempidy < 3200))) {
                degreee = old_degreee;
            }
            //添加角度飘动过滤
            //av_log(ffp, AV_LOG_ERROR, "线路二new(%d),old(%d).. \n", degreee,old_degreee);
            //if(((degreee-old_degreee)>2)||((old_degreee-degreee)>2))
            //if ((((degreee - old_degreee) > 3) && ((degreee - old_degreee) < 200)) || (((old_degreee - degreee) > 3) && ((old_degreee - degreee) < 200))||((degreee - old_degreee) > 300)||((old_degreee - degreee) > 300))
            if ((((degreee - old_degreee) > 2) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 2) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                // int tem=degreee;
                degreee = old_degreee;
                //old_degreee=tem;
            }
            
            //av_log(ffp, AV_LOG_ERROR, "线路二，现在度数：(%d)..(%d)\n", degreee,old_degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 2, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:2];
            }
        } else if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x03){//G Sensor
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            
            //degreee = computeDegree(673,18,3665);
            //av_log(ffp, AV_LOG_ERROR, "线路二test:%d\n",degreee);
            //degreee = computeDegree(3141,59,254);
            //av_log(ffp, AV_LOG_ERROR, "线路二test2:%d\n",degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            
            degreee = computeDegree3(tempidx, tempidy, tempidz);
            //av_log(ffp, AV_LOG_ERROR, "线路三data：(0x%x),(0x%x),(0x%x),(0x%x),(0x%x),(0x%x).tempidx:0x%x,tempidy:0x%x,tempidz:0x%x=%d\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5],tempidx,tempidy,tempidz,degreee);
            if (degreee >= 180) {
                degreee = (degreee - 180);
            } else {
                degreee = 180 + degreee;
            }
            
            if(((tempidy > 810) && (tempidy < 1080)) || ((tempidy > 2800) && (tempidy < 3200))) {
                degreee = old_degreee;
            }
            
            //添加角度飘动过滤
            //av_log(ffp, AV_LOG_ERROR, "线路三new(%d),old(%d).. \n", degreee,old_degreee);
            if ((((degreee - old_degreee) > 2) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 2) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                degreee = old_degreee;
            }
            //av_log(ffp, AV_LOG_ERROR, "线路三，现在度数：(%d).. \n", degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 3, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:3];
            }
        } else if(packet->data[tempid + 10] == 0xfb && packet->data[tempid + 11] == 0x01){  //E7Pro 0xFB 0x01
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            
            //degreee = computeDegree(673,18,3665);
            //av_log(ffp, AV_LOG_ERROR, "线路二test:%d\n",degreee);
            //degreee = computeDegree(3141,59,254);
            //av_log(ffp, AV_LOG_ERROR, "线路二test2:%d\n",degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            
            degreee = computeDegree3(tempidx, tempidy, tempidz);
            //av_log(ffp, AV_LOG_ERROR, "线路三data：(0x%x),(0x%x),(0x%x),(0x%x),(0x%x),(0x%x).tempidx:0x%x,tempidy:0x%x,tempidz:0x%x=%d\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5],tempidx,tempidy,tempidz,degreee);
            if (degreee >= 180) {
                degreee = (degreee - 180);
            } else {
                degreee = 180 + degreee;
            }
            
            if(((tempidy > 810) && (tempidy < 1080)) || ((tempidy > 2800) && (tempidy < 3200))) {
                degreee=old_degreee;
            }
            
            //添加角度飘动过滤
            //av_log(ffp, AV_LOG_ERROR, "线路三new(%d),old(%d).. \n", degreee,old_degreee);
            if ((((degreee - old_degreee) > 2) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 2) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                degreee = old_degreee;
            }
            //av_log(ffp, AV_LOG_ERROR, "线路三，现在度数：(%d).. \n", degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 3, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:3];
            }
        } else if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x05) {//G Sensor
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3]<< 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5]<< 8) >> 4;
            
            degreee = computeDegree5(tempidx, tempidy, tempidz);
            
            //av_log(ffp,AV_LOG_ERROR,"+++++++++++++++x:%x++++++++useCos5:%d，useTan5:%d d:%d,od:%d\n",tempidx,useCos5(tempidx,tempidy,tempidz),useTan5(tempidx,tempidy,tempidz),degreee,old_degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            //av_log(ffp,AV_LOG_ERROR,"y_h:%x \n",pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z_l:%x \n",pkt->data[tempid+4]>>4);
            //av_log(ffp,AV_LOG_ERROR,"z_h:%x \n",pkt->data[tempid+5]);
            if((tempidy == 2048) || (tempidy == 2047)) {
                degreee = old_degreee;
            }
            
            if ((((degreee - old_degreee) > 0) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 0) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                // int tem=degreee;
                degreee = old_degreee;
                //old_degreee=tem;
            }
            //av_log(ffp, AV_LOG_ERROR, "线路五，现在度数：(%d)..(%d)\n", degreee,old_degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 5, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:5];
            }
        } else if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x06) {//Y1
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid+3] << 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid+5] << 8) >> 4;
            
            //tempidx=tempidx-480;
            //tempidy=tempidy-146;
            //tempidz=tempidz+2970;ß
            degreee = computeDegree(tempidx, tempidy, tempidz);
            //av_log(ffp, AV_LOG_ERROR, "丫1，现在度数：(%d)..\n", degreee);
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 6, degreee);
            self.degreee = degreee;
            self.drawMode = HZMTKViewDrawModeAsRectangle;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:6];
            }
        } else if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x08) { //e1pro
            //G Sensor
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            
            //tempidx=tempidx-480;
            //tempidy=tempidy-146;
            //tempidz=tempidz+2970;
            degreee = computeDegree(tempidx, tempidy, tempidz) + 90;
            if(degreee > 360) {
                degreee = degreee - 360;
            }
            //av_log(ffp,AV_LOG_ERROR,"_______________tempid:%d \n",tempid);
            //av_log(ffp,AV_LOG_ERROR,"+++++++++++++++x:%x++++++++useCos:%d，useTan:%d d:%d,od:%d\n",tempidx,useCos(tempidx,tempidy,tempidz),useTan(tempidx,tempidy,tempidz),degreee,old_degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            //av_log(ffp,AV_LOG_ERROR,"y_h:%x \n",pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z_l:%x \n",pkt->data[tempid+4]>>4);
            //av_log(ffp,AV_LOG_ERROR,"z_h:%x \n",pkt->data[tempid+5]);
            
            /*
             av_log(ffp, AV_LOG_ERROR, "线路二data：(0x%x),(0x%x),(0x%x),(0x%x),(0x%x),(0x%x).tempidx:0x%x,tempidy:0x%x,tempidz:0x%x=%d\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5],tempidx,tempidy,tempidz,degreee);
             */
            if(((tempidy > 810) && (tempidy < 1080)) || ((tempidy > 2800) && (tempidy < 3200))) {
                degreee = old_degreee;
            }
            //添加角度飘动过滤
            //av_log(ffp, AV_LOG_ERROR, "线路二new(%d),old(%d).. \n", degreee,old_degreee);
            //if(((degreee-old_degreee)>2)||((old_degreee-degreee)>2))
            //if ((((degreee - old_degreee) > 3) && ((degreee - old_degreee) < 200)) || (((old_degreee - degreee) > 3) && ((old_degreee - degreee) < 200))||((degreee - old_degreee) > 300)||((old_degreee - degreee) > 300))
            if ((((degreee - old_degreee) > 2) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 2) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                // int tem=degreee;
                degreee = old_degreee;
                //old_degreee=tem;
            }
            //av_log(ffp, AV_LOG_ERROR, "e1pro，现在度数：(%d)..(%d)\n", degreee,old_degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 8, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:8];
            }
        } else if(packet->data[tempid + 10] == 0xfb && packet->data[tempid + 11] == 0x02) { //e1pro ( FB 02)
            //G Sensor
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            
            //tempidx=tempidx-480;
            //tempidy=tempidy-146;
            //tempidz=tempidz+2970;
            degreee = computeDegree(tempidx, tempidy, tempidz) + 90;
            if(degreee > 360) {
                degreee = degreee - 360;
            }
            //av_log(ffp,AV_LOG_ERROR,"_______________tempid:%d \n",tempid);
            //av_log(ffp,AV_LOG_ERROR,"+++++++++++++++x:%x++++++++useCos:%d，useTan:%d d:%d,od:%d\n",tempidx,useCos(tempidx,tempidy,tempidz),useTan(tempidx,tempidy,tempidz),degreee,old_degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            //av_log(ffp,AV_LOG_ERROR,"y_h:%x \n",pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z_l:%x \n",pkt->data[tempid+4]>>4);
            //av_log(ffp,AV_LOG_ERROR,"z_h:%x \n",pkt->data[tempid+5]);
            
            
            /*
             av_log(ffp, AV_LOG_ERROR, "线路二data：(0x%x),(0x%x),(0x%x),(0x%x),(0x%x),(0x%x).tempidx:0x%x,tempidy:0x%x,tempidz:0x%x=%d\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5],tempidx,tempidy,tempidz,degreee);
             */
            if(((tempidy > 810) && (tempidy < 1080)) || ((tempidy > 2800) && (tempidy < 3200))) {
                degreee = old_degreee;
            }
            //添加角度飘动过滤
            //av_log(ffp, AV_LOG_ERROR, "线路二new(%d),old(%d).. \n", degreee,old_degreee);
            //if(((degreee-old_degreee)>2)||((old_degreee-degreee)>2))
            //if ((((degreee - old_degreee) > 3) && ((degreee - old_degreee) < 200)) || (((old_degreee - degreee) > 3) && ((old_degreee - degreee) < 200))||((degreee - old_degreee) > 300)||((old_degreee - degreee) > 300))
            if ((((degreee - old_degreee) > 2) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 2) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                // int tem=degreee;
                degreee = old_degreee;
                //old_degreee=tem;
            }
            //av_log(ffp, AV_LOG_ERROR, "e1pro，现在度数：(%d)..(%d)\n", degreee,old_degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 8, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:8];
            }
        } else if(packet->data[tempid + 10] == 0xfe && packet->data[tempid + 11] == 0x09) { //A1se
            //G Sensor
            int16_t tempidx = (packet->data[tempid] | packet->data[tempid + 1] << 8) >> 4;
            int16_t tempidy = (packet->data[tempid + 2] | packet->data[tempid + 3] << 8) >> 4;
            int16_t tempidz = (packet->data[tempid + 4] | packet->data[tempid + 5] << 8) >> 4;
            
            //tempidx=tempidx-480;
            //tempidy=tempidy-146;
            //tempidz=tempidz+2970;
            degreee = computeDegree(tempidx, tempidy, tempidz) + 90;
            
            if(degreee > 360) {
                degreee = degreee - 360;
            }
            //av_log(ffp,AV_LOG_ERROR,"_______________tempid:%d \n",tempid);
            //av_log(ffp,AV_LOG_ERROR,"+++++++++++++++x:%x++++++++useCos:%d，useTan:%d d:%d,od:%d\n",tempidx,useCos(tempidx,tempidy,tempidz),useTan(tempidx,tempidy,tempidz),degreee,old_degreee);
            //av_log(ffp,AV_LOG_ERROR,"x:%d ,xl:0x%x,,xh:0x%x\n",tempidx,pkt->data[tempid],pkt->data[tempid+1]);
            //av_log(ffp,AV_LOG_ERROR,"y:%d ,yl:0x%x,,yh:0x%x\n",tempidy,pkt->data[tempid+2],pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z:%d \n",tempidz);
            //av_log(ffp,AV_LOG_ERROR,"y_h:%x \n",pkt->data[tempid+3]);
            //av_log(ffp,AV_LOG_ERROR,"z_l:%x \n",pkt->data[tempid+4]>>4);
            //av_log(ffp,AV_LOG_ERROR,"z_h:%x \n",pkt->data[tempid+5]);
            
            /*
             av_log(ffp, AV_LOG_ERROR, "线路二data：(0x%x),(0x%x),(0x%x),(0x%x),(0x%x),(0x%x).tempidx:0x%x,tempidy:0x%x,tempidz:0x%x=%d\n", pkt->data[tempid], pkt->data[tempid+1], pkt->data[tempid+2], pkt->data[tempid+3], pkt->data[tempid+4], pkt->data[tempid+5],tempidx,tempidy,tempidz,degreee);
             */
            if(((tempidy > 810) && (tempidy < 1080)) || ((tempidy > 2800) && (tempidy < 3200))) {
                degreee = old_degreee;
            }
            //添加角度飘动过滤
            //av_log(ffp, AV_LOG_ERROR, "线路二new(%d),old(%d).. \n", degreee,old_degreee);
            //if(((degreee-old_degreee)>2)||((old_degreee-degreee)>2))
            //if ((((degreee - old_degreee) > 3) && ((degreee - old_degreee) < 200)) || (((old_degreee - degreee) > 3) && ((old_degreee - degreee) < 200))||((degreee - old_degreee) > 300)||((old_degreee - degreee) > 300))
            if ((((degreee - old_degreee) > 2) && ((degreee - old_degreee) < 358)) || (((old_degreee - degreee) > 2) && ((old_degreee - degreee) < 358))) {
                old_degreee = degreee;
            } else {
                // int tem=degreee;
                degreee = old_degreee;
                //old_degreee=tem;
            }
            //av_log(ffp, AV_LOG_ERROR, "A1se，现在度数：(%d)..(%d)\n", degreee,old_degreee);
            
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 9, degreee);
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:9];
            }
        } else { //不是陀螺仪效果 可能是UDP
            //av_log(ffp, AV_LOG_ERROR, "线路四，现在度数：(%d)..\n", degreee);
            
            //可能是陀螺仪 但是不是转数据的
            //ffp_notify_msg3(ffp, FFP_MSG_TUOLUOYI, 0, degreee);
            self.drawMode = HZMTKViewDrawModeUnknow;
            self.degreee = degreee;
            if (self.delegate && [self.delegate respondsToSelector:@selector(backTuoLuoyi:type:)]) {
                [self.delegate backTuoLuoyi:degreee type:0];
            }
        }
        
        unsigned char origin[12] = {0x03,0x03,0x02,0x04,0x03,0x05,0x05,0x04,0x04,0x00,0x00,0x01};
        memcpy(&packet->data[j+8], origin, 12);
    }
    return YES;
}

#pragma mark - HZVideoToolboxDecoderDelegate
- (void)videoToolboxDecoder:(HZVideoToolboxDecoder *)videoToolboxDecoder didGetImageBuffer:(CVPixelBufferRef)imageBuffer {
    [self drawDecodedImage:imageBuffer];
}

- (void)drawDecodedImage:(CVPixelBufferRef)imageBuffer {
#if FFMPEG_RENDER_METHOD_METAL
    float rotateAngleInRadians = self.degreee * M_PI / 180.0f;
    /*static float rotateAngleInRadians = 0.0f;
     rotateAngleInRadians += 0.02;
     self.displayLayer.drawMode = YES;*/
    [self.displayLayer drawPixelBuffer:imageBuffer withRotateAngleInRadians:rotateAngleInRadians drawMode:self.drawMode];
#else
    AVStream *stream = _pFormatCtx->streams[_videoindex];
    CMTime presentationTimeStamp = CMTimeMakeWithSeconds(_pFrame->pts * stream->time_base.num, stream->time_base.den);
    CMSampleBufferRef sampleBufferRef = [self convertCVImageBufferRefToCMSampleBufferRef:imageBuffer withPresentationTimeStamp:presentationTimeStamp];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.displayLayer enqueueSampleBuffer:sampleBufferRef];
        CFRelease(sampleBufferRef);
    });
#endif
    
    if (_playState != HZFFmpegPlayStatePlaying) {
        _playState = HZFFmpegPlayStatePlaying;
        if (self.delegate && [self.delegate respondsToSelector:@selector(moviePlayStartPlay)]) {
            [self.delegate moviePlayStartPlay];
        }
    }
}

@end
