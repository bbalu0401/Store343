// NfOCRService.swift
// OCR parsing for NF (Nonfood) visszaküldés documents

import Vision
import UIKit

struct NfOCRResult {
    var bizonylatSzam: String
    var termekek: [NfTermekData]
}

struct NfTermekData {
    var cikkszam: String
    var cikkMegnev: String
    var elviKeszlet: Int16
    var sorrend: Int16
}

class NfOCRService {

    // MARK: - Main OCR Function
    static func recognizeText(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            let fullText = recognizedStrings.joined(separator: "\n")
            completion(fullText.isEmpty ? nil : fullText)
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["hu-HU", "en-US"]
        request.usesLanguageCorrection = true

        do {
            try requestHandler.perform([request])
        } catch {
            completion(nil)
        }
    }

    // MARK: - Parse NF Document
    static func parseNfDocument(from text: String, startingSorrend: Int16 = 0) -> [NfOCRResult] {
        var results: [String: [NfTermekData]] = [:] // bizonylatSzam -> termékek
        var currentSorrend = startingSorrend

        let lines = text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }

        for line in lines {
            // Skip empty lines
            if line.isEmpty { continue }

            // Skip section headers (Parkside kw45, PLU KW45, etc.)
            if line.lowercased().contains("parkside") ||
               line.lowercased().contains("plu kw") ||
               line.lowercased().contains("cikkszám") ||
               line.lowercased().contains("bizonylat") {
                continue
            }

            // Try to parse product line
            if let productData = parseProductLine(line, sorrend: currentSorrend) {
                // Group by bizonylat number
                if results[productData.bizonylatSzam] == nil {
                    results[productData.bizonylatSzam] = []
                }
                results[productData.bizonylatSzam]?.append(productData.termek)
                currentSorrend += 1
            }
        }

        // Convert dictionary to array of NfOCRResult
        return results.map { (bizonylatSzam, termekek) in
            NfOCRResult(bizonylatSzam: bizonylatSzam, termekek: termekek)
        }.sorted { $0.bizonylatSzam < $1.bizonylatSzam }
    }

    // MARK: - Parse Single Product Line
    private static func parseProductLine(_ line: String, sorrend: Int16) -> (bizonylatSzam: String, termek: NfTermekData)? {
        // Expected format: "476486   | LIVARNO...   | WT-41/2-25 | 43634 | 1"
        // Or with spaces: "476486 LIVARNO... WT-41/2-25 43634 1"

        // Extract cikkszám (6 digits at start)
        guard let cikkszamMatch = line.range(of: "^\\d{6}", options: .regularExpression) else {
            return nil
        }
        let cikkszam = String(line[cikkszamMatch])

        // Extract bizonylat (5 digits)
        let bizonylatPattern = "\\b\\d{5}\\b"
        guard let bizonylatMatch = line.range(of: bizonylatPattern, options: .regularExpression) else {
            return nil
        }
        let bizonylatSzam = String(line[bizonylatMatch])

        // Extract quantity (last number in line, 1-3 digits)
        let quantityPattern = "\\d{1,3}\\s*$"
        guard let quantityMatch = line.range(of: quantityPattern, options: .regularExpression) else {
            return nil
        }
        let quantityString = String(line[quantityMatch]).trimmingCharacters(in: .whitespaces)
        let elviKeszlet = Int16(quantityString) ?? 0

        // Extract product name (between cikkszám and WT code)
        // Find WT code pattern: WT-XX/X-XX
        let wtPattern = "WT-\\d{1,2}/\\d{1,2}-\\d{2}"
        var productName = ""

        if let wtMatch = line.range(of: wtPattern, options: .regularExpression) {
            // Product name is between cikkszám and WT code
            let startIndex = line.index(cikkszamMatch.upperBound, offsetBy: 0)
            let endIndex = wtMatch.lowerBound
            productName = String(line[startIndex..<endIndex])
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "|", with: "")
                .trimmingCharacters(in: .whitespaces)
        } else {
            // Fallback: take text between cikkszám and bizonylat
            let startIndex = line.index(cikkszamMatch.upperBound, offsetBy: 0)
            let endIndex = bizonylatMatch.lowerBound
            productName = String(line[startIndex..<endIndex])
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "|", with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        // Remove WT code from product name if it slipped in
        if let wtRange = productName.range(of: wtPattern, options: .regularExpression) {
            productName = String(productName[..<wtRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
        }

        // Create product data
        let termek = NfTermekData(
            cikkszam: cikkszam,
            cikkMegnev: productName,
            elviKeszlet: elviKeszlet,
            sorrend: sorrend
        )

        return (bizonylatSzam: bizonylatSzam, termek: termek)
    }

    // MARK: - Merge Multiple Pages
    static func mergeOCRResults(_ results: [[NfOCRResult]], preserveOrder: Bool = true) -> [NfOCRResult] {
        var merged: [String: [NfTermekData]] = [:]

        // Flatten all results
        let allResults = results.flatMap { $0 }

        // Group by bizonylat and merge products
        for result in allResults {
            if merged[result.bizonylatSzam] == nil {
                merged[result.bizonylatSzam] = []
            }
            merged[result.bizonylatSzam]?.append(contentsOf: result.termekek)
        }

        // Convert back to NfOCRResult array
        return merged.map { (bizonylatSzam, termekek) in
            // If preserveOrder is true, keep original sorrend values
            // Otherwise, renumber sequentially
            let sortedTermekek = preserveOrder
                ? termekek.sorted { $0.sorrend < $1.sorrend }
                : termekek.enumerated().map { (index, termek) in
                    var updated = termek
                    updated.sorrend = Int16(index)
                    return updated
                }

            return NfOCRResult(bizonylatSzam: bizonylatSzam, termekek: sortedTermekek)
        }.sorted { $0.bizonylatSzam < $1.bizonylatSzam }
    }
}
