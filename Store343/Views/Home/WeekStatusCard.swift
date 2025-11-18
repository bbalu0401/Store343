// WeekStatusCard.swift
// Week status card with Lidl colors and real data

import SwiftUI

struct WeekStatusCard: View {
    @Environment(\.colorScheme) var colorScheme
    let urgentCount: Int
    let dailyCount: Int

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1e70eb"), Color(hex: "#5b9df5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            VStack(alignment: .leading, spacing: 12) {
                // Active badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#4ade80"))
                        .frame(width: 8, height: 8)
                    Text("Aktív")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)

                Spacer().frame(height: 4)

                // Week number with Lidl yellow
                Text(getCurrentWeekNumber())
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(Color(hex: "#fef08a"))

                Text(getStatusMessage())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                // Statistics with real data
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("📋")
                        Text("\(urgentCount + dailyCount) aktív")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    HStack(spacing: 6) {
                        Text("🔴")
                        Text("\(urgentCount) sürgős")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white.opacity(0.9))
            }
            .padding(20)
        }
        .frame(height: 180)
        .shadow(color: Color(hex: "#1e70eb").opacity(0.3), radius: 20, y: 10)
    }

    private func getCurrentWeekNumber() -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let weekNumber = calendar.component(.weekOfYear, from: Date())
        return "\(weekNumber). hét"
    }

    private func getStatusMessage() -> String {
        if urgentCount == 0 && dailyCount == 0 {
            return "Nincs új feladat"
        } else if urgentCount == 0 {
            return "Minden rendben megy"
        } else if urgentCount <= 2 {
            return "Kicsit sürget a munka"
        } else {
            return "Sok sürgős feladat!"
        }
    }
}
