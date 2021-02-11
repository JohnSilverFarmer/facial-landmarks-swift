//
//  ImageCapture.swift
//  facial-landmarks-swift
//
//  Created by Johannes Silberbauer on 09.02.21.
//

import AVFoundation


enum CameraCaptureManagerError: Error {
    
    /*
     * The capture manager was unable to open the video stream.
     */
    case failedToOpen(_ underlyingError: AVError?)
    
    /*
     * The manager was unable to obtain proper user authorization for accessing the camera.
     */
    case authorizationFailure
}

/*
 * Wrapper class around AVFoundation that manages live camera video streams.
 */
final class CameraCaptureManager {
    
    private var session: CaptureSession?
    
    /*
     * The delegate to the
     */
    var delegate: AVCaptureVideoDataOutputSampleBufferDelegate? {
        set {
            session?.output.setSampleBufferDelegate(newValue, queue: .global(qos: .userInitiated))
        }
        get {
            return session?.output.sampleBufferDelegate
        }
    }
    
    /*
     * Current authorization status for video camera access.
     */
    var accessStatus: AVAuthorizationStatus {
        get {
            return AVCaptureDevice.authorizationStatus(for: .video)
        }
    }
    
    let sessionPreset: AVCaptureSession.Preset
    
    init(preset: AVCaptureSession.Preset) {
        sessionPreset = preset
    }
    
    /*
     * Setup the capture session after ensuring the application has been authorized.
     */
    func setup(onCompletion: @escaping (Error?) -> Void) {
        if accessStatus == .authorized {
            setupAuthorized(onCompletion: onCompletion)
        } else if accessStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupAuthorized(onCompletion: onCompletion)
                } else {
                    onCompletion(CameraCaptureManagerError.authorizationFailure)
                }
            }
        } else {
            onCompletion(CameraCaptureManagerError.authorizationFailure)
        }
    }
    
    /*
     * Setup assuming a valid authorization status.
     */
    private func setupAuthorized(onCompletion: (Error?) -> Void) {
        do {
            session = try CaptureSession()
            session?.session.sessionPreset = sessionPreset
        } catch let err {
            onCompletion(err)
        }
        onCompletion(nil)
    }
    
    /**
     * Starts capturing camera data.
     */
    func start() {
        guard let session = session else {
            return
        }
        guard !session.session.isRunning else {
            return
        }
        session.session.startRunning()
    }
    
    /**
     * Stops capturing camera data.
     */
    func stop() {
        guard let session = session else {
            return
        }
        guard session.session.isRunning else {
            return
        }
        session.session.stopRunning()
    }
    
}

/*
 * Wrapper around the actual AVCaptureSession.
 */
private class CaptureSession {
    
    /*
     * AVFoundation APIs.
     */
    let session: AVCaptureSession
    let device: AVCaptureDevice
    let deviceInput: AVCaptureDeviceInput
    let output: AVCaptureVideoDataOutput
    
    init() throws {
        session = AVCaptureSession()
        session.beginConfiguration()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraCaptureManagerError.failedToOpen(nil)
        }
        device = captureDevice
        
        deviceInput = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(deviceInput) else {
            throw CameraCaptureManagerError.failedToOpen(nil)
        }
        session.addInput(deviceInput)
        
        output = AVCaptureVideoDataOutput()
        guard session.canAddOutput(output) else {
            throw CameraCaptureManagerError.failedToOpen(nil)
        }
        session.addOutput(output)
        
        session.commitConfiguration()
    }
    
}
