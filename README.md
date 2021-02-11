# facial-landmarks-swift
Demonstrate how to use Apple's Vision framework for processing a live video stream on macos.

The project is structured into:

- `CameraCaptureManager.swift` communicates with the AVFoundation to handle authorisation and camera access.
- `ImageProcessingPipeline.swift` receives frames from `CameraCaptureManager` and processes them. Also handles dropping frames when processing is slower than the cameras frame rate.
- `ContentView.swift`/`LandmarksVisualization.swift` is used to render a live camera preview using SwiftUI.
