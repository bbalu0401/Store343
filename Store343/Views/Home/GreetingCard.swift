// GreetingCard.swift
// Main greeting card with time-based greeting, date and week number

import SwiftUI

struct GreetingCard: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1e70eb"), Color(hex: "#5b9df5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            VStack(alignment: .leading, spacing: 12) {
                // Time-based greeting with emoji
                HStack(spacing: 8) {
                    Text(getGreetingEmoji())
                        .font(.system(size: 32))
                    Text(getGreeting())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer().frame(height: 4)

                // Full date
                Text(getFormattedDate())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                // Week number with Lidl yellow
                Text(getWeekNumber())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#fef08a"))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 160)
        .shadow(color: Color(hex: "#1e70eb").opacity(0.3), radius: 20, y: 10)
    }

    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<8:
            return "Jó reggelt!"
        case 8..<18:
            return "Jó napot!"
        default:
            return "Jó estét!"
        }
    }

    private func getGreetingEmoji() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<8:
            return "🌅"
        case 8..<18:
            return "☀️"
        default:
            return "🌙"
        }
    }

    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM d., EEEE"
        return formatter.string(from: Date())
    }

    private func getWeekNumber() -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let weekNumber = calendar.component(.weekOfYear, from: Date())
        return "\(weekNumber). hét"
    }
}
