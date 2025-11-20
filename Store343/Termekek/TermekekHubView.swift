// TermekekHubView.swift
// Products hub with navigation to different product management types

import SwiftUI

struct TermekekHubView: View {
    @State private var selectedType: String? = nil
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if selectedType == nil {
                    TermekekSelectionView(selectedType: $selectedType)
                } else if selectedType == "elosztasok" {
                    ElosztasokView(selectedType: $selectedType)
                } else if selectedType == "hianycikkek" {
                    HianycikkekView(selectedType: $selectedType)
                } else if selectedType == "nf_visszakuldes" {
                    NfVisszakuldesView(selectedType: $selectedType)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Selection View
struct TermekekSelectionView: View {
    @Binding var selectedType: String?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Spacer()

                Text("Termékek")
                    .font(.headline)

                Spacer()
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(
                Divider()
                    .background(Color.secondary.opacity(0.3)),
                alignment: .bottom
            )

            VStack(spacing: 16) {
                Text("Válaszd ki a termékezési feladatot")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)

                // Elosztások
                TermekekTypeCard(
                    icon: "square.grid.2x2",
                    title: "Elosztások",
                    subtitle: "Termékek elosztása és áthelyezése",
                    color: .lidlBlue
                )
                .onTapGesture {
                    selectedType = "elosztasok"
                }

                // Hiánycikkek
                TermekekTypeCard(
                    icon: "cart.badge.minus",
                    title: "Hiánycikkek",
                    subtitle: "Hiányzó és elfogyott termékek",
                    color: .lidlRed
                )
                .onTapGesture {
                    selectedType = "hianycikkek"
                }

                // Nf visszaküldés
                TermekekTypeCard(
                    icon: "arrow.uturn.backward.circle",
                    title: "Nf visszaküldés",
                    subtitle: "Számlák és visszaküldések kezelése",
                    color: .lidlYellow
                )
                .onTapGesture {
                    selectedType = "nf_visszakuldes"
                }

                Spacer()
            }
            .padding()
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
    }
}

// MARK: - Type Card Component
struct TermekekTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(color)
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                Text(subtitle)
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
    }
}
