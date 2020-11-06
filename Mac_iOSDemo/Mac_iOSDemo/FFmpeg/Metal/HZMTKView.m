//
//  HZMTKView.m
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/29.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "HZMTKView.h"
#import "HZMTKShaderTypes.h"
#import <Accelerate/Accelerate.h>


@interface HZMTKView () <MTKViewDelegate>

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
/// 从ffmpeg复制来的数据
@property (nonatomic, assign) CVPixelBufferRef sourcePixelBuffer;
/// NV12转成RGB后, 用来作渲染的数据
@property (nonatomic, assign) CVPixelBufferRef rgbPixelBuffer;
@property (nonatomic, strong) id<MTLTexture> rgbTexture;
/// 作了圆形处理, 缩放等变换的数据
@property (nonatomic, assign) CVPixelBufferRef circledAndScaledPixelBuffer;
@property (nonatomic, strong) id<MTLTexture> circledAndScaledTexture;
/// 旋转后的数据
@property (nonatomic, assign) CVPixelBufferRef rotatedPixelBuffer;
@property (nonatomic, strong) id<MTLTexture> rotatedTexture;
@property (nonatomic, strong) MTLRenderPassDescriptor *rotateRenderPassDescriptor;

@property (nonatomic, strong) id<MTLComputePipelineState> nv12ComputePipelineState;
@property (nonatomic, strong) id<MTLComputePipelineState> circleComputePipelineState;
@property (nonatomic, assign) MTLSize groupSize;
@property (nonatomic, assign) MTLSize rgbGroupCount;
@property (nonatomic, assign) MTLSize transformGroupCount;

@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> rendPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> rotatePipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> verticesBuffer;
@property (nonatomic, strong) id<MTLBuffer> convertMatrixBuffer;
@property (nonatomic, assign) NSUInteger numVertices; ///< 顶点个数

@property (nonatomic, strong) dispatch_queue_t renderQueue;

@property (nonatomic, assign) float zoomRatio;
@property (nonatomic, assign) BOOL drawForDrawableSizeChanged;

@end


@implementation HZMTKView

- (void)dealloc {
    if (self.textureCache) {
        CFRelease(self.textureCache);
        self.textureCache = NULL;
    }
    
    [self freePictureData];
}

