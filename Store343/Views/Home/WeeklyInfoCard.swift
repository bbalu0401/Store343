// WeeklyInfoCard.swift
// Weekly info statistics card for dashboard

import SwiftUI

struct WeeklyInfoCard: View {
    @Environment(\.colorScheme) var colorScheme
    let weeklyCount: Int

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Text("📅")
                .font(.system(size: 40))

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text("Heti Info")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Text("Ezen a héten")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#94A3B8"))
            }

            Spacer()

            // Count badge
            VStack(spacing: 4) {
                Text("\(weeklyCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#3B82F6"))

                Text("dokumentum")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#94A3B8"))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#3B82F6").opacity(0.1), Color(hex: "#06B6D4").opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#3B82F6").opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }
}
