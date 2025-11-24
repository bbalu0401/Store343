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
                    showRendelesiLista = true
                }) {
                    Image(systemName: "list.clipboard")
                        .foregroundColor(.lidlBlue)
                }
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
                    StatisztikaCard(
                        osszesen: osszesHianycikk,
                        rendelesreVar: rendelesreVarCount,
                        uj: ujCount
                    )

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

    private var rendelesreVarCount: Int {
        hianycikkek.filter { $0.statusz == HianycikkStatusz.rendelesreVar.rawValue }.count
    }

    private var ujCount: Int {
        hianycikkek.filter { $0.statusz == HianycikkStatusz.uj.rawValue }.count
    }

    private func getCountForKategoria(_ kategoria: HianycikkKategoria) -> Int {
        hianycikkek.filter { $0.kategoria == kategoria.rawValue }.count
    }
}

// MARK: - Statisztika Card
struct StatisztikaCard: View {
    let osszesen: Int
    let rendelesreVar: Int
    let uj: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Statisztika")
                .font(.headline)
                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

            Divider()

            HStack(spacing: 20) {
                StatItem(emoji: "🔴", text: "\(osszesen) hiánycikk összesen")
                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(emoji: "🟡", text: "\(rendelesreVar) rendelésre vár")
                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(emoji: "🟢", text: "\(uj) még nem kezelt")
                Spacer()
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}

struct StatItem: View {
    let emoji: String
    let text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
        }
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