- (void)freePictureData {
    dispatch_async(self.renderQueue, ^{
        if (self.sourcePixelBuffer) {
            CVPixelBufferRelease(self.sourcePixelBuffer);
            self.sourcePixelBuffer = NULL;
        }
        if (self.rgbPixelBuffer) {
            CVPixelBufferRelease(self.rgbPixelBuffer);
            self.rgbPixelBuffer = NULL;
        }
        if (self.circledAndScaledPixelBuffer) {
            CVPixelBufferRelease(self.circledAndScaledPixelBuffer);
            self.circledAndScaledPixelBuffer = NULL;
        }
        if (self.rotatedPixelBuffer) {
            CVPixelBufferRelease(self.rotatedPixelBuffer);
            self.rotatedPixelBuffer = NULL;
        }
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.renderQueue = dispatch_queue_create("HZ.Metal.RenderQueue", DISPATCH_QUEUE_SERIAL);
        
        dispatch_sync(self.renderQueue, ^{
            self.paused = YES;
            //self.enableSetNeedsDisplay = NO;
            self.drawMode = HZMTKViewDrawModeUnknow;
            self.videoGravity = AVLayerVideoGravityResizeAspect;
            
            //self.rotateAngleInRadians = M_PI_4;
            //self.reversalMode = HZMTKViewReversalModeLeftRight;
            self.assetWriteManager = [[HZAssetWriterManager alloc] init];
            [self initMetal];
        });
    }
    return self;
}

- (void)initMetal {
    // Metal初始化
    self.device = MTLCreateSystemDefaultDevice();
    NSAssert(self.device, @"Device not support Metal.");
    self.delegate = self;
    
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> transformVertexFunction = [defaultLibrary newFunctionWithName:@"rotateVertexShader"];
    id<MTLFunction> transformFragmentFunction = [defaultLibrary newFunctionWithName:@"rotateFragmentShader"];
    MTLRenderPipelineDescriptor *rotatePipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    rotatePipelineDescriptor.vertexFunction = transformVertexFunction;
    rotatePipelineDescriptor.fragmentFunction = transformFragmentFunction;
    rotatePipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    self.rotatePipelineState = [self.device newRenderPipelineStateWithDescriptor:rotatePipelineDescriptor error:NULL];
    
    id<MTLFunction> renderVertexFunction = [defaultLibrary newFunctionWithName:@"renderVertexShader"];
    id<MTLFunction> renderFragmentFunction = [defaultLibrary newFunctionWithName:@"renderFragmentShader"];
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexFunction = renderVertexFunction;
    renderPipelineDescriptor.fragmentFunction = renderFragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    self.rendPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:NULL];
    
    self.rotateRenderPassDescriptor = [MTLRenderPassDescriptor new];
    self.rotateRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
    self.rotateRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    self.rotateRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    self.commandQueue = [self.device newCommandQueue];
    
    id<MTLFunction> nv12Function = [defaultLibrary newFunctionWithName:@"nv12ToRGBKernelFuction"];
    self.nv12ComputePipelineState = [self.device newComputePipelineStateWithFunction:nv12Function error:NULL];
    
    id<MTLFunction> circleFunction = [defaultLibrary newFunctionWithName:@"scaleAndCircleImageKernelFuction"];
    self.circleComputePipelineState = [self.device newComputePipelineStateWithFunction:circleFunction error:NULL];
    
    // 顶点
    static const HZMTKVertex quadVertices[] = {
        // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    self.verticesBuffer = [self.device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    self.numVertices = sizeof(quadVertices) / sizeof(HZMTKVertex);
    // YUV矩阵
    /*/// BT.601, which is the standard for SDTV.
     matrix_float3x3 kColorConversion = (matrix_float3x3){
     (simd_float3){1.164,    1.164   1.164},
     (simd_float3){0.0,      -0.392, 2.017},
     (simd_float3){1.596,    -0.813, 0.0},
     };*/
    /// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
    /*matrix_float3x3 kColorConversion = (matrix_float3x3){
     (simd_float3){1.0,  1.0,    1.0},
     (simd_float3){0.0,  -0.343, 1.765},
     (simd_float3){1.4,  -0.711, 0.0},
     };*/
    /// BT.709, which is the standard for HDTV.
    matrix_float3x3 kColorConversion = (matrix_float3x3){
        (simd_float3){1.164,    1.164,  1.164},
        (simd_float3){0.0,      -0.213, 2.112},
        (simd_float3){1.793,    -0.533, 0.0},
    };
    vector_float3 kColorConversionOffset = (vector_float3){-(16.0 / 255.0), -0.5, -0.5};
    HZMTKConvertMatrix matrix = {
        .matrix = kColorConversion,
        .offset = kColorConversionOffset,
    };
    self.convertMatrixBuffer = [self.device newBufferWithBytes:&matrix length:sizeof(matrix) options:MTLResourceStorageModeShared];
    
    // 纹理缓存
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
}

- (void)setRotateAngleInRadians:(float)rotateAngleInRadians {
    dispatch_async(self.renderQueue, ^{
        self->_rotateAngleInRadians = rotateAngleInRadians;
        //NSLog(@"设置角度:%f", rotateAngleInRadians);
    });
}

- (void)setDrawMode:(HZMTKViewDrawMode)drawMode {
    dispatch_async(self.renderQueue, ^{
        if (self->_drawMode == drawMode) {
            return;
        }
        self->_drawMode = drawMode;
        [self freePictureData];
    });
}

- (id<MTLBuffer>)getRotateModelViewMatrixBuffer {
    CATransform3D matrix = CATransform3DIdentity;
    
    // 反转计算
    if ((self.reversalMode & HZMTKViewReversalModeLeftRight) != 0) {
        matrix = CATransform3DRotate(matrix, M_PI, 0.0f, 1.0f, 0.0f);
    }
    if ((self.reversalMode & HZMTKViewReversalModeTopBottom) != 0) {
        matrix = CATransform3DRotate(matrix, M_PI, 1.0f, 0.0f, 0.0f);
    }
    
    // 旋转计算
    if (self.drawMode == HZMTKViewDrawModeDrawAsCircle) {
        //NSLog(@"读取角度:%f", self.rotateAngleInRadians);
        //static float rotateAngleInRadians = 0;
        //rotateAngleInRadians += 0.1f;
        matrix = CATransform3DRotate(matrix, self.rotateAngleInRadians, 0.0f, 0.0f, 1.0f);
    }
    
    // 最终数据处理
    matrix_float4x4 matrix_f = [self getMetalMatrixFromCAMatrix:matrix];
    id<MTLBuffer> buffer = [self.device newBufferWithBytes:&matrix_f length:sizeof(matrix_f) options:MTLResourceStorageModeShared];
    return buffer;
}

- (id<MTLBuffer>)getRenderModelViewMatrixBuffer {
    CATransform3D matrix = CATransform3DIdentity;
    // 屏幕填充方式计算
    size_t width = CVPixelBufferGetWidth(self.circledAndScaledPixelBuffer);
    size_t height = CVPixelBufferGetHeight(self.circledAndScaledPixelBuffer);
    if (self.circledAndScaledPixelBuffer && self.viewportSize.y > 0 && self.viewportSize.x > 0 && width > 0 && height > 0) {
        CGFloat wToH_image = 1.0f * width / height;
        CGFloat wToH_mtkView = 1.0f * self.viewportSize.x / self.viewportSize.y;
        if ([self.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
            if (wToH_image > wToH_mtkView) {
                matrix = CATransform3DScale(matrix, wToH_image / wToH_mtkView, 1.0f, 1.0f);
            } else {
                matrix = CATransform3DScale(matrix, 1.0f, wToH_mtkView / wToH_image, 1.0f);
            }
        } else if ([self.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
            
        } else {
            if (wToH_image > wToH_mtkView) {
                matrix = CATransform3DScale(matrix, 1.0f, wToH_mtkView / wToH_image, 1.0f);
            } else {
                matrix = CATransform3DScale(matrix, wToH_image / wToH_mtkView, 1.0f, 1.0f);
            }
        }
    }
    
    // 最终数据处理
    matrix_float4x4 matrix_f = [self getMetalMatrixFromCAMatrix:matrix];
    id<MTLBuffer> buffer = [self.device newBufferWithBytes:&matrix_f length:sizeof(matrix_f) options:MTLResourceStorageModeShared];
    return buffer;
}

/// Metal框架中没找到矩阵计算的API, 用CoreAnimation的计算后再转成Metal数据
- (matrix_float4x4)getMetalMatrixFromCAMatrix:(CATransform3D)matrix {
    matrix_float4x4 ret = (matrix_float4x4){
        simd_make_float4(matrix.m11, matrix.m12, matrix.m13, matrix.m14),
        simd_make_float4(matrix.m21, matrix.m22, matrix.m23, matrix.m24),
        simd_make_float4(matrix.m31, matrix.m32, matrix.m33, matrix.m34),
        simd_make_float4(matrix.m41, matrix.m42, matrix.m43, matrix.m44),
    };
    return ret;
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    //NSLog(@"drawableSize:%@", NSStringFromCGSize(size));
    dispatch_async(self.renderQueue, ^{
        self.viewportSize = (vector_uint2){size.width, size.height};
        if (self.rotatedTexture) {
            self.drawForDrawableSizeChanged = YES;
            [self draw];
        }
    });
}

- (void)drawInMTKView:(MTKView *)view {
    if (!self.drawForDrawableSizeChanged) {
        //计算
        //nv12转RGB
        id<MTLCommandBuffer> nv12CommandBuffer = [self.commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> nv12Encoder = [nv12CommandBuffer computeCommandEncoder];
        [nv12Encoder setComputePipelineState:self.nv12ComputePipelineState];
        if (self.sourcePixelBuffer) {
            [self setupYUVTextureWithEncoder:nv12Encoder];
        }
        [nv12Encoder setTexture:self.rgbTexture atIndex:HZMTKFragmentTextureIndexTextureRGB];
        [nv12Encoder setBuffer:self.convertMatrixBuffer offset:0 atIndex:HZMTKFragmentInputIndexMatrix];
        [nv12Encoder setThreadgroupMemoryLength:(sizeof(vector_float3) + 15) / 16 * 16 atIndex:0];
        // 计算区域
        [nv12Encoder dispatchThreadgroups:self.rgbGroupCount threadsPerThreadgroup:self.groupSize];
        // 调用endEncoding释放编码器，下个encoder才能创建
        [nv12Encoder endEncoding];
        [nv12CommandBuffer commit]; // 提交；
        [nv12CommandBuffer waitUntilCompleted];
        //CVPixelBufferRef p1 = self.rgbPixelBuffer;
        
        //缩放, 圆形处理
        id<MTLCommandBuffer> circleCommandBuffer = [self.commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> circleEncoder = [circleCommandBuffer computeCommandEncoder];
        [circleEncoder setComputePipelineState:self.circleComputePipelineState];
        [circleEncoder setTexture:self.rgbTexture atIndex:HZMTKFragmentTextureIndexTextureRGB];
        [circleEncoder setTexture:self.circledAndScaledTexture atIndex:HZMTKFragmentTextureIndexTextureCircledAndScaled];
        HZMTKCircleAndScaleData circleAndScaleData = {
            .shouldDrawAsCircle = self.drawMode == HZMTKViewDrawModeDrawAsCircle ? true : false,
            .zoomRatio = self.zoomRatio,
        };
        id<MTLBuffer> shouldDrawAsCircleBuffer = [self.device newBufferWithBytes:&circleAndScaleData length:sizeof(circleAndScaleData) options:MTLResourceStorageModeShared];
        [circleEncoder setBuffer:shouldDrawAsCircleBuffer offset:0 atIndex:HZMTKKenelBufferIndexCircleAndScaleData];
        [circleEncoder setThreadgroupMemoryLength:(sizeof(vector_float3) + 15) / 16 * 16 atIndex:0];
        // 计算区域
        [circleEncoder dispatchThreadgroups:self.transformGroupCount threadsPerThreadgroup:self.groupSize];
        // 调用endEncoding释放编码器，下个encoder才能创建
        [circleEncoder endEncoding];
        [circleCommandBuffer commit]; // 提交；
        [circleCommandBuffer waitUntilCompleted];
        //CVPixelBufferRef p3 = self.circledAndScaledPixelBuffer;
        
        // 旋转
        //[self rotateRenderPixelBuffer:self.rotateAngleInRadians];
        id<MTLCommandBuffer> rotateCommandBuffer = [self.commandQueue commandBuffer];
        if (self.rotateRenderPassDescriptor) {
            self.rotateRenderPassDescriptor.colorAttachments[0].texture = self.rotatedTexture;
            id<MTLRenderCommandEncoder> rotateEncoder = [rotateCommandBuffer renderCommandEncoderWithDescriptor:self.rotateRenderPassDescriptor];
            size_t w = CVPixelBufferGetWidth(self.rotatedPixelBuffer);
            size_t h = CVPixelBufferGetHeight(self.rotatedPixelBuffer);
            MTLViewport viewport = {0.0f, 0.0f, w, h , -1.0f, 1.0f};
            [rotateEncoder setViewport:viewport];
            [rotateEncoder setRenderPipelineState:self.rotatePipelineState];
            [rotateEncoder setVertexBuffer:self.verticesBuffer offset:0 atIndex:HZMTKVertexInputIndexVertices];
            id<MTLBuffer> modelViewMatrixBuffer = [self getRotateModelViewMatrixBuffer];
            [rotateEncoder setVertexBuffer:modelViewMatrixBuffer offset:0 atIndex:HZMTKVertexInputIndexVertexMatrix];
            [rotateEncoder setFragmentTexture:self.circledAndScaledTexture atIndex:HZMTKFragmentTextureIndexTextureCircledAndScaled];
            [rotateEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];
            [rotateEncoder endEncoding];
        }
        [rotateCommandBuffer commit]; // 提交；
        [rotateCommandBuffer waitUntilCompleted];
        //CVPixelBufferRef p2 = self.rotatedPixelBuffer;
        
        //录像
        if (self.assetWriteManager.isRecording) {
            [self.assetWriteManager recordPixelBuffer:self.rotatedPixelBuffer];
        }
    }
    
    //渲染
    id<MTLCommandBuffer> renderCommandBuffer = [self.commandQueue commandBuffer];
    // MTLRenderPassDescriptor 相当于OpenGL里的FrameBuffer, 不用当前view的,自己创建一个, 就可以拿到渲染的数据了
    // renderPassDescriptor.colorAttachments[0].texture = renderTexture; //要想拿到渲染数据, 要自己管理这个texture
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor) {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
        id<MTLRenderCommandEncoder> renderEncoder = [renderCommandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        MTLViewport viewport = {0.0f, 0.0f, self.viewportSize.x, self.viewportSize.y, -1.0f, 1.0f};
        [renderEncoder setViewport:viewport];
        [renderEncoder setRenderPipelineState:self.rendPipelineState];
        [renderEncoder setVertexBuffer:self.verticesBuffer offset:0 atIndex:HZMTKVertexInputIndexVertices];
        id<MTLBuffer> modelViewMatrixBuffer = [self getRenderModelViewMatrixBuffer];
        [renderEncoder setVertexBuffer:modelViewMatrixBuffer offset:0 atIndex:HZMTKVertexInputIndexVertexMatrix];
        [renderEncoder setFragmentTexture:self.rotatedTexture atIndex:HZMTKFragmentTextureIndexTextureCircledAndScaled];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];
        [renderEncoder endEncoding];
        [renderCommandBuffer presentDrawable:view.currentDrawable];
    }
    [renderCommandBuffer commit];
    [renderCommandBuffer waitUntilCompleted];
    
    self.drawForDrawableSizeChanged = NO;
}

#pragma mark -
- (void)drawPixelBuffer:(CVPixelBufferRef)pixelBuffer withRotateAngleInRadians:(float)rotateAngleInRadians drawMode:(HZMTKViewDrawMode)drawMode {
    if (!pixelBuffer) {
        return;
    }
    
    if (!self.sourcePixelBuffer) {
        dispatch_sync(self.renderQueue, ^{
            if (drawMode != HZMTKViewDrawModeUnknow &&
                self->_drawMode != drawMode) { // 当ffmpeg的数据为unknow时, 画方的还是画圆的由外部判断
                self->_drawMode = drawMode;
            }
            if (drawMode == HZMTKViewDrawModeDrawAsCircle) { // 其它情况下这个角度由外部设置, 可能是udp的socket数据来的
                self->_rotateAngleInRadians = rotateAngleInRadians;
            }
            [self createPictureData:pixelBuffer];
        });
    }
    
    if (CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess) {
        // 将数据复制出来
        CVPixelBufferLockBaseAddress(self.sourcePixelBuffer, 0);
        void* data = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        size_t w = CVPixelBufferGetBytesPerRowOfPlane(self.sourcePixelBuffer, 0);
        size_t h = CVPixelBufferGetHeightOfPlane(self.sourcePixelBuffer, 0);
        void* tagetData = CVPixelBufferGetBaseAddressOfPlane(self.sourcePixelBuffer, 0);
        memcpy(tagetData, data, h * w);
        data = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        tagetData = CVPixelBufferGetBaseAddressOfPlane(self.sourcePixelBuffer, 1);
        w = CVPixelBufferGetBytesPerRowOfPlane(self.sourcePixelBuffer, 1);
        h = CVPixelBufferGetHeightOfPlane(self.sourcePixelBuffer, 1);
        memcpy(tagetData, data, h * w);
        CVPixelBufferUnlockBaseAddress(self.sourcePixelBuffer, 0);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
    
    dispatch_async(self.renderQueue, ^{
        if (drawMode != HZMTKViewDrawModeUnknow &&
            self->_drawMode != drawMode) { // 当ffmpeg的数据为unknow时, 画方的还是画圆的由外部判断
            self->_drawMode = drawMode;
        }
        if (drawMode == HZMTKViewDrawModeDrawAsCircle) { // 其它情况下这个角度由外部设置, 可能是udp的socket数据来的
            self->_rotateAngleInRadians = rotateAngleInRadians;
        }
        [self draw];
    });
}

- (void)createPictureData:(CVPixelBufferRef)pixelBuffer {
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    if (width <= 0 || height <= 0) {
        return;
    }
    
    // 源YUV数据
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, attrs, &_sourcePixelBuffer);
    
    // RGB数据
    CVPixelBufferRef rgbPixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &rgbPixelBuffer);
    MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
    CVMetalTextureRef rgbTexture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, rgbPixelBuffer, NULL, pixelFormat, width, height, 0, &rgbTexture);
    if(status == kCVReturnSuccess) {
        self.rgbTexture = CVMetalTextureGetTexture(rgbTexture);
        self.rgbPixelBuffer = rgbPixelBuffer;
        CFRelease(rgbTexture);
    } else {
        //NSLog(@"textureCache: %p", self.textureCache);
        NSAssert(NO, @"CVMetalTextureCacheCreateTextureFromImage fail");
    }
    
    // 设置GPU计算
    self.groupSize = MTLSizeMake(16, 16, 1); // 太大某些GPU不支持，太小效率低；
    //保证每个像素都有处理到
    _rgbGroupCount.width  = (width  + self.groupSize.width -  1) / self.groupSize.width;
    _rgbGroupCount.height = (height + self.groupSize.height - 1) / self.groupSize.height;
    _rgbGroupCount.depth = 1; // 我们是2D纹理，深度设为1
    
    self.zoomRatio = 1.0f;
    if (self.drawMode == HZMTKViewDrawModeDrawAsCircle) {
        width = MIN(width, height);
        height = width;
    }
    while (width * self.zoomRatio * height * self.zoomRatio < 1000000) {
        self.zoomRatio += 0.5;
    }
    
    // 缩放及圆形处理后的数据
    if (self.drawMode == HZMTKViewDrawModeDrawAsCircle) {
        width = width * self.zoomRatio;
        height = width;
    } else {
        width = width * self.zoomRatio;
        height = height * self.zoomRatio;
    }
    CVPixelBufferRef circledAndScaledPixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &circledAndScaledPixelBuffer);
    CVMetalTextureRef circledAndScaledTexture = NULL;
    status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, circledAndScaledPixelBuffer, NULL, pixelFormat, width, height, 0, &circledAndScaledTexture);
    if(status == kCVReturnSuccess) {
        self.circledAndScaledTexture = CVMetalTextureGetTexture(circledAndScaledTexture);
        self.circledAndScaledPixelBuffer = circledAndScaledPixelBuffer;
        CFRelease(circledAndScaledTexture);
    } else {
        //NSLog(@"textureCache: %p", self.textureCache);
        NSAssert(NO, @"CVMetalTextureCacheCreateTextureFromImage fail");
    }
    _transformGroupCount.width  = (width  + self.groupSize.width -  1) / self.groupSize.width;
    _transformGroupCount.height = (height + self.groupSize.height - 1) / self.groupSize.height;
    _transformGroupCount.depth = 1; // 我们是2D纹理，深度设为1
    
    // 旋转后的数据
    CVPixelBufferRef rotatedPixelBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &rotatedPixelBuffer);
    CVMetalTextureRef rotatedTexture = NULL;
    status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, rotatedPixelBuffer, NULL, pixelFormat, width, height, 0, &rotatedTexture);
    if(status == kCVReturnSuccess) {
        self.rotatedTexture = CVMetalTextureGetTexture(rotatedTexture);
        self.rotatedPixelBuffer = rotatedPixelBuffer;
        CFRelease(rotatedTexture);
    } else {
        //NSLog(@"textureCache: %p", self.textureCache);
        NSAssert(NO, @"CVMetalTextureCacheCreateTextureFromImage fail");
    }
}

