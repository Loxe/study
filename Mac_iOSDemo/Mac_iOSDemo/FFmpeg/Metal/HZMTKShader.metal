//
//  HZMTKShader.metal
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/29.
//  Copyright © 2020 JinTao. All rights reserved.
//

#include <metal_stdlib>
#import "HZMTKShaderTypes.h"
using namespace metal;

typedef struct {
    float4 clipSpacePosition [[ position ]]; // position的修饰符表示这个是顶点
    float2 textureCoordinate; // 纹理坐标，会做插值处理
} RasterizerData;



/// YUV420sp(NV12)转RGB
kernel void
nv12ToRGBKernelFuction(texture2d<float> textureY[[texture(HZMTKFragmentTextureIndexTextureY)]], // texture表明是纹理数据，LYFragmentTextureIndexTextureY是索引
                       texture2d<float> textureUV[[texture(HZMTKFragmentTextureIndexTextureUV)]], // texture表明是纹理数据，LYFragmentTextureIndexTextureUV是索引
                       texture2d<float, access::write> textureRGB[[texture(HZMTKFragmentTextureIndexTextureRGB)]],
                       constant HZMTKConvertMatrix *convertMatrix[[buffer(HZMTKFragmentInputIndexMatrix)]],
                       uint2 grid [[thread_position_in_grid]]) {
    // 边界保护
    if(grid.x <= textureRGB.get_width() && grid.y <= textureRGB.get_height()) {
        constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
        
        float2 textureCoordinate = {1.0f * grid.x / textureY.get_width(), 1.0f * grid.y / textureY.get_height()};
        float y = textureY.sample(textureSampler, textureCoordinate).r;
        float2 uv = textureUV.sample(textureSampler, textureCoordinate).rg;
        float3 yuv = float3(y, float2(uv.r, uv.g));
        
        float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
        float4 RGB = float4(rgb, 1.0f);
        textureRGB.write(RGB, grid);
    }
}

/// 缩放并将图片处理成圆形
kernel void
scaleAndCircleImageKernelFuction(texture2d<float, access::sample> textureRGB[[texture(HZMTKFragmentTextureIndexTextureRGB)]],
                                 texture2d<float, access::write> textureTransformed[[texture(HZMTKFragmentTextureIndexTextureCircledAndScaled)]],
                                 constant HZMTKCircleAndScaleData *circleAndScaleData [[buffer(HZMTKKenelBufferIndexCircleAndScaleData)]],
                                 uint2 grid [[thread_position_in_grid]],
                                 threadgroup float3 *localBuffer [[threadgroup(0)]]) // threadgroup地址空间，这里并没有使用到；
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear); // sampler是采样器
    uint w = textureTransformed.get_width();
    uint h = textureTransformed.get_height();
    if (circleAndScaleData[0].shouldDrawAsCircle) {
        float radius = min(w, h) / 2.0f;
        float2 center = float2(w / 2.0f, h / 2.0f);
        if (distance(float2(grid), center) > radius) {
            textureTransformed.write(float4(0.0f, 0.0f, 0.0f, 1.0f), grid);
        } else {
            uint w_rgb = textureRGB.get_width() * circleAndScaleData[0].zoomRatio;
            uint h_rgb = textureRGB.get_height() * circleAndScaleData[0].zoomRatio;
            float x = (grid.x + (w_rgb - w) / 2.0f) / w_rgb;
            float y = (grid.y + (h_rgb - h) / 2.0f) / h_rgb;
            float2 point = float2(x, y);
            if (x < 0 || y < 0) { // 不正常情况下
                point = abs(point);
            }
            float4 rgba = textureRGB.sample(textureSampler, point);
            textureTransformed.write(rgba, grid);
        }
    } else {
        float2 point = float2(1.0f * grid.x / w, 1.0f * grid.y / h); // 前后比例一样
        float4 rgba = textureRGB.sample(textureSampler, point);
        textureTransformed.write(rgba, grid);
    }
}

