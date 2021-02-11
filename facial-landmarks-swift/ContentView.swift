//
//  ContentView.swift
//  facial-landmarks-swift
//
//  Created by Johannes Silberbauer on 11.02.21.
//

import SwiftUI

extension Image {
    init?(_ cgimage: CGImage?) {
        guard let cgimage = cgimage else {
            return nil
        }
        self = Image(cgimage, scale: 1.0, label: Text(""))
    }
}

extension Text {
    init?<S: StringProtocol>(_ optionalString: S?) {
        guard let content = optionalString else {
            return nil
        }
        self = Text(content)
    }
}

struct ContentView: View {
    
    @State var currentFrame: CGImage?
    @State var error: Error?
    
    var message: String? {
        get {
            guard currentFrame == nil else { return nil }
            return error==nil ? "Loading..." : error?.localizedDescription
        }
    }
    
    let capture = CameraCaptureManager(preset: .qHD960x540)
    let processingPipeline = ImageProcessingPipeline()
    
    var body: some View {
        ZStack {
            Color.init(.underPageBackgroundColor)
            Text(message).font(.headline).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            Image(currentFrame)?.resizable().aspectRatio(contentMode: .fit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        .onAppear(perform: startCapture)
    }
    
    func startCapture() {
        processingPipeline.onOutput = { result in
            DispatchQueue.main.async {
                currentFrame = result.preview
            }
        }
        capture.setup { error in
            capture.delegate = processingPipeline
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                }
            } else {
                capture.start()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
