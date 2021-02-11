//
//  LandmarksVisualization.swift
//  facial-landmarks-swift
//
//  Created by Johannes Silberbauer on 10.02.21.
//

import Vision
import CoreImage

/**
 * Creates a path representing the landmark region into the graphics context.
 *
 * - note: Assumes that the context is of the same size as the image.
 */
func createPath(for region: VNFaceLandmarkRegion2D, in context: CGContext) {
    let imageSize = CGSize(width: context.width, height: context.height)
    let imagePoints = region.pointsInImage(imageSize: imageSize)
    for (i, imagePoint) in imagePoints.enumerated() { // last point is 0,0
        if i == 0 {
            context.move(to: imagePoint)
        } else {
            context.addLine(to: imagePoint)
        }
    }
}

/**
 * Draw a basic visualization of the face observation into the speicifed image.
 */
func draw(face: VNFaceObservation, into ciImage: CIImage) -> CGImage? {
    // create the bitmap
    let ciContext = CIContext.init(options: nil)
    guard let image = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
        return nil
    }
    
    // setup the drawing context
    guard let colorSpace = image.colorSpace else {
        return nil
    }
    guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.bytesPerRow, space: colorSpace, bitmapInfo: image.bitmapInfo.rawValue) else {
        return nil
    }
    
    let color: CGColor = .white
    let width: CGFloat = 2.0
    
    // draw the image
    let imageSize = CGSize(width: image.width, height: image.height)
    context.draw(image, in: CGRect(origin: .zero, size: imageSize))
    
    let landmarksToDraw = [face.landmarks?.faceContour,
                           face.landmarks?.outerLips,
                           face.landmarks?.innerLips,
                           face.landmarks?.leftEye,
                           face.landmarks?.rightEye,
                           face.landmarks?.leftPupil,
                           face.landmarks?.rightPupil,
                           face.landmarks?.leftEyebrow,
                           face.landmarks?.rightEyebrow]
    
    context.setStrokeColor(color)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    // draw landmarks
    for (i, landmark) in landmarksToDraw.enumerated() {
        if let landmark = landmark {
            createPath(for: landmark, in: context)
            if i != 0 {
                context.closePath()
            }
            context.drawPath(using: .stroke)
        }
    }
    
    // get the final image
    return context.makeImage()
}