/// 作旋转
vertex RasterizerData // 返回给片元着色器的结构体
rotateVertexShader(uint vertexID[[vertex_id]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
                   constant HZMTKVertex *vertexArray[[buffer(HZMTKVertexInputIndexVertices)]],  // buffer表明是缓存数据，0是索引
                   constant matrix_float4x4 *modelViewMatrix[[buffer(HZMTKVertexInputIndexVertexMatrix)]]) {
    RasterizerData out;
    out.clipSpacePosition = modelViewMatrix[0] * vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4
rotateFragmentShader(RasterizerData input[[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
                     texture2d<float> textureRGB[[texture(HZMTKFragmentTextureIndexTextureCircledAndScaled)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear); // sampler是采样器
    float4 rgba = textureRGB.sample(textureSampler, input.textureCoordinate);
    return rgba;
}

/// 显示在屏幕上的渲染管道
vertex RasterizerData // 返回给片元着色器的结构体
renderVertexShader(uint vertexID[[vertex_id]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
                   constant HZMTKVertex *vertexArray[[buffer(HZMTKVertexInputIndexVertices)]],  // buffer表明是缓存数据，0是索引
                   constant matrix_float4x4 *modelViewMatrix[[buffer(HZMTKVertexInputIndexVertexMatrix)]]) {
    RasterizerData out;
    out.clipSpacePosition = modelViewMatrix[0] * vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4
renderFragmentShader(RasterizerData input[[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
                     texture2d<float> textureRGB[[texture(HZMTKFragmentTextureIndexTextureCircledAndScaled)]]) {
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear); // sampler是采样器
    float4 rgba = textureRGB.sample(textureSampler, input.textureCoordinate);
    //if (RGB.a < 0.99) {
    //    discard_fragment();
    //}
    return rgba;
}


//kernel void test(device int *a) {
//    /*/// Metal支持的数据类型
//    bool a1;
//    char a2; // 8bit
//    uchar a3; unsigned char a4;
//    short a5; // 16bit
//    ushort a6; unsigned short a7;
//    int a8; // 32bit
//    uint a9; unsigned int a10;
//    half a11; // 16bit
//    float a12; // 32bit
//    size_t a13; // 64bit uint, 一般用作sizeof结果
//    ptrdiff_t a14; // 64bit int, 一般用作指针差
//    void a15;*/
//    
//    //纹理texture
//    //sample：纹理对象可以被采样, sample与read的区别是支不支持缩放插值;
//    //read：不使⽤采样器, ⼀个图形渲染函数或者⼀个并⾏计算函数可以读取纹理对象;
//    //write：⼀个图形渲染函数或者⼀个并⾏计算函数可以向纹理对象写⼊数据;
//    //texture1d<T, metal::access::sample> t;
//    texture1d_array<float, access::sample> t1;
//    texture2d<float, access::sample> t2;
//    texture2d_array<float, access::sample> t3;
//    texture3d<float, access::sample> t4;
//    texturecube<float, access::sample> t5;
//    texture2d_ms<int, access::read> t6;
//    
//    //带有深度格式的纹理必须被声明为下面纹理数据类型中的一个
//    depth2d<float> d1;
//    depth2d_array<float, access::sample> d2;
//    depthcube<float, access::sample> d3;
//    depth2d_ms<float, access::read> d4;
//    
//    //从纹理中采样时,纹理坐标是否需要归⼀化;
//    //enum class coord { normalized, pixel };
//    //设置纹理s,t,r坐标的寻址模式;
//    //enum class s_address { clamp_to_zero, clamp_to_edge, repeat, mirrored_repeat };
//    //enum class t_address { clamp_to_zero, clamp_to_edge, repeat, mirrored_repeat };
//    //enum class r_address { clamp_to_zero, clamp_to_edge, repeat, mirrored_repeat };
//    //设置纹理采样的mipMap过滤模式, 如果是none,那么只有⼀层纹理⽣效;
//    //enum class mip_filter { none, nearest, linear };
//    // 采样器必须使⽤ constexpr 修饰符声明
//    constexpr sampler textureSampler(coord::pixel, mag_filter::linear, min_filter::linear, s_address::clamp_to_edge, mip_filter::none);
//    
//    //Metal 着⾊器语⾔使⽤ 地址空间修饰符 来表示⼀个函数变量或者参数变量 被分配于那⼀⽚内存区域. 所有的着⾊函数(vertex, fragment, kernel)的参数,如果是指针或是引⽤, 都必须带有地址空间修饰符号;
//    //device : 设备地址空间 可读可写
//    //threadgrounp : 线程组地址空间 ⽤于为 并⾏计算着⾊函数分配内存变量
//    //constant : 常量地址空间
//    //thread : thread地址空间 在图形绘制着⾊函数或者并⾏计算着⾊函数中声明的变量thread 地址空间分配
//    
//    //内建变量属性修饰符
//    //[[vertex_id]] 顶点id 标识符;
//    //[[position]] 顶点信息(float4) /描 述了⽚元的窗⼝相对坐标(x, y, z, 1/w)
//    //[[point_size]] 点的⼤⼩(float)
//    //[[color(m)]] 颜⾊, m编译前得确定;
//    //[[stage_in]] ：⽚元着⾊函数使⽤的单个⽚元输⼊数据是由顶点着⾊函数输出然后经过光栅化⽣成的。顶点和⽚元着⾊函数都是只能有⼀个参数被声明为使⽤“stage_in”修饰符，对于⼀个使⽤ 了“stage_in”修饰符的⾃定义的结构体，其成员可以为⼀个整形或浮点标量，或是整形或浮点向量。
//}
