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
        // Strategy: Product names are usually the LARGEST/BOLDEST text that is NOT a brand name
        // They can appear anywhere on the label

        var productNameCandidates: [(text: String, score: Double, position: CGRect)] = []

        for item in textItems {
            let trimmedText = item.text.trimmingCharacters(in: .whitespaces)

            // Skip empty or very short text (but allow 2-letter words like brand names)
            guard trimmedText.count >= 2 else { continue }

            // Skip if it's the cikkszám we already found
            if let foundCikkszam = cikkszam, trimmedText.contains(foundCikkszam) {
                continue
            }

            // Skip common brand names and generic words (case-insensitive)
            let lowercaseText = trimmedText.lowercased()
            let brandNames = [
                "kama", "pilos", "mooore", "pick", "dulano", "bio", "organic", "lidl",
                "combino", "lovilio", "vitasia", "freshona", "mcennedy", "alesto",
                "freeway", "cien", "w5", "pikok", "solevita", "floralys", "eridanous",
                "kania"
            ]
            if brandNames.contains(lowercaseText) {
                continue
            }

            // Skip descriptions/ingredients (Hungarian specific patterns)
            let descriptionPatterns = ["val", "vel", "ból", "ből", "ban", "ben", "ról", "ről", "és", "vagy"]
            var isDescription = false
            for pattern in descriptionPatterns {
                if lowercaseText.contains(pattern) && trimmedText.count > 15 {
                    isDescription = true
                    break
                }
            }
            if isDescription { continue }

            // Skip weight/measurement indicators and prices
            if trimmedText.contains("kg") || trimmedText.contains("g") ||
               trimmedText.contains("ml") || trimmedText.contains("l") ||
               trimmedText.contains("db") || trimmedText.contains("Ft") ||
               trimmedText.contains("=") {
                continue
            }

            // Check if mostly letters (product names are text, not numbers)
            // Allow % and other special chars that might be in product names
            let letterCount = trimmedText.filter { $0.isLetter || $0.isWhitespace || $0 == "," || $0 == "." || $0 == "-" || $0 == "%" }.count
            let digitCount = trimmedText.filter { $0.isNumber }.count

            // Skip if it looks like a price (mostly numbers)
            if digitCount > letterCount {
                continue
            }

            // Must be mostly text, but allow some numbers (like "Tejföl 12%")
            guard letterCount >= digitCount && Double(letterCount) / Double(trimmedText.count) >= 0.5 else {
                continue
            }

            // Calculate score based on: size, confidence, and preferred position
            // Larger text = higher score, left position = bonus points
            let sizeScore = Double(item.position.height) * 100.0  // Height is primary factor
            let confidenceScore = Double(item.confidence) * 10.0  // Confidence matters
            let positionBonus = item.position.minX < 0.6 ? 5.0 : 0.0  // Slight bonus for left/center, but not required

            let totalScore = sizeScore + confidenceScore + positionBonus

            productNameCandidates.append((text: trimmedText, score: totalScore, position: item.position))
        }

        // Sort by score (highest first)
        productNameCandidates.sort { $0.score > $1.score }

        // Take the best candidate (highest scoring text)
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
