//
//  GLShape.m
//  OpenGLShap
//
//  Created by JinTao on 2020/9/10.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "GLShape.h"

@implementation GLShape

- (void)dealloc {
    if (self.vertexAndTextureData) {
        free(self.vertexAndTextureData);
    }
    if (self.vertexIndexData) {
        free(self.vertexIndexData);
    }
}

@end


@implementation GLEllipsoidShape

- (instancetype)initWithRadiusX:(GLfloat)radiusX radiusY:(GLfloat)radiusY radiusZ:(GLfloat)radiusZ slices:(GLint)slices stacks:(GLint)stacks {
    if (self = [super init]) {
        GLint numberOfVertex = (slices + 1) * (stacks + 1); // 顶点数
        self.vertexAndTextureByteNumber = 5 * numberOfVertex * sizeof(GLfloat);
        self.vertexAndTextureData = malloc(self.vertexAndTextureByteNumber);
        GLfloat radianPerSlice = 2 * M_PI / slices;
        GLfloat radianPerStack = M_PI / stacks;
        GLfloat textureSPerSlice = 1.0 / slices;
        GLfloat textureTPerStack = 1.0 / stacks;
        for (int i = 0; i <= slices; i++) {
            for (int j = 0; j <= stacks; j++) {
                GLint index = (i * (stacks + 1) + j) * 5;
                //顶点
                GLfloat radius_slice = M_PI_2 + i * radianPerSlice;
                GLfloat radius_stack =  j * radianPerStack;
                GLfloat x = -sinf(radius_stack) * cosf(radius_slice) * radiusX;
                GLfloat y = -cosf(radius_stack) * radiusY;
                GLfloat z = sinf(radius_stack) * sinf(radius_slice) * radiusZ;
                self.vertexAndTextureData[index + 0] = x;
                self.vertexAndTextureData[index + 1] = y;
                self.vertexAndTextureData[index + 2] = z;
                //纹理
                GLfloat s = i * textureSPerSlice;
                GLfloat t = j * textureTPerStack;
                self.vertexAndTextureData[index + 3] = s;
                self.vertexAndTextureData[index + 4] = t;
                
                //NSLog(@"i:%d j:%d index:%d radianStack:%f radianSlice:%f", i, j, index, j * radianPerStack, i * radianPerSlice);
                //NSLog(@"vertexAndTexture %d x:%f y:%f z:%f", index, self.vertexAndTextureData[index + 0], self.vertexAndTextureData[index + 1], self.vertexAndTextureData[index + 2]);
            }
        }
        
        GLint numberOfQuadrangle = slices * stacks; // 四边形数
        self.vertexIndexByteNumber = numberOfQuadrangle * 2 * 3 * sizeof(GLint); // 每个四边开有两个三角形，一个三角形三个顶点
        self.vertexIndexData = malloc(self.vertexIndexByteNumber);
        for (int i = 0; i < slices; i++) {
            for (int j = 0; j < stacks; j++) {
                GLint index = (i * stacks + j) * 6;
                self.vertexIndexData[index + 0] = i * (stacks + 1) + j;
                self.vertexIndexData[index + 1] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 2] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 3] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 4] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 5] = (i + 1) * (stacks + 1) + j + 1;
                
                //NSLog(@"vertexIndex: %d %d %d %d %d %d", self.vertexIndexData[i * j + 0], self.vertexIndexData[i * j + 1], self.vertexIndexData[i * j + 2], self.vertexIndexData[i * j + 3], self.vertexIndexData[i * j + 4], self.vertexIndexData[i * j + 5]);
            }
        }
    }
    return self;
}

@end

@implementation GLSphereShape
- (instancetype)initWithRadius:(GLfloat)radius slices:(GLint)slices stacks:(GLint)stacks {
    if (self = [super initWithRadiusX:radius radiusY:radius radiusZ:radius slices:slices stacks:stacks]) {
        
    }
    return self;
}
@end



@interface GLCylinderShape ()
@property (nonatomic, assign) GLfloat height;
@property (nonatomic, assign) GLint slices;
@property (nonatomic, assign) GLint stacks;
@end

@implementation GLCylinderShape

