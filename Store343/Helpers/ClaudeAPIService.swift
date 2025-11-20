// ClaudeAPIService.swift
// Claude API integration for accurate Napi Infó OCR parsing

import Foundation
import UIKit

// MARK: - Response Models

// Napi Info Models
struct NapiInfoBlock: Codable {
    let tema: String
    let erintett: String
    let tartalom: String
    let hatarido: String?
    let emoji: String? // AI-selected emoji for the topic
    let checkboxes: [String]
    let images: [String]?
}

struct ClaudeAPIResponse: Codable {
    let success: Bool
    let blocks: [NapiInfoBlock]?
    let error: String?
    let usage: Usage?

    struct Usage: Codable {
        let input_tokens: Int
        let output_tokens: Int
    }
}

// NF Visszaküldés Models
struct NfTermekResponse: Codable {
    let cikkszam: String
    let cikk_megnevezes: String
    let bizonylat_szam: String
    let elvi_keszlet: Int
}

struct NfClaudeAPIResponse: Codable {
    let success: Bool
    let termekek: [NfTermekResponse]?
    let error: String?
    let usage: Usage?

    struct Usage: Codable {
        let input_tokens: Int
        let output_tokens: Int
    }
}

// MARK: - API Service
class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let baseURL = "https://store343-claude-api-5c681a6660b4.herokuapp.com"

    private init() {}

    /// Process Napi Infó document with Claude API (Image)
    /// - Parameter image: UIImage of the document to process
    /// - Returns: Array of parsed NapiInfoBlock objects
    func processNapiInfo(image: UIImage) async throws -> [NapiInfoBlock] {
        // 1. Convert image to JPEG with higher quality for better OCR
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            throw APIError.imageConversionFailed
        }

        // 2. Encode to base64
        let base64String = imageData.base64EncodedString()

        // 3. Create request
        guard let url = URL(string: "\(baseURL)/api/process-napi-info") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Longer timeout for API processing

        let body: [String: Any] = ["image_base64": base64String]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 4. Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // 6. Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ClaudeAPIResponse.self, from: data)

        // 7. Check success
        guard apiResponse.success, let blocks = apiResponse.blocks else {
            throw APIError.processingFailed(message: apiResponse.error ?? "Ismeretlen hiba történt")
        }

        // 8. Validate blocks
        guard !blocks.isEmpty else {
            throw APIError.noInfoFound
        }

        return blocks
    }

    /// Process Napi Infó document with Claude API (PDF/Document)
    /// - Parameter documentURL: URL of the PDF/document to process
    /// - Returns: Array of parsed NapiInfoBlock objects
    func processNapiInfoDocument(documentURL: URL) async throws -> [NapiInfoBlock] {
        // 1. Read document data
        guard let documentData = try? Data(contentsOf: documentURL) else {
            throw APIError.imageConversionFailed
        }

        // 2. Determine MIME type
        let mimeType = getMimeType(for: documentURL)

        // 3. Encode to base64
        let base64String = documentData.base64EncodedString()

        // 4. Create request
        guard let url = URL(string: "\(baseURL)/api/process-napi-info") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // Longer timeout for document processing

        let body: [String: Any] = [
            "document_base64": base64String,
            "document_type": mimeType
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 5. Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // 6. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // 7. Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ClaudeAPIResponse.self, from: data)

        // 8. Check success
        guard apiResponse.success, let blocks = apiResponse.blocks else {
            throw APIError.processingFailed(message: apiResponse.error ?? "Ismeretlen hiba történt")
        }

        // 9. Validate blocks
        guard !blocks.isEmpty else {
            throw APIError.noInfoFound
        }

        return blocks
    }

    /// Process NF visszaküldés document with Claude API (Image)
    /// - Parameter image: UIImage of the NF document to process
    /// - Returns: Array of parsed NfTermekResponse objects
    func processNfVisszakuldes(image: UIImage) async throws -> [NfTermekResponse] {
        // 1. Convert image to JPEG with higher quality for better OCR
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            throw APIError.imageConversionFailed
        }

        // 2. Encode to base64
        let base64String = imageData.base64EncodedString()

        // 3. Create request
        guard let url = URL(string: "\(baseURL)/api/process-nf-visszakuldes") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90 // Longer timeout for NF processing (can have many items)

        let body: [String: Any] = ["image_base64": base64String]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 4. Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // 6. Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(NfClaudeAPIResponse.self, from: data)

        // 7. Check success
        guard apiResponse.success, let termekek = apiResponse.termekek else {
            throw APIError.processingFailed(message: apiResponse.error ?? "Ismeretlen hiba történt")
        }

        // 8. Validate termekek
        guard !termekek.isEmpty else {
            throw APIError.noInfoFound
        }

        return termekek
    }

    /// Process NF visszaküldés document with Claude API (PDF/Document)
    /// - Parameter documentURL: URL of the PDF/document to process
    /// - Returns: Array of parsed NfTermekResponse objects
    func processNfVisszakuldesDocument(documentURL: URL) async throws -> [NfTermekResponse] {
        // 1. Read document data
        guard let documentData = try? Data(contentsOf: documentURL) else {
            throw APIError.imageConversionFailed
        }

        // 2. Determine MIME type
        let mimeType = getMimeType(for: documentURL)

        // 3. Encode to base64
        let base64String = documentData.base64EncodedString()

        // 4. Create request
        guard let url = URL(string: "\(baseURL)/api/process-nf-visszakuldes") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // Longer timeout for document processing

        let body: [String: Any] = [
            "document_base64": base64String,
            "document_type": mimeType
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 5. Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // 6. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // 7. Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(NfClaudeAPIResponse.self, from: data)

        // 8. Check success
        guard apiResponse.success, let termekek = apiResponse.termekek else {
            throw APIError.processingFailed(message: apiResponse.error ?? "Ismeretlen hiba történt")
        }

        // 9. Validate termekek
        guard !termekek.isEmpty else {
            throw APIError.noInfoFound
        }

        return termekek
    }

    // MARK: - Helper Functions

    /// Correct common Hungarian OCR errors
    static func correctHungarianText(_ text: String) -> String {
        var corrected = text

        // Common OCR mistakes - Hungarian specific
        let corrections: [String: String] = [
            // Accent marks
            "Tema:": "Téma:",
            "Erintett:": "Érintett:",
            "Hatarido:": "Határidő:",
            "erintett": "érintett",
            "hatarido": "határidő",

            // Days of week
            "hetfo": "hétfő",
            "kedd": "kedd",
            "szerda": "szerda",
            "csutortok": "csütörtök",
            "pentek": "péntek",
            "szombat": "szombat",
            "vasarnap": "vasárnap",

            // Cyrillic to Latin (common OCR mistake)
            "З": "3",
            "І": "I",
            "О": "0",
            "А": "A",
            "Е": "E",

            // Common words
            "keszlet": "készlet",
            "terulet": "terület",
            "feluletre": "felületre"
        ]

        for (wrong, right) in corrections {
            corrected = corrected.replacingOccurrences(of: wrong, with: right, options: .caseInsensitive)
        }

        return corrected
    }

    /// Get fallback emoji based on topic keywords (if backend doesn't provide one)
    static func getFallbackEmoji(for tema: String) -> String {
        let tema = tema.lowercased()

        // Food & Products
        if tema.contains("baby") || tema.contains("esl") { return "🍼" }
        if tema.contains("hűtő") || tema.contains("hűtött") { return "🧊" }
        if tema.contains("szaloncukor") { return "🍬" }
        if tema.contains("élelmiszer") || tema.contains("termék") { return "🛒" }

        // Operations
        if tema.contains("kassa") || tema.contains("pénz") { return "💰" }
        if tema.contains("mystery") || tema.contains("ellenőrzés") { return "🔍" }
        if tema.contains("raktár") || tema.contains("készlet") { return "📦" }

        // Marketing & Display
        if tema.contains("dekoráció") || tema.contains("karácsony") { return "🎄" }
        if tema.contains("magazin") || tema.contains("újság") { return "📰" }
        if tema.contains("display") || tema.contains("mpk") { return "📺" }
        if tema.contains("akció") || tema.contains("kedvezmény") { return "🏷️" }

        // Training & Info
        if tema.contains("training") || tema.contains("tréner") || tema.contains("oktatás") { return "📚" }
        if tema.contains("határidő") || tema.contains("időpont") { return "⏰" }
        if tema.contains("figyelem") || tema.contains("fontos") { return "⚠️" }
        if tema.contains("statisztika") || tema.contains("adat") { return "📊" }

        return "📋" // default
    }

    /// Get MIME type from file URL
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "pdf":
            return "application/pdf"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "xls":
            return "application/vnd.ms-excel"
        case "csv":
            return "text/csv"
        case "txt":
            return "text/plain"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default:
            return "application/octet-stream"
        }
    }

    // MARK: - Error Types
    enum APIError: LocalizedError {
        case imageConversionFailed
        case invalidURL
        case invalidResponse
        case serverError(statusCode: Int)
        case processingFailed(message: String)
        case noInfoFound
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Nem sikerült a képet feldolgozni"
            case .invalidURL:
                return "Érvénytelen szerveroldali URL"
            case .invalidResponse:
                return "Érvénytelen válasz a szervertől"
            case .serverError(let statusCode):
                return "Szerverhiba történt (kód: \(statusCode))"
            case .processingFailed(let message):
                return "Feldolgozási hiba: \(message)"
            case .noInfoFound:
                return "Nem található információ a dokumentumon"
            case .networkError(let error):
                return "Hálózati hiba: \(error.localizedDescription)"
            }
        }
    }
}
