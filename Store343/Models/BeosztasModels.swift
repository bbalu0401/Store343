// BeosztasModels.swift
// Data models for employee scheduling

import Foundation

/// Employee/Worker information
struct Munkavallaló: Identifiable, Codable {
    let id: String
    let nev: String

    init(id: String = UUID().uuidString, nev: String) {
        self.id = id
        self.nev = nev
    }
}

/// Shift/Work schedule entry
struct Muszak: Identifiable, Codable {
    let id: String
    let munkavallaloId: String
    let munkavallaloNev: String
    let datum: Date
    let kezdes: Date  // Start time
    let veg: Date     // End time

    init(id: String = UUID().uuidString,
         munkavallaloId: String,
         munkavallaloNev: String,
         datum: Date,
         kezdes: Date,
         veg: Date) {
        self.id = id
        self.munkavallaloId = munkavallaloId
        self.munkavallaloNev = munkavallaloNev
        self.datum = datum
        self.kezdes = kezdes
        self.veg = veg
    }

    /// Format start time as "HH:mm"
    var kezdesIdopont: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: kezdes)
    }

    /// Format end time as "HH:mm"
    var vegIdopont: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: veg)
    }

    /// Format shift as "HH:mm - HH:mm"
    var idotartam: String {
        return "\(kezdesIdopont) - \(vegIdopont)"
    }
}

/// Helper functions for scheduling
class BeosztasHelper {

    /// Get the start of the week (Monday) for a given date
    static func hetKezdete(datum: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: datum)
        components.weekday = 2  // Monday
        return calendar.date(from: components) ?? datum
    }

    /// Get the end of the week (Sunday) for a given date
    static func hetVege(datum: Date) -> Date {
        let calendar = Calendar.current
        let hetKezd = hetKezdete(datum: datum)
        return calendar.date(byAdding: .day, value: 6, to: hetKezd) ?? datum
    }

    /// Get all dates in the week (Monday to Sunday)
    static func hetiNapok(datum: Date) -> [Date] {
        let calendar = Calendar.current
        let hetKezd = hetKezdete(datum: datum)

        return (0..<7).compactMap { napIndex in
            calendar.date(byAdding: .day, value: napIndex, to: hetKezd)
        }
    }

    /// Check if two dates are on the same day
    static func ugyanazANap(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Format date as "YYYY. MMMM dd. EEEE"
    static func formatDatum(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM dd. EEEE"
        return formatter.string(from: date)
    }

    /// Get shifts for a specific date, sorted by start time
    static func napiBeosztasok(osszesMuszak: [Muszak], datum: Date) -> [Muszak] {
        return osszesMuszak
            .filter { ugyanazANap($0.datum, datum) }
            .sorted { $0.kezdes < $1.kezdes }
    }
}
