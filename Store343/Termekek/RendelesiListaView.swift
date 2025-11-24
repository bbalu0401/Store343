// RendelesiListaView.swift
// Order list view with selected items for ordering

import SwiftUI
import CoreData

struct RendelesiListaView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HianycikkEntity.kategoria, ascending: true),
            NSSortDescriptor(keyPath: \HianycikkEntity.cikkszam, ascending: true)
        ],
        predicate: NSPredicate(format: "statusz == %@ AND lezarva == NO", HianycikkStatusz.rendelesreVar.rawValue),
        animation: .default)
    private var rendelesreVaroTermekek: FetchedResults<HianycikkEntity>

    @State private var selectedTermekIds: Set<UUID> = []
    @State private var showExportOptions = false
    @State private var showVeglegesitesAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Összesítő card
                OsszesitoCard(
                    kijeloltDb: selectedTermekIds.count,
                    osszesDb: rendelesreVaroTermekek.count
                )
                .padding()

                // Tömeges műveletek
                HStack(spacing: 12) {
                    Button(action: osszesKijelolese) {
                        Text("Összes kijelölése")
                            .font(.subheadline)
                            .foregroundColor(.lidlBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.lidlBlue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: kijelelesTorlese) {
                        Text("Kijelölés törlése")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                // Lista
                if rendelesreVaroTermekek.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Kategóriák szerint:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            ForEach(kategoriacsoportok, id: \.kategoria) { csoport in
                                KategoriaCsoport(
                                    kategoria: csoport.kategoria,
                                    termekek: csoport.termekek,
                                    selectedIds: $selectedTermekIds
                                )
                            }
                        }
                        .padding()
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showExportOptions = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Rendelés exportálása")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lidlYellow)
                        .cornerRadius(12)
                    }
                    .disabled(selectedTermekIds.isEmpty)
                    .opacity(selectedTermekIds.isEmpty ? 0.5 : 1.0)

                    Button(action: {
                        showVeglegesitesAlert = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("✅ Rendelés véglegesítése")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lidlBlue)
                        .cornerRadius(12)
                    }
                    .disabled(selectedTermekIds.isEmpty)
                    .opacity(selectedTermekIds.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .navigationTitle("Rendelési lista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vissza") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Export opciók", isPresented: $showExportOptions) {
                Button("Email") { exportEmail() }
                Button("PDF") { exportPDF() }
                Button("CSV") { exportCSV() }
                Button("Mégse", role: .cancel) { }
            }
            .alert("Rendelés véglegesítése", isPresented: $showVeglegesitesAlert) {
                Button("Mégse", role: .cancel) { }
                Button("Véglegesítés", role: .destructive) {
                    veglegesitRendeles()
                }
            } message: {
                Text("Biztosan véglegesíted a rendelést? A kijelölt termékek státusza 'Megrendelve'-re változik.")
            }
            .onAppear {
                // Auto-select all items on appear
                selectedTermekIds = Set(rendelesreVaroTermekek.map { $0.id! })
            }
        }
    }

    // MARK: - Computed Properties
    private var kategoriacsoportok: [KategoriaCsoportData] {
        var groups: [HianycikkKategoria: [HianycikkEntity]] = [:]

        for termek in rendelesreVaroTermekek {
            if let kategoriaString = termek.kategoria,
               let kategoria = HianycikkKategoria(rawValue: kategoriaString) {
                groups[kategoria, default: []].append(termek)
            }
        }

        return groups.map { KategoriaCsoportData(kategoria: $0.key, termekek: $0.value) }
            .sorted { $0.kategoria.rawValue < $1.kategoria.rawValue }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.lidlBlue)
            Text("Nincs rendelésre váró termék")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Adj hozzá termékeket a rendeléshez a részletek nézetből")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Functions
    private func osszesKijelolese() {
        selectedTermekIds = Set(rendelesreVaroTermekek.map { $0.id! })
    }

    private func kijelelesTorlese() {
        selectedTermekIds.removeAll()
    }

    private func exportEmail() {
        // TODO: Implement email export
        print("Export to Email")
    }

    private func exportPDF() {
        // TODO: Implement PDF export
        print("Export to PDF")
    }

    private func exportCSV() {
        // TODO: Implement CSV export
        print("Export to CSV")
    }

    private func veglegesitRendeles() {
        for termek in rendelesreVaroTermekek where selectedTermekIds.contains(termek.id!) {
            termek.statusz = HianycikkStatusz.megrendelve.rawValue
            termek.modositva = Date()
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving: \(error)")
        }
    }
}

// MARK: - Data Structures
struct KategoriaCsoportData {
    let kategoria: HianycikkKategoria
    let termekek: [HianycikkEntity]
}

// MARK: - Összesítő Card
struct OsszesitoCard: View {
    let kijeloltDb: Int
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
                    Text("Kiválasztva:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(kijeloltDb) termék")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Összes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(osszesDb) termék")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Kategória Csoport
struct KategoriaCsoport: View {
    let kategoria: HianycikkKategoria
    let termekek: [HianycikkEntity]
    @Binding var selectedIds: Set<UUID>
    @Environment(\.colorScheme) var colorScheme

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 12) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(kategoria.emoji)
                        .font(.title3)
                    Text("\(kategoria.displayName) (\(termekek.count) tétel)")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
                .cornerRadius(12)
            }

            // Items
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(termekek, id: \.id) { termek in
                        RendelesiTermekCard(
                            termek: termek,
                            isSelected: selectedIds.contains(termek.id!)
                        ) {
                            if selectedIds.contains(termek.id!) {
                                selectedIds.remove(termek.id!)
                            } else {
                                selectedIds.insert(termek.id!)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Rendelési Termék Card
struct RendelesiTermekCard: View {
    let termek: HianycikkEntity
    let isSelected: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .lidlBlue : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(termek.cikkszam ?? "N/A") | \(termek.cikkMegnev ?? "Név nélkül")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                    Text("Mennyiség: \(termek.rendeltMennyiseg) db")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
