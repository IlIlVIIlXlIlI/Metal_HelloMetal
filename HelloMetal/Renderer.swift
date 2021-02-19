//
//  Renderer.swift
//  HelloMetal
//
//  Created by Shogo Nobuhara on 2021/02/13.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    let parent: MetalView
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var viewportSize: CGSize = CGSize()
    var vertices: [ShaderVertex] = [ShaderVertex]()
    
    // イニシャライザを追加する
    init(_ parent: MetalView) {
        self.parent = parent
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        self.viewportSize = size
        let wh = Float(min(size.width,size.height))
        
        // 四角形の頂点の座標を計算する
        self.vertices = [
            // 三角形( 1 )
            ShaderVertex(position: vector_float2(-wh / 2.0, wh / 2.0),
                         color: vector_float4(1.0,1.0,1.0,1.0)),
            ShaderVertex(position: vector_float2(-wh / 2.0, -wh / 2.0),
                         color: vector_float4(1.0,1.0,1.0,1.0)),
            ShaderVertex(position: vector_float2(wh / 2.0, -wh / 2.0),
                         color: vector_float4(1.0,1.0,1.0,1.0)),
            
            // 三角形( 2 )
            ShaderVertex(position: vector_float2(wh / 2.0, -wh / 2.0),
                         color: vector_float4(1.0,1.0,1.0,1.0)),
            ShaderVertex(position: vector_float2(-wh / 2.0, wh / 2.0),
                         color: vector_float4(1.0,1.0,1.0,1.0)),
            ShaderVertex(position: vector_float2(wh / 2.0, wh / 2.0),
                         color: vector_float4(1.0,1.0,1.0,1.0)),
            
        ]
        
    }
    
    func draw(in view: MTKView)
    {
        guard let cmdBuffer = self.commandQueue?.makeCommandBuffer()else {
            return
        }
        
        guard let renderPassDesc = view.currentRenderPassDescriptor else {
            return
        }
        
        guard let encorder = cmdBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else {
            return
        }
        
        encorder.setViewport(MTLViewport(originX: 0, originY: 0,
                                         width: Double(self.viewportSize.width),
                                         height: Double(self.viewportSize.height),
                                         znear: 0.0,zfar: 1.0))
        
        if let pipeline = self.pipelineState {
            // パイプライン状態オブジェクトを設定する
            encorder.setRenderPipelineState(pipeline)
            
            // Vertex関数に渡す引数を設定する
            encorder.setVertexBytes(self.vertices,
                                    length: MemoryLayout<ShaderVertex>.size * self.vertices.count,
                                    index: kShaderVertexInputIndexVertices)
            
            var vpSize = vector_float2(Float(self.viewportSize.width / 2.0),
                                       Float(self.viewportSize.height / 2.0))
            encorder.setVertexBytes(&vpSize,
                                    length: MemoryLayout<vector_float2>.size,
                                    index: kShaderVertexInputIndexViewportSize)
            
            // 三角形を描画する
            encorder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 6)
            
        }
        
        encorder.endEncoding()
        
        if let drawable = view.currentDrawable {
            cmdBuffer.present(drawable)
        }
        
        cmdBuffer.commit()
    }
    
    func setup(device: MTLDevice, view:MTKView) {
        self.commandQueue = device.makeCommandQueue()
        setupPipelineState(device: device, view: view)
    }
    
    func setupPipelineState(device: MTLDevice, view: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            return
        }
        
        guard let vertexFunc = library.makeFunction(name: "vertexShader"),
              let fragmentFunc = library.makeFunction(name: "fragmentShader") else {
            return
        }
        
        let pipelineStateDesc = MTLRenderPipelineDescriptor()
        pipelineStateDesc.vertexFunction = vertexFunc
        pipelineStateDesc.fragmentFunction = fragmentFunc
        pipelineStateDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDesc)
        } catch let error {
            print(error)
        }
        
    }
    
    
    func makeTexture(device: MTLDevice?)->MTLTexture? {
          
        // アセットカタログから画像を読み込む
        guard let image = UIImage(named: "TextureImage") else {
            return nil
        }
        
        // CGImageを取得する
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        // データプロバイダ経由でピクセルデータを取得する
        guard let pixelData = cgImage.dataProvider?.data else {
            return nil
        }
        
        guard let srcBits = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        
        // テクスチャを作成する
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                            width: cgImage.width,
                                                            height: cgImage.height,
                                                            mipmapped: false)
        let texture = device?.makeTexture(descriptor: desc)
        
        // RGBA形式のピクセルデータを作る
        let bytesPerRow = cgImage.width * 4
        var dstBits = Data(count: bytesPerRow * cgImage.height)
        let alphaInfo = cgImage.alphaInfo
        
        let rPos = (alphaInfo == .first || alphaInfo == .noneSkipFirst) ? 1 : 0
        let gPos = rPos + 1
        let bPos = gPos + 1
        let aPos = (alphaInfo == .last || alphaInfo == .noneSkipLast) ? 3 : 0
        
        for y in 0 ..< cgImage.height {
            for x in 0 ..< cgImage.width {
                let srcOff = y * cgImage.bytesPerRow + x * cgImage.bitsPerPixel / 8
                let dstOff = y * bytesPerRow + x * 4
                
                dstBits[dstOff] = srcBits[srcOff + rPos]
                dstBits[dstOff + 1] = srcBits[srcOff + gPos]
                dstBits[dstOff + 2] = srcBits[srcOff + bPos]
                
                if alphaInfo != .none {
                    dstBits[dstOff + 3] = srcBits[srcOff + aPos]
                }
            }
        }
        
        // テクスチャのピクセルデータを置き換える
        dstBits.withUnsafeBytes { (bufPtr) in
            if let baseAddress = bufPtr.baseAddress {
                let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                       size: MTLSize(width: cgImage.width,
                                                     height: cgImage.height,
                                                     depth: 1))
                
                texture?.replace(region: region,
                                 mipmapLevel: 0,
                                 withBytes: baseAddress,
                                 bytesPerRow: bytesPerRow)
            }
        }
        
        
        return nil
    }
    
    
}
