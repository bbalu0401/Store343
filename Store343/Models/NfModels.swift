// NfModels.swift
// Data models for NF (Nonfood) visszaküldés processing

import Foundation

/// Response from Claude API for NF OCR
struct NfTermekResponse: Codable {
    var bizonylat_szam: String
    var cikkszam: String
    var cikk_megnevezes: String
    var elvi_keszlet: Int
}

/// Result of processing one or more pages of NF document
struct NfOCRResult {
    var bizonylatSzam: String
    var termekek: [NfTermekData]
}

/// Single product/item from NF document
struct NfTermekData {
    var cikkszam: String
    var cikkMegnev: String
    var elviKeszlet: Int16
    var sorrend: Int16
}

/// Helper function to merge multiple OCR results (from multiple pages)
class NfOCRHelper {
    /// Merge Multiple Pages
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
