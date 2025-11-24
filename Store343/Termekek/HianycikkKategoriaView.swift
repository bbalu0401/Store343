// HianycikkKategoriaView.swift
// Category details view showing products in a specific category

import SwiftUI
import CoreData

struct HianycikkKategoriaView: View {
    let kategoria: HianycikkKategoria
    let onBack: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var termekek: FetchedResults<HianycikkEntity>

    @State private var searchText = ""
    @State private var selectedTermek: HianycikkEntity? = nil
    @State private var showStatusActionSheet = false

    init(kategoria: HianycikkKategoria, onBack: @escaping () -> Void) {
        self.kategoria = kategoria
        self.onBack = onBack

        // Initialize fetch request with filter for this category
        _termekek = FetchRequest<HianycikkEntity>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \HianycikkEntity.hianyKezdete, ascending: false)
            ],
            predicate: NSPredicate(format: "kategoria == %@ AND lezarva == NO", kategoria.rawValue),
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Hiánycikkek")
                    }
                    .foregroundColor(.lidlBlue)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(
                Divider()
                    .background(Color.secondary.opacity(0.3)),
                alignment: .bottom
            )

            // Category Header
            HStack(spacing: 12) {
                Text(kategoria.emoji)
                    .font(.system(size: 40))
                Text(kategoria.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                Spacer()
            }
            .padding()
            .background(Color.adaptiveCardBackground(colorScheme: colorScheme))

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Cikkszám vagy név keresése", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)

            // Product count
            HStack {
                Text("\(filteredTermekek.count) termék")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Products List
            if filteredTermekek.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTermekek, id: \.id) { termek in
                            TermekCard(termek: termek)
                                .onTapGesture {
                                    selectedTermek = termek
                                    showStatusActionSheet = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        megszuntetHianycikk(termek)
                                    } label: {
                                        Label("Megszüntet", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .confirmationDialog("Termék állapota", isPresented: $showStatusActionSheet, presenting: selectedTermek) { termek in
            ForEach(HianycikkStatusz.allCases.filter { $0 != .megszuntetve }) { status in
                Button(action: {
                    changeStatus(termek: termek, to: status)
                }) {
                    Text("\(status.emoji) \(status.displayName)")
                }
            }

            Button(role: .destructive, action: {
                megszuntetHianycikk(termek)
            }) {
                Text("⚫ Hiánycikk megszüntetése")
            }

            Button("Mégse", role: .cancel) { }
        }
    }

    // MARK: - Computed Properties
    private var filteredTermekek: [HianycikkEntity] {
        if searchText.isEmpty {
            return Array(termekek)
        } else {
            return termekek.filter { termek in
                let cikkszamMatch = termek.cikkszam?.localizedCaseInsensitiveContains(searchText) ?? false
                let megnevMatch = termek.cikkMegnev?.localizedCaseInsensitiveContains(searchText) ?? false
                return cikkszamMatch || megnevMatch
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text(kategoria.emoji)
                .font(.system(size: 60))
            Text("Nincs hiánycikk ebben a kategóriában")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Jelenleg minden termék készleten van")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions
    private func changeStatus(termek: HianycikkEntity, to status: HianycikkStatusz) {
        termek.statusz = status.rawValue
        termek.modositva = Date()

        do {
            try viewContext.save()
        } catch {
            print("Hiba az állapot változtatása során: \(error)")
        }
    }

    private func megszuntetHianycikk(_ termek: HianycikkEntity) {
        // Lezárja a hiánycikket
        termek.lezarva = true
        termek.lezarasDatuma = Date()
        termek.statusz = HianycikkStatusz.megszuntetve.rawValue
        termek.modositva = Date()

        // Mentés
        do {
            try viewContext.save()
        } catch {
            print("Hiba a hiánycikk megszüntetése során: \(error)")
        }
    }
}

// MARK: - Termek Card
struct TermekCard: View {
    let termek: HianycikkEntity
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with checkbox and name
            HStack(alignment: .top, spacing: 12) {
                // Checkbox placeholder (will be used in rendelési lista)
                Image(systemName: termek.statusz == HianycikkStatusz.rendelesreVar.rawValue ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(termek.statusz == HianycikkStatusz.rendelesreVar.rawValue ? .lidlBlue : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(termek.cikkszam ?? "N/A") | \(termek.cikkMegnev ?? "Név nélkül")")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                    // Details
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox")
                            .font(.caption)
                        Text("Elvi készlet: \(termek.elviKeszlet) db")
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)

                    if let hianyKezdete = termek.hianyKezdete {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("Hiány dátum: \(formattedDate(hianyKezdete))")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let jegyzetek = termek.jegyzetek, !jegyzetek.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption)
                            Text(jegyzetek)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Status Badge
            if let statuszString = termek.statusz,
               let statusz = HianycikkStatusz(rawValue: statuszString) {
                HStack {
                    Spacer()
                    Text(statusz.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusz.color.opacity(0.2))
                        .foregroundColor(statusz.color)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
