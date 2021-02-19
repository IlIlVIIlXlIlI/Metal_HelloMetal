#include <metal_stdlib>
#include <metal_matrix>
#include "ShaderTypes.h"

// Vertex関数が出力するデータの型定義
typedef struct {
    // 座標
    float4 position [[position]];
    
    // 色
    float4 color;
    
} RasterizerData;

vertex RasterizerData vertexShader(
   uint vertexID [[vertex_id]],
   constant ShaderVertex *vertices
    [[buffer(kShaderVertexInputIndexVertices)]],
   constant vector_float2 *viewportSize
    [[buffer(kShaderVertexInputIndexViewportSize)]],
   constant float &pastTime
    [[buffer(kShaderVertexInputIndexPastTime)]])
{
    // 回転角度を計算する。20秒で1回転とする
    int intVal = 0;
    float angle = 360.0 * metal::fmod(pastTime / 20.0, intVal);

    // ラジアンに変換する
    angle = angle / 360.0 * 2.0 * M_PI_F;
    
    // 回転行列を作る
    metal::float2x2 rotation =
        metal::float2x2(metal::cos(angle), metal::sin(angle),
                        -metal::sin(angle), metal::cos(angle));

    // 回転行列を適用する
    RasterizerData result = {};
    result.position = float4(0.0, 0.0, 0.0, 1.0);
    result.position.xy = vertices[vertexID].position * rotation / (*viewportSize);

    // RGB->YCCに変換する
    float4 rgb = vertices[vertexID].color;
    float y  = 0.3 * rgb.x + 0.59 * rgb.y + 0.11 * rgb.z;
    float c1 = 0.7 * rgb.x - 0.59 * rgb.y - 0.11 * rgb.z;
    float c2 = -0.3 * rgb.x - 0.59 * rgb.y + 0.89 * rgb.z;

    // 色差(c1とc2)から色相と彩度を計算する
    float hue = metal::atan2(c1, c2);
    float sat = metal::sqrt(metal::pow(c1, 2) + metal::pow(c2, 2));
    
    // 色相を回転させる
    hue += angle;
    
    // 色差を計算する
    c1 = sat * metal::sin(hue);
    c2 = sat * metal::cos(hue);
    
    // YCC->RGBに変換する
    float r = metal::max(0.0, metal::min(1.0, y + c1));
    float g = metal::max(0.0,
        metal::min(1.0, y - 0.3 / 0.59 * c1 - 0.11 / 0.59 * c2));
    float b = metal::max(0.0, metal::min(1.0, y + c2));
    result.color = float4(r, g, b, rgb.z);

    return result;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
