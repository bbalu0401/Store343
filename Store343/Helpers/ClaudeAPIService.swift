// ClaudeAPIService.swift
// OCR API integration for Napi Infó processing
// Uses Google Cloud Vision API backend

import Foundation
import UIKit

// MARK: - Response Models

struct NapiInfoBlock: Codable {
    let tema: String
    let erintett: String
    let tartalom: String
    let hatarido: String?
}

struct OCRAPIResponse: Codable {
    let success: Bool
    let blocks: [NapiInfoBlock]?
    let raw_text: String?
    let error: String?
}

// MARK: - API Service
class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    // TODO: Update this URL after Railway deployment
    private let baseURL = "https://your-app-name.up.railway.app"

    private init() {}

    // MARK: - Napi Info Processing

    /// Process Napi Infó document with Google Cloud Vision API
    func processNapiInfo(image: UIImage) async throws -> [NapiInfoBlock] {
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            throw APIError.imageConversionFailed
        }

        let base64String = imageData.base64EncodedString()

        guard let url = URL(string: "\(baseURL)/api/process-napi-info") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = ["image_base64": base64String]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(OCRAPIResponse.self, from: data)

        guard apiResponse.success, let blocks = apiResponse.blocks else {
            throw APIError.processingFailed(message: apiResponse.error ?? "Ismeretlen hiba")
        }

        guard !blocks.isEmpty else {
            throw APIError.noInfoFound
        }

        return blocks
    }

    // MARK: - Helper Functions

    /// Correct common Hungarian OCR mistakes
    static func correctHungarianText(_ text: String) -> String {
        var corrected = text
        
        // Common OCR mistakes for Hungarian characters
        let replacements: [(String, String)] = [
            ("õ", "ő"), ("ó́", "ő"), ("õ", "ő"),
            ("ǘ", "ű"), ("ú́", "ű"), ("û", "ű"),
            ("á́", "á"), ("é́", "é"), ("í́", "í"), ("ó́", "ó"), ("ú́", "ú"),
        ]
        
        for (wrong, correct) in replacements {
            corrected = corrected.replacingOccurrences(of: wrong, with: correct)
        }
        
        return corrected
    }

    /// Get emoji for a topic (fallback for simple categorization)
    static func getFallbackEmoji(for tema: String) -> String {
        let temaLower = tema.lowercased()
        
        // Product categories
        if temaLower.contains("pék") || temaLower.contains("kenyér") { return "🍞" }
        if temaLower.contains("hús") || temaLower.contains("szalámi") { return "🥩" }
        if temaLower.contains("zöldség") || temaLower.contains("gyümölcs") { return "🥬" }
        if temaLower.contains("tejtermék") || temaLower.contains("tej") || temaLower.contains("sajt") { return "🥛" }
        if temaLower.contains("ital") || temaLower.contains("üdítő") { return "🥤" }
        
        // Operations
        if temaLower.contains("kassa") || temaLower.contains("pénz") { return "💰" }
        if temaLower.contains("raktár") || temaLower.contains("készlet") { return "📦" }
        if temaLower.contains("ár") || temaLower.contains("árazás") { return "💲" }
        
        // General
        if temaLower.contains("figyelem") || temaLower.contains("fontos") { return "⚠️" }
        if temaLower.contains("akció") { return "🏷️" }
        
        return "📋" // default
    }

    // MARK: - Placeholder functions for NF (to be implemented later)
    
    func processNfVisszakuldes(image: UIImage) async throws -> [Any] {
        // TODO: Implement NF processing when needed
        throw APIError.processingFailed(message: "NF feldolgozás még nem elérhető")
    }
    
    func processNfVisszakuldesDocument(documentURL: URL) async throws -> [Any] {
        // TODO: Implement NF document processing when needed
        throw APIError.processingFailed(message: "NF feldolgozás még nem elérhető")
    }

    // MARK: - Error Types
    enum APIError: LocalizedError {
        case imageConversionFailed
        case invalidURL
        case invalidResponse
        case serverError(statusCode: Int)
        case processingFailed(message: String)
        case noInfoFound

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Nem sikerült a képet feldolgozni"
            case .invalidURL:
                return "Érvénytelen szerveroldali URL"
            case .invalidResponse:
                return "Érvénytelen válasz a szervertől"
            case .serverError(let statusCode):
                return "Szerverhiba (kód: \(statusCode))"
            case .processingFailed(let message):
                return "Feldolgozási hiba: \(message)"
            case .noInfoFound:
                return "Nem található információ"
            }
        }
    }
}
