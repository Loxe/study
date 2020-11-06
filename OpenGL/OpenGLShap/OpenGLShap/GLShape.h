//
//  GLShape.h
//  OpenGLShap
//
//  Created by JinTao on 2020/9/10.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 形状类：各种形状的顶点，顶点索引，纹理生成。 学习全景视频的OpenGL或Metal渲染
@interface GLShape : NSObject
// 顶点和纹理数据指针， 一个顶点占用3个GLfloat的顶点数据和2个GLfloat的纹理数据
@property (nonatomic, assign) GLfloat *vertexAndTextureData;
// 顶点数据和纹理数据总共有多少个字节, 顶点个数为 vertexAndTextureByteNumber / sizeof(GLfloat) / 5
@property (nonatomic, assign) GLint vertexAndTextureByteNumber;
// 顶点索引数据指针
@property (nonatomic, assign) GLint *vertexIndexData;
// 顶点索引数据总共有多少个字节, 索引的个数为 vertexIndexByteNumber / sizeof(GLint)
@property (nonatomic, assign) GLint vertexIndexByteNumber;
@end


/// 椭球
@interface GLEllipsoidShape : GLShape
/// 椭球初始化, 球心为OpenGL坐标原点
/// @param radiusX 球体x半径
/// @param radiusY 球体y半径
/// @param radiusZ 球体z半径 
/// @param slices 绕y轴旋转把球分成多少份等分角
/// @param stacks 沿y轴把球分成多少份等分角
- (instancetype)initWithRadiusX:(GLfloat)radiusX
                        radiusY:(GLfloat)radiusY
                        radiusZ:(GLfloat)radiusZ
                         slices:(GLint)slices
                         stacks:(GLint)stacks;
@end

/// 球， 椭球的特殊情况
@interface GLSphereShape : GLEllipsoidShape
- (instancetype)initWithRadius:(GLfloat)radius slices:(GLint)slices stacks:(GLint)stacks;
@end

/// 圆柱, 也可用来画棱柱
@interface GLCylinderShape : GLShape
/// 圆柱初始化, 圆柱心为OpenGL坐标原点
/// @param radius 圆柱半径
/// @param height 圆柱高
/// @param startRadian 开始弧度, 以OpenGL坐标正Z轴方向为0度, 在圆柱上面观察, 逆时针方向递增
/// @param endRadian 结束弧度, 增加弧度参数是为了将圆柱渐变到正四边形
/// @param slices 绕y轴旋转把圆柱分成多少份等分角
/// @param stacks 沿y轴把圆柱高分成多少等份
- (instancetype)initWithRadius:(GLfloat)radius
                        height:(GLfloat)height
                   startRadian:(GLfloat)startRadian
                     endRadian:(GLfloat)endRadian
                        slices:(GLint)slices
                        stacks:(GLint)stacks;
- (instancetype)initWithRadius:(GLfloat)radius
                        height:(GLfloat)height
                        slices:(GLint)slices
                        stacks:(GLint)stacks;
- (void)calculateVertexDataWithRadius:(GLfloat)radius startRadian:(GLfloat)startRadian endRadian:(GLfloat)endRadian;
@end

/// 圆椎, 圆台
@interface GLConeShape : GLShape
/// 圆台初始化, 圆椎中部圆心为OpenGL坐标原点
/// @param bottomRadius 圆椎底部圆半径
/// @param topRadius 圆椎顶部圆半径
/// @param height 圆椎高
/// @param slices 绕y轴旋转把圆椎分成多少份等分角
/// @param stacks 沿y轴把圆椎分成多少份等分高
- (instancetype)initWithBottomRadius:(GLfloat)bottomRadius
                           topRadius:(GLfloat)topRadius
                              height:(GLfloat)height
                              slices:(GLint)slices
                              stacks:(GLint)stacks;
/// 圆椎初始化, 尖朝上, 圆的特殊情况
- (instancetype)initWithBottomRadius:(GLfloat)bottomRadius
                              height:(GLfloat)height
                              slices:(GLint)slices
                              stacks:(GLint)stacks;
@end

/// 圆环体
@interface GLTorusShape : GLShape
/// 圆环体初始化, 圆环中心为OpenGL坐标原点
/// @param ringRadius 中心到环心距离
/// @param circleRadius 圆环上圆的半径
/// @param slices 绕y轴旋转把圆环分成多少份等分角
/// @param stacks 圆环切面圆分成多少份等分角
- (instancetype)initWithRingRadius:(GLfloat)ringRadius
                      circleRadius:(GLfloat)circleRadius
                            slices:(GLint)slices
                            stacks:(GLint)stacks;
@end

NS_ASSUME_NONNULL_END
