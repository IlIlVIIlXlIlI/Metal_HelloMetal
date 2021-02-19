//
//  Shader.metal
//  HelloMetal
//
//  Created by Shogo Nobuhara on 2021/02/14.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

// Vertex関数が出力するデータの型定義
typedef struct {
    // 座標
    float4 position [[position]];
    
    // 色
    float4 color;

    // テクスチャ座標
    float2 textureCoordinate;

} RasterizerData;

vertex RasterizerData vertexShader(
   uint vertexID [[vertex_id]],
   constant ShaderVertex *vertices
        [[buffer(kShaderVertexInputIndexVertices)]],
   constant vector_float2 *viewportSize
        [[buffer(kShaderVertexInputIndexViewportSize)]])
{
    RasterizerData result = {};
    result.position = float4(0.0, 0.0, 0.0, 1.0);
    result.position.xy = vertices[vertexID].position / (*viewportSize);
    result.color = vertices[vertexID].color;
    result.textureCoordinate = vertices[vertexID].textureCoordinate;
    return result;
}

fragment float4 fragmentShader(
    RasterizerData in [[stage_in]],
    metal::texture2d<half> texture [[texture(kFragmentInputIndexTexture)]])
{
    constexpr metal::sampler textureSampler(metal::mag_filter::linear,
                                            metal::min_filter::linear);
    const half4 colorSample = texture.sample(textureSampler,
        in.textureCoordinate);
        
    return float4(colorSample);
}
