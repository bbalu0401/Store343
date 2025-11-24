// HianycikkekView.swift
// Main view for shortage items (Hiánycikkek) with categories

import SwiftUI
import CoreData

struct HianycikkekView: View {
    @Binding var selectedType: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HianycikkEntity.letrehozva, ascending: false)],
        predicate: NSPredicate(format: "lezarva == NO"),
        animation: .default)
    private var hianycikkek: FetchedResults<HianycikkEntity>

    @State private var selectedKategoria: HianycikkKategoria? = nil
    @State private var showUjHianycikk = false
    @State private var showRendelesiLista = false
    @State private var showNapValtasAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if selectedKategoria == nil {
                    mainView
                } else {
                    HianycikkKategoriaView(
                        kategoria: selectedKategoria!,
                        onBack: { selectedKategoria = nil }
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showUjHianycikk) {
                UjHianycikkView()
            }
            .sheet(isPresented: $showRendelesiLista) {
                RendelesiListaView()
            }
            .alert("Nap váltás", isPresented: $showNapValtasAlert) {
                Button("Mégse", role: .cancel) { }
                Button("Új napot indítok", role: .destructive) {
                    ujNapotIndit()
                }
            } message: {
                Text("Ez lezárja az összes aktív hiánycikket és tiszta lappal indítasz. Biztosan folytatod?")
            }
        }
    }

    // MARK: - Main View
    private var mainView: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: {
                    selectedType = nil
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Vissza")
                    }
                    .foregroundColor(.lidlBlue)
                }

                Spacer()

                Text("Hiánycikkek")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showNapValtasAlert = true
                }) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.lidlBlue)
                }

                Button(action: {
                    showRendelesiLista = true
                }) {
                    Image(systemName: "list.clipboard")
                        .foregroundColor(.lidlBlue)
                }
                .padding(.leading, 12)
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(
                Divider()
                    .background(Color.secondary.opacity(0.3)),
                alignment: .bottom
            )

            ScrollView {
                VStack(spacing: 16) {
                    // Statisztika Card
                    StatisztikaCard(osszesen: osszesHianycikk)

                    // Kategória kártyák
                    ForEach(HianycikkKategoria.allCases) { kategoria in
                        KategoriaCard(
                            kategoria: kategoria,
                            count: getCountForKategoria(kategoria)
                        )
                        .onTapGesture {
                            selectedKategoria = kategoria
                        }
                    }

                    // Új hiánycikk hozzáadása gomb
                    Button(action: {
                        showUjHianycikk = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Új hiánycikk hozzáadása")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lidlRed)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
    }

    // MARK: - Computed Properties
    private var osszesHianycikk: Int {
        hianycikkek.count
    }

    private func getCountForKategoria(_ kategoria: HianycikkKategoria) -> Int {
        hianycikkek.filter { $0.kategoria == kategoria.rawValue }.count
    }

    // MARK: - Actions
    private func ujNapotIndit() {
        // Lezárja az összes aktív hiánycikket
        for hianycikk in hianycikkek {
            hianycikk.lezarva = true
            hianycikk.lezarasDatuma = Date()
            hianycikk.statusz = HianycikkStatusz.megszuntetve.rawValue
            hianycikk.modositva = Date()
        }

        // Mentés
        do {
            try viewContext.save()
        } catch {
            print("Hiba a nap váltás során: \(error)")
        }
    }
}

// MARK: - Statisztika Card
struct StatisztikaCard: View {
    let osszesen: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Statisztika")
                .font(.headline)
                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Összes hiánycikk:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(osszesen) termék")
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

// MARK: - Kategória Card
struct KategoriaCard: View {
    let kategoria: HianycikkKategoria
    let count: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            Text(kategoria.emoji)
                .font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(kategoria.color.opacity(0.2))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(kategoria.displayName)
                    .font(.headline)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                Text("\(count) hiányzó termék")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}
