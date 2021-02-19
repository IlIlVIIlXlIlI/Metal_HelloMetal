import SwiftUI

struct ContentView: View {
    @State var isRunningCapture: Bool = false
    
    var body: some View {
        VStack {
            MetalView(isRunningCapture: $isRunningCapture)
            Button(action: {
                self.isRunningCapture = !self.isRunningCapture
            }) {
                if self.isRunningCapture {
                    Text("Stop Capture")
                } else {
                    Text("Start Capture")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
