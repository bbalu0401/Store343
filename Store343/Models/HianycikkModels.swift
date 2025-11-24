// HianycikkModels.swift
// Models and enums for Hiánycikk (shortage items) feature

import Foundation
import SwiftUI

// MARK: - Kategória Enum
public enum HianycikkKategoria: String, CaseIterable, Identifiable {
    case troso = "troso"
    case mopro = "mopro"
    case tiko = "tiko"
    case bakeoff = "bakeoff"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .troso: return "📦 Troso"
        case .mopro: return "❄️ Mopro"
        case .tiko: return "🧊 Tiko"
        case .bakeoff: return "🥖 Bakeoff"
        }
    }

    var emoji: String {
        switch self {
        case .troso: return "📦"
        case .mopro: return "❄️"
        case .tiko: return "🧊"
        case .bakeoff: return "🥖"
        }
    }

    var color: Color {
        switch self {
        case .troso: return .brown
        case .mopro: return .blue
        case .tiko: return .cyan
        case .bakeoff: return .orange
        }
    }
}

// MARK: - Prioritás Enum
public enum HianycikkPrioritas: String, CaseIterable, Identifiable {
    case surgos = "surgos"
    case normal = "normal"
    case alacsony = "alacsony"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .surgos: return "🔴 Sürgős"
        case .normal: return "🟡 Normál"
        case .alacsony: return "🟢 Alacsony"
        }
    }

    var emoji: String {
        switch self {
        case .surgos: return "🔴"
        case .normal: return "🟡"
        case .alacsony: return "🟢"
        }
    }

    var color: Color {
        switch self {
        case .surgos: return .red
        case .normal: return .orange
        case .alacsony: return .green
        }
    }

    var sortOrder: Int {
        switch self {
        case .surgos: return 1
        case .normal: return 2
        case .alacsony: return 3
        }
    }
}

// MARK: - Státusz Enum
public enum HianycikkStatusz: String, CaseIterable, Identifiable {
    case uj = "uj"
    case rendelesreVar = "rendelesre_var"
    case megrendelve = "megrendelve"
    case megerkezett = "megerkezett"
    case lezarva = "lezarva"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uj: return "🟢 Új"
        case .rendelesreVar: return "🟡 Rendelésre vár"
        case .megrendelve: return "🔵 Megrendelve"
        case .megerkezett: return "✅ Megérkezett"
        case .lezarva: return "⚫ Lezárva"
        }
    }

    var emoji: String {
        switch self {
        case .uj: return "🟢"
        case .rendelesreVar: return "🟡"
        case .megrendelve: return "🔵"
        case .megerkezett: return "✅"
        case .lezarva: return "⚫"
        }
    }

    var color: Color {
        switch self {
        case .uj: return .green
        case .rendelesreVar: return .orange
        case .megrendelve: return .blue
        case .megerkezett: return .green
        case .lezarva: return .gray
        }
    }
}

// MARK: - HianycikkEntity Extension
public extension HianycikkEntity {
    var kategoriaEnum: HianycikkKategoria? {
        get {
            guard let kategoria = kategoria else { return nil }
            return HianycikkKategoria(rawValue: kategoria)
        }
        set {
            kategoria = newValue?.rawValue
        }
    }

    var prioritasEnum: HianycikkPrioritas? {
        get {
            guard let prioritas = prioritas else { return nil }
            return HianycikkPrioritas(rawValue: prioritas)
        }
        set {
            prioritas = newValue?.rawValue
        }
    }

    var statuszEnum: HianycikkStatusz? {
        get {
            guard let statusz = statusz else { return nil }
            return HianycikkStatusz(rawValue: statusz)
        }
        set {
            statusz = newValue?.rawValue
        }
    }

    var isKritikusKeszlet: Bool {
        return elviKeszlet < minKeszlet
    }
}
