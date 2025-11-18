// HianycikkekView.swift
// Out of stock items management

import SwiftUI

struct HianycikkekView: View {
    @Binding var selectedType: String?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
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

            // Content
            VStack {
                Image(systemName: "cart.badge.minus")
                    .font(.system(size: 80))
                    .foregroundColor(.lidlRed)

                Text("Hiánycikkek")
                    .font(.title2)
                    .fontWeight(.light)
                    .padding()

                Text("Ez a funkció hamarosan elérhető lesz...")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
    }
}
