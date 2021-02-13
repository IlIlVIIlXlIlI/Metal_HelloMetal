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
    
    // イニシャライザを追加する
    init(_ parent: MetalView) {
        self.parent = parent
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.viewportSize = size
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
    
    
}