- (instancetype)initWithRadius:(GLfloat)radius
                        height:(GLfloat)height
                   startRadian:(GLfloat)startRadian
                     endRadian:(GLfloat)endRadian
                        slices:(GLint)slices
                        stacks:(GLint)stacks {
    if (self = [super init]) {
        self.height = height;
        self.slices = slices;
        self.stacks = stacks;
        GLint numberOfVertex = (slices + 1) * (stacks + 1); // 顶点数
        self.vertexAndTextureByteNumber = 5 * numberOfVertex * sizeof(GLfloat);
        self.vertexAndTextureData = malloc(self.vertexAndTextureByteNumber);
        
        [self calculateVertexDataWithRadius:radius startRadian:startRadian endRadian:endRadian];
        
        GLint numberOfQuadrangle = slices * stacks; // 四边形数
        self.vertexIndexByteNumber = numberOfQuadrangle * 2 * 3 * sizeof(GLint); // 每个四边开有两个三角形，一个三角形三个顶点
        self.vertexIndexData = malloc(self.vertexIndexByteNumber);
        for (int i = 0; i < slices; i++) {
            for (int j = 0; j < stacks; j++) {
                GLint index = (i * stacks + j) * 6;
                self.vertexIndexData[index + 0] = i * (stacks + 1) + j;
                self.vertexIndexData[index + 1] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 2] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 3] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 4] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 5] = (i + 1) * (stacks + 1) + j + 1;
                
                //NSLog(@"vertexIndex: %d %d %d %d %d %d", self.vertexIndexData[i * j + 0], self.vertexIndexData[i * j + 1], self.vertexIndexData[i * j + 2], self.vertexIndexData[i * j + 3], self.vertexIndexData[i * j + 4], self.vertexIndexData[i * j + 5]);
            }
        }
    }
    return self;
}

- (instancetype)initWithRadius:(GLfloat)radius height:(GLfloat)height slices:(GLint)slices stacks:(GLint)stacks {
    return [self initWithRadius:radius height:height startRadian:0.0f endRadian:2 * M_PI slices:slices stacks:stacks];
}

- (void)calculateVertexDataWithRadius:(GLfloat)radius startRadian:(GLfloat)startRadian endRadian:(GLfloat)endRadian {
    GLfloat radianPerSlice = fabsf(endRadian - startRadian) / self.slices;
    GLfloat textureSPerSlice = 1.0 / self.slices;
    GLfloat textureTPerStack = 1.0 / self.stacks;
    for (int i = 0; i <= self.slices; i++) {
        for (int j = 0; j <= self.stacks; j++) {
            GLint index = (i * (self.stacks + 1) + j) * 5;
            //顶点
            GLfloat radius_slice = i * radianPerSlice;
            GLfloat x = sinf(radius_slice) * radius;
            GLfloat y = -self.height / 2 + (self.height / self.stacks * j);
            GLfloat z = cosf(radius_slice) * radius;
            self.vertexAndTextureData[index + 0] = x;
            self.vertexAndTextureData[index + 1] = y;
            self.vertexAndTextureData[index + 2] = z;
            //纹理
            GLfloat s = i * textureSPerSlice;
            GLfloat t = j * textureTPerStack;
            self.vertexAndTextureData[index + 3] = s;
            self.vertexAndTextureData[index + 4] = t;
            
            //NSLog(@"i:%d j:%d index:%d radianStack:%f radianSlice:%f", i, j, index, j * radianPerStack, i * radianPerSlice);
            //NSLog(@"vertexAndTexture %d x:%f y:%f z:%f", index, self.vertexAndTextureData[index + 0], self.vertexAndTextureData[index + 1], self.vertexAndTextureData[index + 2]);
        }
    }
}

@end


@implementation GLConeShape

- (instancetype)initWithBottomRadius:(GLfloat)bottomRadius
                           topRadius:(GLfloat)topRadius
                              height:(GLfloat)height
                              slices:(GLint)slices
                              stacks:(GLint)stacks {
    if (self = [super init]) {
        GLint numberOfVertex = (slices + 1) * (stacks + 1); // 顶点数
        self.vertexAndTextureByteNumber = 5 * numberOfVertex * sizeof(GLfloat);
        self.vertexAndTextureData = malloc(self.vertexAndTextureByteNumber);
        GLfloat radianPerSlice = 2 * M_PI / slices;
        GLfloat heightPerStack = height / stacks;
        GLfloat textureSPerSlice = 1.0 / slices;
        GLfloat textureTPerStack = 1.0 / stacks;
        for (int i = 0; i <= slices; i++) {
            for (int j = 0; j <= stacks; j++) {
                GLint index = (i * (stacks + 1) + j) * 5;
                //顶点
                GLfloat radius_slice = i * radianPerSlice;
                GLfloat height_stack = j * heightPerStack;
                GLfloat radius = bottomRadius - (height_stack * (bottomRadius - topRadius)) / height;
                GLfloat x = sinf(radius_slice) * radius;
                GLfloat y = -height / 2 + (height / stacks * j);
                GLfloat z = cosf(radius_slice) * radius;
                self.vertexAndTextureData[index + 0] = x;
                self.vertexAndTextureData[index + 1] = y;
                self.vertexAndTextureData[index + 2] = z;
                //纹理
                GLfloat s = i * textureSPerSlice;
                GLfloat t = j * textureTPerStack;
                self.vertexAndTextureData[index + 3] = s;
                self.vertexAndTextureData[index + 4] = t;
                
                //NSLog(@"i:%d j:%d index:%d radianStack:%f radianSlice:%f", i, j, index, j * radianPerStack, i * radianPerSlice);
                //NSLog(@"vertexAndTexture %d x:%f y:%f z:%f", index, self.vertexAndTextureData[index + 0], self.vertexAndTextureData[index + 1], self.vertexAndTextureData[index + 2]);
            }
        }
        
        GLint numberOfQuadrangle = slices * stacks; // 四边形数
        self.vertexIndexByteNumber = numberOfQuadrangle * 2 * 3 * sizeof(GLint); // 每个四边开有两个三角形，一个三角形三个顶点
        self.vertexIndexData = malloc(self.vertexIndexByteNumber);
        for (int i = 0; i < slices; i++) {
            for (int j = 0; j < stacks; j++) {
                GLint index = (i * stacks + j) * 6;
                self.vertexIndexData[index + 0] = i * (stacks + 1) + j;
                self.vertexIndexData[index + 1] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 2] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 3] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 4] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 5] = (i + 1) * (stacks + 1) + j + 1;
                
                //NSLog(@"vertexIndex: %d %d %d %d %d %d", self.vertexIndexData[i * j + 0], self.vertexIndexData[i * j + 1], self.vertexIndexData[i * j + 2], self.vertexIndexData[i * j + 3], self.vertexIndexData[i * j + 4], self.vertexIndexData[i * j + 5]);
            }
        }
    }
    return self;
}

