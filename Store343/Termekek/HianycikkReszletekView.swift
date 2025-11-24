// HianycikkReszletekView.swift
// Product details view with editing capabilities

import SwiftUI
import CoreData

struct HianycikkReszletekView: View {
    @ObservedObject var termek: HianycikkEntity
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        if let kategoriaEnum = termek.kategoriaEnum {
                            Text(kategoriaEnum.emoji)
                                .font(.system(size: 60))
                        }

                        Text(termek.cikkMegnev ?? "Név nélkül")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                            .multilineTextAlignment(.center)

                        Text(termek.cikkszam ?? "N/A")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // Információk
                    SectionCard(title: "Információk") {
                        VStack(spacing: 12) {
                            InfoRow(label: "Cikkszám:", value: termek.cikkszam ?? "N/A")
                            InfoRow(label: "Megnevezés:", value: termek.cikkMegnev ?? "N/A")

                            if let kategoriaEnum = termek.kategoriaEnum {
                                InfoRow(label: "Kategória:", value: kategoriaEnum.displayName)
                            }

                            if let hianyKezdete = termek.hianyKezdete {
                                InfoRow(
                                    label: "Hiány kezdete:",
                                    value: formattedDateTime(hianyKezdete)
                                )
                            }

                            if let statuszEnum = termek.statuszEnum {
                                HStack {
                                    Text("Státusz:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .frame(width: 140, alignment: .leading)
                                    Text(statuszEnum.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                                    Spacer()
                                }
                            }
                        }
                    }

                    // Hiány megszüntetése gomb
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Hiány megszüntetése")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
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
        }
    }

    // MARK: - Helper Functions
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }

    private func megszuntetHiany() {
        termek.lezarva = true
        termek.lezarasDatuma = Date()
        termek.statusz = HianycikkStatusz.lezarva.rawValue
        termek.modositva = Date()

        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }

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
