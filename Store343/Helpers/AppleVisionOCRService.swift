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

                // Extract all recognized text with multiple candidates for better accuracy
                var recognizedStrings: [String] = []
                for observation in observations {
                    // Try top 3 candidates and pick the best one
                    let candidates = observation.topCandidates(3)
                    if let bestCandidate = candidates.first {
                        recognizedStrings.append(bestCandidate.string)
                    }
                }

                // Parse the recognized text
                let result = self.parseHianycikkText(from: recognizedStrings)
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
    private func parseHianycikkText(from lines: [String]) -> HianycikkOCRResult {
        var cikkszam: String?
        var cikkMegnev: String?
        var cikkszamIndex: Int?

        // Pattern for cikkszám (usually 6-8 digits)
        let cikkszamPattern = #"(\d{6,8})"#
        let cikkszamRegex = try? NSRegularExpression(pattern: cikkszamPattern)

        // First pass: Find cikkszám
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if cikkszam == nil {
                let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
                if let match = cikkszamRegex?.firstMatch(in: trimmedLine, range: range) {
                    if let matchRange = Range(match.range, in: trimmedLine) {
                        cikkszam = String(trimmedLine[matchRange])
                        cikkszamIndex = index
                        break
                    }
                }
            }
        }

        // Second pass: Find product name (improved logic)
        if let foundIndex = cikkszamIndex {
            // Look for product name in the next 5 lines after cikkszám
            var productNameParts: [String] = []

            for i in (foundIndex + 1)..<min(foundIndex + 6, lines.count) {
                let candidateLine = lines[i].trimmingCharacters(in: .whitespaces)

                // Skip empty lines
                if candidateLine.isEmpty { continue }

                // Skip lines with only numbers or very short lines
                if candidateLine.count < 3 { continue }

                // Check if line is mostly letters (product name characteristic)
                let letterCount = candidateLine.filter { $0.isLetter || $0.isWhitespace || $0 == "," || $0 == "." }.count
                let digitCount = candidateLine.filter { $0.isNumber }.count

                // If line is mostly text and has few numbers, it's likely part of product name
                if letterCount > digitCount && letterCount > candidateLine.count / 2 {
                    productNameParts.append(candidateLine)
                } else if !productNameParts.isEmpty {
                    // Stop if we've collected parts and hit a non-name line
                    break
                }

                // Stop after collecting reasonable amount of text
                if productNameParts.joined(separator: " ").count > 50 {
                    break
                }
            }

            // Combine parts into full product name
            if !productNameParts.isEmpty {
                cikkMegnev = productNameParts.joined(separator: " ")
            }
        }

        // Fallback: If no cikkszám found, still try to find a product name
        if cikkMegnev == nil {
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                if trimmedLine.count > 5 {
                    let letterCount = trimmedLine.filter { $0.isLetter || $0.isWhitespace }.count
                    if Double(letterCount) / Double(trimmedLine.count) > 0.6 {
                        cikkMegnev = trimmedLine
                        break
                    }
                }
            }
        }

        return HianycikkOCRResult(
            cikkszam: cikkszam,
            cikkMegnev: cikkMegnev,
            allRecognizedText: lines
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
