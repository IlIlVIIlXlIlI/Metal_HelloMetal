//
//  MetalView.swift
//  HelloMetal
//
//  Created by Shogo Nobuhara on 2021/02/13.
//

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    // MTKViewを表示する
    typealias UIViewType = MTKView
    
    @Binding var isRunningCapture: Bool

    // MTKViewを作る
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = context.coordinator
        view.clearColor = MTLClearColor(
            red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        if let device = view.device {
            context.coordinator.setup(device: device, view: view)
        }

        return view
    }
    
    // ビューの更新処理
    func updateUIView(_ uiView: MTKView, context: Context) {
        if self.isRunningCapture {
            if let device = uiView.device {
                context.coordinator.startFrameCapture(device: device)
            }
        }
        else {
            context.coordinator.stopFrameCapture()
        }
    }
    
    // コーディネーターを作る
    func makeCoordinator() -> Renderer {
        return Renderer(self)
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        MetalView(isRunningCapture: .constant(false))
    }
}