- (void)setupYUVTextureWithEncoder:(id<MTLComputeCommandEncoder>)encoder {
    id<MTLTexture> textureY = nil;
    id<MTLTexture> textureUV = nil;
    // textureY 设置
    size_t width = CVPixelBufferGetWidthOfPlane(self.sourcePixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(self.sourcePixelBuffer, 0);
    MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm; // 这里的颜色格式不是RGBA
    
    CVMetalTextureRef textureY_cv = NULL; // CoreVideo的Metal纹理
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, self.sourcePixelBuffer, NULL, pixelFormat, width, height, 0, &textureY_cv);
    if(status == kCVReturnSuccess) {
        textureY = CVMetalTextureGetTexture(textureY_cv); // 转成Metal用的纹理
        CFRelease(textureY_cv);
    }
    
    // textureUV 设置
    width = CVPixelBufferGetWidthOfPlane(self.sourcePixelBuffer, 1);
    height = CVPixelBufferGetHeightOfPlane(self.sourcePixelBuffer, 1);
    pixelFormat = MTLPixelFormatRG8Unorm; // 2-8bit的格式
    
    CVMetalTextureRef textureUV_cv = NULL; // CoreVideo的Metal纹理
    status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, self.sourcePixelBuffer, NULL, pixelFormat, width, height, 1, &textureUV_cv);
    if(status == kCVReturnSuccess) {
        textureUV = CVMetalTextureGetTexture(textureUV_cv); // 转成Metal用的纹理
        CFRelease(textureUV_cv);
    }
    
    if(textureY != nil && textureUV != nil) {
        [encoder setTexture:textureY atIndex:HZMTKFragmentTextureIndexTextureY];
        [encoder setTexture:textureUV atIndex:HZMTKFragmentTextureIndexTextureUV];
    }
}

