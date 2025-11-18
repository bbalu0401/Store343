// QuickActionCard.swift
// Quick action card component for dashboard

import SwiftUI

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let emoji: String
    let count: Int
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    Text(emoji)
                        .font(.system(size: 32))

                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                // Badge number
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                        .padding([.top, .trailing], 16)
                }
            }
            .frame(height: 120)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: gradient.first?.opacity(0.3) ?? Color.clear, radius: 15, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
