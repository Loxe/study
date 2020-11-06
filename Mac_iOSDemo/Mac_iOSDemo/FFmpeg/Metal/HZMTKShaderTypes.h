//
//  HZMTKShaderTypes.h
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/29.
//  Copyright © 2020 JinTao. All rights reserved.
//

#ifndef HZMTKShaderTypes_h
#define HZMTKShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float4 position;
    vector_float2 textureCoordinate;
} HZMTKVertex;

typedef struct {
    matrix_float3x3 matrix;
    vector_float3 offset;
} HZMTKConvertMatrix;


typedef enum HZMTKVertexInputIndex {
    HZMTKVertexInputIndexVertices = 0,
    HZMTKVertexInputIndexVertexMatrix = 1,
} HZMTKVertexInputIndex;

typedef enum HZMTKFragmentBufferIndex {
    HZMTKFragmentInputIndexMatrix = 0,
} HZMTKFragmentBufferIndex;

typedef enum HZMTKFragmentTextureIndex {
    HZMTKFragmentTextureIndexTextureY  = 0,
    HZMTKFragmentTextureIndexTextureU = 1,
    HZMTKFragmentTextureIndexTextureUV = HZMTKFragmentTextureIndexTextureU,
    HZMTKFragmentTextureIndexTextureV = 2,
    HZMTKFragmentTextureIndexTextureRGB = 3,
    HZMTKFragmentTextureIndexTextureCircledAndScaled = 4,
} HZMTKFragmentTextureIndex;

typedef struct {
    bool shouldDrawAsCircle;
    float zoomRatio;
} HZMTKCircleAndScaleData;

typedef enum HZMTKKenelBufferIndex {
    HZMTKKenelBufferIndexCircleAndScaleData = 0,
} HZMTKKenelBufferIndex;

#endif /* HZMTKShaderTypes_h */
