//
//  ImageProcessingPipeline.swift
//  facial-landmarks-swift
//
//  Created by Johannes Silberbauer on 10.02.21.
//

import AVFoundation
import Vision

/**
 * Class that runs image processing pipeline of the app.
 */
final class ImageProcessingPipeline: NSObject {
    
    /**
     * Describes the output of the apps image processing pipeline
     */
    class Output {
        
        let preview: CGImage
        
        init(preview _preview: CGImage) {
            preview = _preview
        }
        
    }
    
    /**
     * Called everytime the pipeline has computed a new output sample.
     *
     * - Note: The closure might be called on a background thread.
     */
    var onOutput: ((Output) -> ())?
    
    private let frameBufferSize: Int
    private var frameBuffer: [CIImage] = []
    private let processingQueue: DispatchQueue = DispatchQueue(label: "com.image-processing-pipeline.worker")
    
    private var isProcessing: Bool = false
    
    private let landmarksRequest = VNDetectFaceLandmarksRequest()
    
    init(frameBufferSize _frameBufferSize: Int = 1) {
        frameBufferSize = _frameBufferSize
        landmarksRequest.constellation = .constellation76Points
    }
    
    /**
     * Add a new image to the pipeline for processing.
     *
     * Frames are kept in an internal buffer and processed in FIFO order. If the frame buffer is full the oldest frame is discarded.
     */
    func input(_ frame: CIImage) {
        processingQueue.async {
            self.frameBuffer.append(frame)
            if self.frameBuffer.count > self.frameBufferSize {
                self.frameBuffer.removeFirst()
            }
            self.startProcessIfNeeded()
        }
    }
    
    private func process(_ sampleBuffer: CMSampleBuffer) {
        // retrieve camera frame from buffer
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage = CIImage(cvPixelBuffer: buffer).oriented(.upMirrored)
        input(ciImage)
    }
    
    private func startProcessIfNeeded() {
        guard !frameBuffer.isEmpty && !isProcessing else {
            return
        }
        isProcessing = true
        processingQueue.async {
            self.process(self.frameBuffer.removeFirst())
        }
    }
    
    private func processNextIfNeeded() {
        guard !frameBuffer.isEmpty else {
            isProcessing = false
            return
        }
        processingQueue.async {
            self.process(self.frameBuffer.removeFirst())
        }
    }
    
    private func process(_ frame: CIImage) {
        defer {
            processNextIfNeeded()
        }
        
        let requestHandler = VNImageRequestHandler(ciImage: frame, options: [:])
        do {
            try requestHandler.perform([landmarksRequest])
            
            // try to get any detected face
            guard let faceObservations = landmarksRequest.results as? [VNFaceObservation] else {
                return
            }
            guard let faceObservation = faceObservations.first else {
                return
            }
            
            // render observations into a preview image
            guard let preview = draw(face: faceObservation, into: frame) else {
                return
            }
            let result = Output(preview: preview)
            
            onOutput?(result)
        } catch {
        }
    }
    
}

extension ImageProcessingPipeline: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // nothing
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        process(sampleBuffer)
    }
    
}
