//
//  ShaderTypes.h
//  HelloMetal
//
//  Created by Shogo Nobuhara on 2021/02/14.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

enum {
    kShaderVertexInputIndexVertices     = 0,
    kShaderVertexInputIndexViewportSize = 1
};

enum {
    kFragmentInputIndexTexture = 0
};

typedef struct {
    vector_float2 position;
    vector_float4 color;
    vector_float2 textureCoordinate;
} ShaderVertex;

#endif /* ShaderTypes_h */
