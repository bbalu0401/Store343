// HianycikkReszletekView.swift
// Product details view with editing capabilities

import SwiftUI
import CoreData

struct HianycikkReszletekView: View {
    @ObservedObject var termek: HianycikkEntity
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var jegyzetekText: String = ""
    @State private var selectedPrioritas: HianycikkPrioritas = .normal
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("\(termek.cikkszam ?? "N/A") | \(termek.cikkMegnev ?? "Név nélkül")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Alapadatok
                    SectionCard(title: "Alapadatok") {
                        VStack(spacing: 12) {
                            InfoRow(label: "Cikkszám:", value: termek.cikkszam ?? "N/A")
                            InfoRow(label: "Megnevezés:", value: termek.cikkMegnev ?? "N/A")
                            if let vonalkod = termek.vonalkod, !vonalkod.isEmpty {
                                InfoRow(label: "Vonalkód:", value: vonalkod)
                            }
                            if let kategoriaEnum = termek.kategoriaEnum {
                                InfoRow(label: "Kategória:", value: kategoriaEnum.displayName)
                            }
                        }
                    }

                    // Készlet információ
                    SectionCard(title: "Készlet információ") {
                        VStack(spacing: 12) {
                            InfoRow(label: "📦 Elvi készlet:", value: "\(termek.elviKeszlet) db")
                            InfoRow(label: "📊 Raktár készlet:", value: "\(termek.raktarKeszlet) db")
                            InfoRow(label: "🎯 Min. készlet:", value: "\(termek.minKeszlet) db")

                            if termek.isKritikusKeszlet {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("KÉSZLET KRITIKUS!")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }

                    // Hiány kezelés
                    SectionCard(title: "Hiány kezelés") {
                        VStack(spacing: 16) {
                            if let hianyKezdete = termek.hianyKezdete {
                                InfoRow(
                                    label: "📅 Hiány kezdete:",
                                    value: formattedDateTime(hianyKezdete)
                                )
                            }

                            // Prioritás selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🏷️ Prioritás:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                                ForEach(HianycikkPrioritas.allCases) { prioritas in
                                    Button(action: {
                                        selectedPrioritas = prioritas
                                        termek.prioritas = prioritas.rawValue
                                        saveContext()
                                    }) {
                                        HStack {
                                            Image(systemName: selectedPrioritas == prioritas ? "largecircle.fill.circle" : "circle")
                                            Text(prioritas.displayName)
                                                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }

                            // Jegyzetek
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📝 Jegyzetek:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                                TextEditor(text: $jegyzetekText)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.adaptiveBackground(colorScheme: colorScheme))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .onChange(of: jegyzetekText) { newValue in
                                        termek.jegyzetek = newValue
                                        saveContext()
                                    }
                            }
                        }
                    }

                    // Rendelési információ
                    SectionCard(title: "Rendelési információ") {
                        VStack(spacing: 12) {
                            InfoRow(label: "Ajánlott mennyiség:", value: "\(ajanlottMennyiseg) db")

                            if let szallito = termek.szallito, !szallito.isEmpty {
                                InfoRow(label: "Szállító:", value: szallito)
                            }

                            Button(action: {
                                hozzaadasRendeleshez()
                            }) {
                                HStack {
                                    Image(systemName: "cart.badge.plus")
                                    Text("Hozzáadás rendeléshez")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.lidlBlue)
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                    }

                    // Hiány megszüntetése gomb
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Hiány megszüntetése")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Bezár") {
                        dismiss()
                    }
                }
            }
            .alert("Hiány megszüntetése", isPresented: $showDeleteAlert) {
                Button("Mégse", role: .cancel) { }
                Button("Megszüntet", role: .destructive) {
                    megszuntetHiany()
                }
            } message: {
                Text("Biztosan megszünteted ezt a hiánycikket? Ez a művelet nem visszavonható.")
            }
            .onAppear {
                jegyzetekText = termek.jegyzetek ?? ""
                selectedPrioritas = termek.prioritasEnum ?? .normal
            }
        }
    }

    // MARK: - Computed Properties
    private var ajanlottMennyiseg: Int16 {
        // Ajánlott mennyiség: legalább a minimális készlet eléréséhez + tartalék
        let hiany = max(0, termek.minKeszlet - termek.elviKeszlet)
        return hiany + 10 // +10 db tartalék
    }

    // MARK: - Helper Functions
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }

    private func saveContext() {
        termek.modositva = Date()
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    private func hozzaadasRendeleshez() {
        termek.statusz = HianycikkStatusz.rendelesreVar.rawValue
        termek.rendeltMennyiseg = ajanlottMennyiseg
        saveContext()
        dismiss()
    }

    private func megszuntetHiany() {
        termek.lezarva = true
        termek.lezarasDatuma = Date()
        termek.statusz = HianycikkStatusz.lezarva.rawValue
        saveContext()
        dismiss()
    }
}

// MARK: - Section Card Component
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

            Divider()

            content
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
            Spacer()
        }
    }
}