- (instancetype)initWithBottomRadius:(GLfloat)bottomRadius
                              height:(GLfloat)height
                              slices:(GLint)slices
                              stacks:(GLint)stacks {
    return [self initWithBottomRadius:bottomRadius topRadius:0.0f height:height slices:slices stacks:stacks];
}

@end


@implementation GLTorusShape

- (instancetype)initWithRingRadius:(GLfloat)ringRadius
                      circleRadius:(GLfloat)circleRadius
                            slices:(GLint)slices
                            stacks:(GLint)stacks {
    if (self = [super init]) {
        GLint numberOfVertex = (slices + 1) * (stacks + 1); // 顶点数
        self.vertexAndTextureByteNumber = 5 * numberOfVertex * sizeof(GLfloat);
        self.vertexAndTextureData = malloc(self.vertexAndTextureByteNumber);
        GLfloat radianPerSlice = 2 * M_PI / slices;
        GLfloat radianPerStack = 2 * M_PI / stacks;
        GLfloat textureSPerSlice = 1.0 / slices;
        GLfloat textureTPerStack = 1.0 / stacks;
        for (int i = 0; i <= slices; i++) {
            for (int j = 0; j <= stacks; j++) {
                GLint index = (i * (stacks + 1) + j) * 5;
                //顶点
                GLfloat radius_slice = i * radianPerSlice;
                GLfloat radius_stack = j * radianPerStack;
                GLfloat x = sinf(radius_slice) * ringRadius + sinf(radius_slice) * sinf(radius_stack) * circleRadius;
                GLfloat y = cosf(radius_stack + M_PI) * circleRadius;
                GLfloat z = cosf(radius_slice) * ringRadius + cosf(radius_slice) * sinf(radius_stack) * circleRadius;
                self.vertexAndTextureData[index + 0] = x;
                self.vertexAndTextureData[index + 1] = y;
                self.vertexAndTextureData[index + 2] = z;
                //纹理
                GLfloat s = i * textureSPerSlice;
                GLfloat t = j * textureTPerStack;
                self.vertexAndTextureData[index + 3] = s;
                self.vertexAndTextureData[index + 4] = t;
                
                //NSLog(@"i:%d j:%d index:%d radianStack:%f radianSlice:%f", i, j, index, j * radianPerStack, i * radianPerSlice);
                //NSLog(@"vertexAndTexture %d x:%f y:%f z:%f", index, self.vertexAndTextureData[index + 0], self.vertexAndTextureData[index + 1], self.vertexAndTextureData[index + 2]);
            }
        }
        
        GLint numberOfQuadrangle = slices * stacks; // 四边形数
        self.vertexIndexByteNumber = numberOfQuadrangle * 2 * 3 * sizeof(GLint); // 每个四边开有两个三角形，一个三角形三个顶点
        self.vertexIndexData = malloc(self.vertexIndexByteNumber);
        for (int i = 0; i < slices; i++) {
            for (int j = 0; j < stacks; j++) {
                GLint index = (i * stacks + j) * 6;
                self.vertexIndexData[index + 0] = i * (stacks + 1) + j;
                self.vertexIndexData[index + 1] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 2] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 3] = i * (stacks + 1) + j + 1;
                self.vertexIndexData[index + 4] = (i + 1) * (stacks + 1) + j;
                self.vertexIndexData[index + 5] = (i + 1) * (stacks + 1) + j + 1;
                
                //NSLog(@"vertexIndex: %d %d %d %d %d %d", self.vertexIndexData[i * j + 0], self.vertexIndexData[i * j + 1], self.vertexIndexData[i * j + 2], self.vertexIndexData[i * j + 3], self.vertexIndexData[i * j + 4], self.vertexIndexData[i * j + 5]);
            }
        }
    }
    return self;
}

@end
