//
//  FFmpegHeader.h
//  Mac_iOSDemo
//
//  Created by Apple on 2020/10/18.
//  Copyright © 2020 JinTao. All rights reserved.
//

#ifndef FFmpegHeader_h
#define FFmpegHeader_h

int decode_video(const char *filename, const char *outfilename);
int decode_audio(const char *filename, const char *outfilename);
int encode_video(const char *filename, const char *codec_name);
int encode_audio(const char *filename);
int avmerge(char *src_file1, char *src_file2, char *out_file);
int cutvideo(const char *srcfile, const char *outfile, double startime, double endtime);
int extr_audio(char *src_filename, char *dst_filename);
int extr_video(const char *src_filename, const char *dst_filename);

#endif /* FFmpegHeader_h */
