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

                // Extract all recognized text
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
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

        // Pattern for cikkszám (usually 6-8 digits)
        let cikkszamPattern = #"(\d{6,8})"#
        let cikkszamRegex = try? NSRegularExpression(pattern: cikkszamPattern)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Try to find cikkszám
            if cikkszam == nil {
                let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
                if let match = cikkszamRegex?.firstMatch(in: trimmedLine, range: range) {
                    if let matchRange = Range(match.range, in: trimmedLine) {
                        cikkszam = String(trimmedLine[matchRange])
                    }
                }
            }

            // If line contains mostly letters and is longer than 3 chars, consider it as product name
            if cikkMegnev == nil && trimmedLine.count > 3 {
                let letterCount = trimmedLine.filter { $0.isLetter || $0.isWhitespace }.count
                if Double(letterCount) / Double(trimmedLine.count) > 0.5 {
                    // Skip if it looks like a cikkszám line
                    if !(trimmedLine.contains(where: { $0.isNumber }) && trimmedLine.count < 15) {
                        cikkMegnev = trimmedLine
                    }
                }
            }
        }

        // If we found a cikkszám, look for the product name on nearby lines
        if let foundCikkszam = cikkszam, cikkMegnev == nil {
            // Look for product name after cikkszám
            if let cikkszamIndex = lines.firstIndex(where: { $0.contains(foundCikkszam) }) {
                // Check next few lines
                for i in (cikkszamIndex + 1)..<min(cikkszamIndex + 4, lines.count) {
                    let candidateLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if candidateLine.count > 3 && !candidateLine.contains(where: { $0.isNumber }) {
                        cikkMegnev = candidateLine
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
