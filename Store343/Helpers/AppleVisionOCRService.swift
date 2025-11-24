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

        // Second pass: Find product name
        // Strategy: Product names are ALWAYS on the LEFT side and are the LARGEST/BOLDEST text
        // They appear below brand names (like "pick") and are clearly distinguishable by size

        var productNameCandidates: [(text: String, height: CGFloat, leftPosition: CGFloat)] = []

        for item in textItems {
            let trimmedText = item.text.trimmingCharacters(in: .whitespaces)

            // Skip empty or very short text
            guard trimmedText.count >= 3 else { continue }

            // Skip if it's the cikkszám we already found
            if let foundCikkszam = cikkszam, trimmedText.contains(foundCikkszam) {
                continue
            }

            // Skip common brand names (case-insensitive)
            let lowercaseText = trimmedText.lowercased()
            let brandNames = ["pick", "bio", "organic", "lidl", "combino", "lovilio", "vitasia"]
            if brandNames.contains(lowercaseText) {
                continue
            }

            // Check if mostly letters (product names are text, not numbers)
            let letterCount = trimmedText.filter { $0.isLetter || $0.isWhitespace || $0 == "," || $0 == "." || $0 == "-" }.count
            let digitCount = trimmedText.filter { $0.isNumber }.count

            // Must be mostly text
            guard letterCount > digitCount && Double(letterCount) / Double(trimmedText.count) > 0.6 else {
                continue
            }

            // MUST be on the LEFT side (minX < 0.5)
            let leftPosition = item.position.minX
            guard leftPosition < 0.5 else { continue }

            // Add to candidates with height and position
            let height = item.position.height
            productNameCandidates.append((text: trimmedText, height: height, leftPosition: leftPosition))
        }

        // Find the text with the LARGEST height that is on the LEFT side
        // Sort by: 1) height (descending), 2) left position (ascending - prefer more left)
        productNameCandidates.sort { (a, b) in
            if abs(a.height - b.height) > 0.005 { // If height difference is significant
                return a.height > b.height  // Prefer larger/bolder text
            } else {
                return a.leftPosition < b.leftPosition  // If similar height, prefer more left
            }
        }

        // Take the best candidate (largest, leftmost text)
        if let bestCandidate = productNameCandidates.first {
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
