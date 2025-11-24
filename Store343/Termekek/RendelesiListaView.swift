// RendelesiListaView.swift
// Összesítő nézet - állapot és kategória szerint csoportosítva

import SwiftUI
import CoreData

struct RendelesiListaView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HianycikkEntity.statusz, ascending: true),
            NSSortDescriptor(keyPath: \HianycikkEntity.kategoria, ascending: true)
        ],
        predicate: NSPredicate(format: "lezarva == NO"),
        animation: .default)
    private var osszesTermek: FetchedResults<HianycikkEntity>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Összesítő card
                OsszesitoCard(osszesDb: osszesTermek.count)
                    .padding()

                // Lista
                if osszesTermek.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Állapotok szerint:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            ForEach(allapotCsoportok, id: \.statusz) { allapotCsoport in
                                AllapotCsoport(
                                    statusz: allapotCsoport.statusz,
                                    kategoriaCsoportok: allapotCsoport.kategoriaCsoportok
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .navigationTitle("Összesítő")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vissza") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var allapotCsoportok: [AllapotCsoportData] {
        // First group by status
        var statusGroups: [HianycikkStatusz: [HianycikkEntity]] = [:]

        for termek in osszesTermek {
            if let statuszString = termek.statusz,
               let statusz = HianycikkStatusz(rawValue: statuszString),
               statusz != .megszuntetve {
                statusGroups[statusz, default: []].append(termek)
            }
        }

        // Then group each status by category
        var result: [AllapotCsoportData] = []
        for (statusz, termekek) in statusGroups {
            var categoryGroups: [HianycikkKategoria: [HianycikkEntity]] = [:]

            for termek in termekek {
                if let kategoriaString = termek.kategoria,
                   let kategoria = HianycikkKategoria(rawValue: kategoriaString) {
                    categoryGroups[kategoria, default: []].append(termek)
                }
            }

            let kategoriaCsoportok = categoryGroups.map { KategoriaCsoportData(kategoria: $0.key, termekek: $0.value) }
                .sorted { $0.kategoria.rawValue < $1.kategoria.rawValue }

            result.append(AllapotCsoportData(statusz: statusz, kategoriaCsoportok: kategoriaCsoportok))
        }

        return result.sorted { $0.statusz.rawValue < $1.statusz.rawValue }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.lidlBlue)
            Text("Nincs aktív hiánycikk")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Jelenleg minden termék készleten van")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Data Structures
struct AllapotCsoportData {
    let statusz: HianycikkStatusz
    let kategoriaCsoportok: [KategoriaCsoportData]
}

struct KategoriaCsoportData {
    let kategoria: HianycikkKategoria
    let termekek: [HianycikkEntity]
}

// MARK: - Összesítő Card
struct OsszesitoCard: View {
    let osszesDb: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Összesítő")
                .font(.headline)
                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Összes hiánycikk:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(osszesDb) termék")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Állapot Csoport
struct AllapotCsoport: View {
    let statusz: HianycikkStatusz
    let kategoriaCsoportok: [KategoriaCsoportData]
    @Environment(\.colorScheme) var colorScheme

    @State private var isExpanded = true

    private var osszesTermekDb: Int {
        kategoriaCsoportok.reduce(0) { $0 + $1.termekek.count }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Status Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                VStack(spacing: 0) {
                    HStack {
                        Text(statusz.emoji)
                            .font(.title2)
                        Text("\(statusz.displayName) (\(osszesTermekDb) db)")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(statusz.color.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            // Category Groups
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(kategoriaCsoportok, id: \.kategoria) { kategoriaCsoport in
                        KategoriaAlCsoport(
                            kategoria: kategoriaCsoport.kategoria,
                            termekek: kategoriaCsoport.termekek
                        )
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Kategória Alcsoport
struct KategoriaAlCsoport: View {
    let kategoria: HianycikkKategoria
    let termekek: [HianycikkEntity]
    @Environment(\.colorScheme) var colorScheme

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            // Category Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(kategoria.emoji)
                        .font(.title3)
                    Text("\(kategoria.displayName) (\(termekek.count) db)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
                .cornerRadius(10)
            }

            // Items
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(termekek, id: \.id) { termek in
                        OsszesitoTermekCard(termek: termek)
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Összesítő Termék Card
struct OsszesitoTermekCard: View {
    let termek: HianycikkEntity
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(termek.cikkszam ?? "N/A")")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(termek.cikkMegnev ?? "Név nélkül")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                    .lineLimit(2)

                if let hianyKezdete = termek.hianyKezdete {
                    Text("Hiány: \(formattedDate(hianyKezdete))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(8)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
}
