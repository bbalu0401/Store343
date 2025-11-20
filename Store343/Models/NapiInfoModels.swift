// NapiInfoModels.swift
// Data models for Napi Info processing

import Foundation

/// Represents a single Napi Info block/section
struct NapiInfoBlock {
    var tema: String
    var erintett: String
    var hatarido: String?
    var tartalom: String
    var termekLista: [[String: String]]?
    var index: Int
}
