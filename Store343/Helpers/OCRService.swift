// OCRService.swift
// Vision API OCR text recognition

import Vision
import UIKit

class OCRService {
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

    // Parse napi_info document structure
    static func parseNapiInfo(from text: String) -> (tema: String?, erintett: String?, hatarido: String?, tartalom: String?, termekLista: [[String: String]]?) {
        var tema: String?
        var erintett: String?
        var hatarido: String?
        var tartalom: String?
        var termekLista: [[String: String]]?

        let lines = text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }

        // Extract sections
        var currentSection: String?
        var contentLines: [String] = []
        var products: [[String: String]] = []

        for (index, line) in lines.enumerated() {
            let lowercaseLine = line.lowercased()

            // Detect sections
            if lowercaseLine.contains("téma") || lowercaseLine.contains("tema") {
                currentSection = "tema"
                if index + 1 < lines.count {
                    tema = lines[index + 1]
                }
            } else if lowercaseLine.contains("érintett") || lowercaseLine.contains("erintett") {
                currentSection = "erintett"
                if index + 1 < lines.count {
                    erintett = lines[index + 1]
                }
            } else if lowercaseLine.contains("határid") || lowercaseLine.contains("hatarido") {
                currentSection = "hatarido"
                if index + 1 < lines.count {
                    hatarido = lines[index + 1]
                }
            } else if lowercaseLine.contains("tartalom") {
                currentSection = "tartalom"
                contentLines = []
            } else if lowercaseLine.contains("termék") || lowercaseLine.contains("termek") {
                currentSection = "termekek"
            } else if currentSection == "tartalom" && !line.isEmpty {
                contentLines.append(line)
            } else if currentSection == "termekek" {
                // Try to parse product: "KÓD | Leírás"
                let parts = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    products.append([
                        "kod": String(parts[0]),
                        "leiras": String(parts[1])
                    ])
                }
                // Also try tab or multiple spaces
                else if line.contains("\t") || line.contains("  ") {
                    let components = line.split(whereSeparator: { $0 == "\t" || $0 == " " })
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    if components.count >= 2 {
                        products.append([
                            "kod": components[0],
                            "leiras": components.dropFirst().joined(separator: " ")
                        ])
                    }
                }
            }
        }

        if !contentLines.isEmpty {
            tartalom = contentLines.joined(separator: " ")
        }

        if !products.isEmpty {
            termekLista = products
        }

        return (tema, erintett, hatarido, tartalom, termekLista)
    }

    // MARK: - Parse Multiple Napi Info from Single Document
    struct NapiInfoBlock {
        var tema: String
        var erintett: String
        var hatarido: String?
        var tartalom: String
        var termekLista: [[String: String]]?
        var index: Int
    }

    static func parseNapiInfoMultiple(from text: String) -> [NapiInfoBlock] {
        var results: [NapiInfoBlock] = []
        let lines = text.split(separator: "\n").map { String($0) }

        // Find all "Téma:" occurrences (case-insensitive)
        var temaIndices: [Int] = []
        for (index, line) in lines.enumerated() {
            let lowercaseLine = line.lowercased().trimmingCharacters(in: .whitespaces)
            if lowercaseLine.contains("téma:") || lowercaseLine.contains("tema:") {
                temaIndices.append(index)
            }
        }

        // If no "Téma:" found, treat entire text as single info
        if temaIndices.isEmpty {
            let singleInfo = parseSingleInfoBlock(lines: lines, startIndex: 0, endIndex: lines.count, blockIndex: 0)
            if let info = singleInfo {
                results.append(info)
            }
            return results
        }

        // Process each info block
        for (blockIndex, temaIndex) in temaIndices.enumerated() {
            let startIndex = temaIndex
            let endIndex = (blockIndex + 1 < temaIndices.count) ? temaIndices[blockIndex + 1] : lines.count

            if let infoBlock = parseSingleInfoBlock(lines: lines, startIndex: startIndex, endIndex: endIndex, blockIndex: blockIndex) {
                results.append(infoBlock)
            }
        }

        return results
    }

    // MARK: - Parse Single Info Block
    private static func parseSingleInfoBlock(lines: [String], startIndex: Int, endIndex: Int, blockIndex: Int) -> NapiInfoBlock? {
        var tema: String = ""
        var erintett: String = ""
        var hatarido: String?
        var contentLines: [String] = []
        var products: [[String: String]] = []

        var temaLineIndex: Int? = nil
        var erintettLineIndex: Int? = nil
        var hatarIdoLineIndex: Int? = nil
        var isInTable = false
        var tableLines: [String] = []

        // FIRST PASS: Extract structured fields and their indices
        for i in startIndex..<min(endIndex, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            let lowercaseLine = line.lowercased()

            // Detect "Téma:"
            if lowercaseLine.contains("téma:") || lowercaseLine.contains("tema:") {
                temaLineIndex = i
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count > 1 {
                    tema = String(parts[1]).trimmingCharacters(in: .whitespaces)
                } else if i + 1 < lines.count {
                    tema = lines[i + 1].trimmingCharacters(in: .whitespaces)
                }
            }

            // Detect "Érintett:"
            if lowercaseLine.contains("érintett:") || lowercaseLine.contains("erintett:") {
                erintettLineIndex = i
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count > 1 {
                    erintett = String(parts[1]).trimmingCharacters(in: .whitespaces)
                } else if i + 1 < lines.count {
                    erintett = lines[i + 1].trimmingCharacters(in: .whitespaces)
                }
            }

            // Detect "Határidő:"
            if lowercaseLine.contains("határidő:") || lowercaseLine.contains("hatarido:") {
                hatarIdoLineIndex = i
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count > 1 {
                    hatarido = String(parts[1]).trimmingCharacters(in: .whitespaces)
                } else if i + 1 < lines.count {
                    hatarido = lines[i + 1].trimmingCharacters(in: .whitespaces)
                }
            }
        }

        // SECOND PASS: Extract content (everything else)
        for i in startIndex..<min(endIndex, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            let lowercaseLine = line.lowercased()

            // Skip header lines and their values
            if let tIdx = temaLineIndex, (i == tIdx || i == tIdx + 1) { continue }
            if let eIdx = erintettLineIndex, (i == eIdx || i == eIdx + 1) { continue }
            if let hIdx = hatarIdoLineIndex, (i == hIdx || i == hIdx + 1) { continue }

            // Skip checkbox lines
            if lowercaseLine.contains("☑") || lowercaseLine.contains("□") {
                continue
            }

            // Skip lines that are just field labels
            if lowercaseLine == "téma:" || lowercaseLine == "tema:" ||
               lowercaseLine == "érintett:" || lowercaseLine == "erintett:" ||
               lowercaseLine == "határidő:" || lowercaseLine == "hatarido:" ||
               lowercaseLine == "tartalom:" {
                continue
            }

            // Detect table (lines with | or consistent spacing with digits)
            if line.contains("|") || isTableRow(line: line) {
                if !isInTable {
                    isInTable = true
                    tableLines = []
                }
                tableLines.append(line)
                continue
            } else if isInTable {
                // End of table, add to content
                if !tableLines.isEmpty {
                    contentLines.append("\n" + tableLines.joined(separator: "\n") + "\n")
                    // Parse products from table
                    products.append(contentsOf: parseTableProducts(tableLines: tableLines))
                    tableLines = []
                }
                isInTable = false
            }

            // Add everything else to content
            if !line.isEmpty && line != tema && line != erintett && line != (hatarido ?? "") {
                contentLines.append(line)
            }
        }

        // Process remaining table if any
        if !tableLines.isEmpty {
            contentLines.append("\n" + tableLines.joined(separator: "\n") + "\n")
            products.append(contentsOf: parseTableProducts(tableLines: tableLines))
        }

        // Create info block with full content
        let tartalom = contentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        // Only create if we have at least a tema
        guard !tema.isEmpty else { return nil }

        return NapiInfoBlock(
            tema: tema,
            erintett: erintett.isEmpty ? "Mindenki" : erintett,
            hatarido: hatarido,
            tartalom: tartalom,
            termekLista: products.isEmpty ? nil : products,
            index: blockIndex
        )
    }

    // MARK: - Detect Table Row
    private static func isTableRow(line: String) -> Bool {
        // Check if line starts with digit (product code) and has multiple spaces or tabs
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let firstChar = trimmed.first, firstChar.isNumber else {
            return false
        }

        // Check for product code pattern (6 digits)
        let components = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" })
        if let first = components.first, first.count >= 5, first.allSatisfy({ $0.isNumber }) {
            return true
        }

        return false
    }

    // MARK: - Parse Table Products
    private static func parseTableProducts(tableLines: [String]) -> [[String: String]] {
        var products: [[String: String]] = []

        for line in tableLines {
            let parts = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 {
                products.append([
                    "kod": String(parts[0]),
                    "leiras": String(parts[1])
                ])
            } else {
                // Try space/tab separated
                let components = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                if components.count >= 2, let first = components.first, first.allSatisfy({ $0.isNumber }) {
                    products.append([
                        "kod": components[0],
                        "leiras": components.dropFirst().joined(separator: " ")
                    ])
                }
            }
        }

        return products
    }
}