#pragma mark - 截图
- (void)screenShotWithFilePath:(NSString *)filePath withCompletionHandler:(void (^)(UIImage * _Nullable image))completionHandler {
    if (filePath.length <= 0) {
        NSLog(@"传入路径为空");
        return;
    }
    dispatch_async(self.renderQueue, ^{
        CVPixelBufferRef pixelBuffer = self.rotatedPixelBuffer;
        if (!pixelBuffer) {
            NSLog(@"Meatl未初始化");
            return;
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                        width, height, 8,
                                                        bytesPerRow,
                                                        colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        // 用CIImage在公司的Iphone6P上UIImage转不成NSData
        //CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        //UIImage *uiImage = [UIImage imageWithCIImage:ciImage];
        UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        NSData *imageData = UIImagePNGRepresentation(uiImage);
        if (!imageData) {
            NSLog(@"没有图片数据");
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [imageData writeToFile:filePath atomically:NO];
        
        if (completionHandler) {
            completionHandler(uiImage);
        }
    });
}

#pragma mark 录像
- (void)startRecordWithFilePath:(NSString *)filePath {
    if (self.zoomRatio <= 0) {
        NSLog(@"视频未初始化");
        return;
    }
    if (!filePath) {
        NSLog(@"传入路径有问题");
        return;
    }
    dispatch_async(self.renderQueue, ^{
        if (!self.rotatedPixelBuffer) {
            NSLog(@"没在渲染");
            return;
        }
        [self.assetWriteManager startRecordWithPixelBuffer:self.rotatedPixelBuffer filePath:filePath];
    });
}

- (void)stopRecord {
    dispatch_async(self.renderQueue, ^{
        [self.assetWriteManager stopRecordWithCompletion:nil];
    });
}


#pragma mark - 缩放旋转
// 用vImage库做缩放旋转, 高清视频, CPU占用率很高, 后面这些操作改用GPU去完成
- (void)rotateRenderPixelBuffer:(float)rotateAngleInRadians {
    if (self.drawMode != HZMTKViewDrawModeDrawAsCircle || rotateAngleInRadians == 0.0f) {
        return;
    }

    CVPixelBufferRef pixelBuffer = self.rgbPixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixel = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    if (width <= 0 || height <= 0) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        return;
    }
    size_t rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer);
    vImage_Buffer buffer = {
        .data = pixel,
        .height = height,
        .width = width,
        .rowBytes = rowBytes,
    };
    Pixel_8888 backColor = {0.0f, 0.0f, 0.0f, 1.0f};
    vImage_Error error = vImageRotate_ARGB8888(&buffer, &buffer, NULL, rotateAngleInRadians, backColor, kvImageBackgroundColorFill);
    if (error != kvImageNoError) {
        NSLog(@"vImageRotate_ARGB8888 error %zd", error);
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (CVPixelBufferRef)getScaledPixelBuffer {
    CVPixelBufferRef pixelBuffer = self.rgbPixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    void *pixel = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    if (width <= 0 || height <= 0) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        return nil;
    }
    size_t rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer);
    vImage_Buffer sourceBuffer = {
        .data = pixel,
        .height = height,
        .width = width,
        .rowBytes = rowBytes,
    };
    
    vImagePixelCount scaledWidth = width * self.zoomRatio;
    vImagePixelCount scaledHeight = height * self.zoomRatio;
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferRef scaledPixelBuffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, scaledWidth, scaledHeight, kCVPixelFormatType_32BGRA, attrs, &scaledPixelBuffer);
    if (!scaledPixelBuffer) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        return nil;
    }
    CVPixelBufferLockBaseAddress(scaledPixelBuffer, 0);
    void *scaledBufferData = CVPixelBufferGetBaseAddressOfPlane(scaledPixelBuffer, 0);
    size_t scaledRowBytes = CVPixelBufferGetBytesPerRow(scaledPixelBuffer);
    vImage_Buffer scaledBuffer = {
        .data = scaledBufferData,
        .height = scaledHeight,
        .width = scaledWidth,
        .rowBytes = scaledRowBytes,
    };
    vImage_Error error = vImageScale_ARGB8888(&sourceBuffer, &scaledBuffer, NULL, kvImageHighQualityResampling);
    if (error != kvImageNoError) {
        NSLog(@"vImageScale_ARGB8888 error %zd", error);
        CVPixelBufferUnlockBaseAddress(scaledPixelBuffer, 0);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferRelease(scaledPixelBuffer);
        return nil;
    }
    
    CVPixelBufferUnlockBaseAddress(scaledPixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    return scaledPixelBuffer;
}

@end
