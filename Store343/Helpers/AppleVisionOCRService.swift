// AppleVisionOCRService.swift
// Apple Vision Framework based OCR for Hiánycikk feature

import UIKit
import Vision
import VisionKit

class AppleVisionOCRService {
    static let shared = AppleVisionOCRService()

    private init() {}

    // MARK: - OCR Processing
    func recognizeText(from image: UIImage) async throws -> HianycikkOCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                // Extract all recognized text with position and confidence info
                var textItems: [(text: String, position: CGRect, confidence: Float)] = []
                for observation in observations {
                    // Try top 3 candidates and pick the best one
                    let candidates = observation.topCandidates(3)
                    if let bestCandidate = candidates.first {
                        textItems.append((
                            text: bestCandidate.string,
                            position: observation.boundingBox,
                            confidence: bestCandidate.confidence
                        ))
                    }
                }

                // Parse the recognized text with position data
                let result = self.parseHianycikkText(from: textItems)
                continuation.resume(returning: result)
            }

            // Configure request for best accuracy
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["hu-HU", "en-US"]
            request.usesLanguageCorrection = true

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Text Parsing
    private func parseHianycikkText(from textItems: [(text: String, position: CGRect, confidence: Float)]) -> HianycikkOCRResult {
        var cikkszam: String?
        var cikkMegnev: String?

        let allLines = textItems.map { $0.text }

        // Pattern for cikkszám (usually 6-8 digits)
        let cikkszamPattern = #"(\d{6,8})"#
        let cikkszamRegex = try? NSRegularExpression(pattern: cikkszamPattern)

        // First pass: Find cikkszám
        for item in textItems {
            let trimmedLine = item.text.trimmingCharacters(in: .whitespaces)

            if cikkszam == nil {
                let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
                if let match = cikkszamRegex?.firstMatch(in: trimmedLine, range: range) {
                    if let matchRange = Range(match.range, in: trimmedLine) {
                        cikkszam = String(trimmedLine[matchRange])
                        break
                    }
                }
            }
        }

        // Second pass: Find product name using position and confidence
        // Product names are typically:
        // 1. In the middle/center of the image (vertically)
        // 2. Bold text (higher confidence, larger bounding box)
        // 3. Mostly letters with few numbers

        var productNameCandidates: [(text: String, score: Float)] = []

        for item in textItems {
            let trimmedText = item.text.trimmingCharacters(in: .whitespaces)

            // Skip empty or very short text
            guard trimmedText.count >= 3 else { continue }

            // Skip if it's the cikkszám we already found
            if let foundCikkszam = cikkszam, trimmedText.contains(foundCikkszam) {
                continue
            }

            // Check if line is mostly letters (product name characteristic)
            let letterCount = trimmedText.filter { $0.isLetter || $0.isWhitespace || $0 == "," || $0 == "." || $0 == "-" }.count
            let digitCount = trimmedText.filter { $0.isNumber }.count

            // Must be mostly text
            guard letterCount > digitCount && Double(letterCount) / Double(trimmedText.count) > 0.6 else {
                continue
            }

            // Calculate score based on multiple factors
            var score: Float = 0.0

            // Factor 1: Position - prefer middle of image (y coordinate around 0.3-0.7)
            let verticalCenter = item.position.midY
            if verticalCenter > 0.25 && verticalCenter < 0.75 {
                score += 30.0
                // Bonus for being very centered
                if verticalCenter > 0.35 && verticalCenter < 0.65 {
                    score += 20.0
                }
            }

            // Factor 2: Confidence (bold text typically has higher confidence)
            score += item.confidence * 20.0

            // Factor 3: Size (bold text has larger bounding box height)
            let boxHeight = item.position.height
            if boxHeight > 0.03 { // Relatively large text
                score += 20.0
            }

            // Factor 4: Text length (product names are usually 10-50 chars)
            if trimmedText.count >= 10 && trimmedText.count <= 60 {
                score += 10.0
            }

            // Factor 5: Multiple words (product names usually have 2+ words)
            let wordCount = trimmedText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            if wordCount >= 2 {
                score += 15.0
            }

            productNameCandidates.append((text: trimmedText, score: score))
        }

        // Sort by score and pick the best candidate
        productNameCandidates.sort { $0.score > $1.score }

        if let bestCandidate = productNameCandidates.first, bestCandidate.score > 30.0 {
            cikkMegnev = bestCandidate.text
        }

        // Fallback: If still no product name, try the old sequential method
        if cikkMegnev == nil {
            for item in textItems {
                let trimmedLine = item.text.trimmingCharacters(in: .whitespaces)

                if trimmedLine.count > 5 {
                    let letterCount = trimmedLine.filter { $0.isLetter || $0.isWhitespace }.count
                    if Double(letterCount) / Double(trimmedLine.count) > 0.7 {
                        cikkMegnev = trimmedLine
                        break
                    }
                }
            }
        }

        return HianycikkOCRResult(
            cikkszam: cikkszam,
            cikkMegnev: cikkMegnev,
            allRecognizedText: allLines
        )
    }
}

// MARK: - Models
struct HianycikkOCRResult {
    let cikkszam: String?
    let cikkMegnev: String?
    let allRecognizedText: [String]

    var isValid: Bool {
        return cikkszam != nil || cikkMegnev != nil
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Érvénytelen kép formátum"
        case .noTextFound:
            return "Nem található szöveg a képen"
        case .parsingFailed:
            return "Nem sikerült feldolgozni a szöveget"
        }
    }
}
