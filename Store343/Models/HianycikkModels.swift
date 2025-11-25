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

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .troso: return "Troso"
        case .mopro: return "Mopro"
        case .tiko: return "Tiko"
        case .bakeoff: return "Bakeoff"
        }
    }

    public var emoji: String {
        switch self {
        case .troso: return "📦"
        case .mopro: return "❄️"
        case .tiko: return "🧊"
        case .bakeoff: return "🥖"
        }
    }

    public var color: Color {
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

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .surgos: return "Sürgős"
        case .normal: return "Normál"
        case .alacsony: return "Alacsony"
        }
    }

    public var emoji: String {
        switch self {
        case .surgos: return "🔴"
        case .normal: return "🟡"
        case .alacsony: return "🟢"
        }
    }

    public var color: Color {
        switch self {
        case .surgos: return .red
        case .normal: return .orange
        case .alacsony: return .green
        }
    }

    public var sortOrder: Int {
        switch self {
        case .surgos: return 1
        case .normal: return 2
        case .alacsony: return 3
        }
    }
}

// MARK: - Státusz Enum
public enum HianycikkStatusz: String, CaseIterable, Identifiable {
    case varFeldolgozasra = "var_feldolgozasra"
    case ujMaiBeérkezés = "uj_mai_beerkezes"
    case holnapiBeerkezes = "holnapi_beerkezes"
    case rosszKeszlet = "rossz_keszlet"
    case adsTermek = "ads_termek"
    case kozpontiHianycikk = "kozponti_hianycikk"
    case maradekAru = "maradek_aru"
    case megszuntetve = "megszuntetve"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .varFeldolgozasra: return "Függőben"
        case .ujMaiBeérkezés: return "Új mai beérkezés"
        case .holnapiBeerkezes: return "Holnapi beérkezés"
        case .rosszKeszlet: return "Rossz készlet"
        case .adsTermek: return "ADS termék"
        case .kozpontiHianycikk: return "Központi hiánycikk"
        case .maradekAru: return "Maradék áru"
        case .megszuntetve: return "Hiánycikk megszüntetve"
        }
    }

    public var emoji: String {
        switch self {
        case .varFeldolgozasra: return "⏳"
        case .ujMaiBeérkezés: return "✅"
        case .holnapiBeerkezes: return "📅"
        case .rosszKeszlet: return "❌"
        case .adsTermek: return "🎯"
        case .kozpontiHianycikk: return "🏢"
        case .maradekAru: return "📉"
        case .megszuntetve: return "⚫"
        }
    }

    public var color: Color {
        switch self {
        case .varFeldolgozasra: return .yellow
        case .ujMaiBeérkezés: return .green
        case .holnapiBeerkezes: return .blue
        case .rosszKeszlet: return .red
        case .adsTermek: return .purple
        case .kozpontiHianycikk: return .orange
        case .maradekAru: return .brown
        case .megszuntetve: return .gray
        }
    }

    public var isFeldolgozva: Bool {
        switch self {
        case .varFeldolgozasra:
            return false
        case .megszuntetve:
            return false
        default:
            return true
        }
    }
}

// MARK: - HianycikkEntity Extension
// Note: HianycikkEntity automatically conforms to Identifiable via CoreData's @NSManaged id property

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
