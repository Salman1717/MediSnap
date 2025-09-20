//
//  OCRHelper.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

// OCRHelper.swift
import Foundation
import UIKit
import Vision
import CoreImage

enum OCRError: Error {
    case failedToCreateCGImage
    case recognitionFailed
}

struct OCRHelper {
    /// Recognize text from UIImage and return concatenated string
    static func recognizeText(from image: UIImage, recognitionLevel: VNRequestTextRecognitionLevel = .accurate) async throws -> String {
        // create CGImage reliably
        let cgImage: CGImage
        if let g = image.cgImage {
            cgImage = g
        } else if let ci = image.ciImage {
            let ctx = CIContext()
            guard let g = ctx.createCGImage(ci, from: ci.extent) else { throw OCRError.failedToCreateCGImage }
            cgImage = g
        } else {
            // try rendering the UIImage into a context
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
            guard let g = rendered.cgImage else { throw OCRError.failedToCreateCGImage }
            cgImage = g
        }

        return try await performRecognition(on: cgImage, recognitionLevel: recognitionLevel)
    }

    private static func performRecognition(on cgImage: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }

                // Sort observations by top y coordinate so reading order is mostly preserved
                let sorted = observations.sorted { lhs, rhs in
                    let l = lhs.boundingBox.origin.y
                    let r = rhs.boundingBox.origin.y
                    return l > r // Vision's coordinate origin is bottom-left; reverse for top-down order
                }

                var lines: [String] = []
                for obs in sorted {
                    if let candidate = obs.topCandidates(1).first {
                        lines.append(candidate.string)
                    }
                }

                let text = lines.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = recognitionLevel
            request.usesLanguageCorrection = true
            // Optionally set recognition languages:
            // request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
