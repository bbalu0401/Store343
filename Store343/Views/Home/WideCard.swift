// WideCard.swift
// Wide card component for dashboard (2 columns wide)

import SwiftUI

struct WideCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Text(icon)
                    .font(.system(size: 40))

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#94A3B8"))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#94A3B8"))
            }
            .padding(20)
            .background(
                colorScheme == .dark
                    ? Color(hex: "#1E293B").opacity(0.5)
                    : Color(hex: "#F8FAFC")
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#334155").opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
