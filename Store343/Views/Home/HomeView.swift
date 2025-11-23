// HomeView.swift
// Main home screen with dashboard cards

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTab: Int

    // Fetch all NapiInfos for statistics
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NapiInfo.datum, ascending: false)],
        animation: .default)
    private var napiInfos: FetchedResults<NapiInfo>

    // Columns for grid layout
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    // 1. Greeting Card (2 columns wide)
                    GreetingCard()
                        .gridCellColumns(2)

                    // 2. Quick Action cards - Daily (left) and Urgent (right)
                    QuickActionCard(
                        title: "Napi",
                        subtitle: "Új információk",
                        emoji: "🟡",
                        count: dailyCount,
                        gradient: [Color(hex: "#f59e0b"), Color(hex: "#fbbf24")],
                        action: {
                            selectedTab = 1 // Navigate to Infók tab
                        }
                    )

                    QuickActionCard(
                        title: "Sürgős",
                        subtitle: "Ma zárásig",
                        emoji: "🔴",
                        count: urgentCount,
                        gradient: [Color(hex: "#dc2626"), Color(hex: "#ef4444")],
                        action: {
                            selectedTab = 1 // Navigate to Infók tab
                        }
                    )

                    // 3. Heti Info card (2 columns wide)
                    WeeklyInfoCard(weeklyCount: weeklyCount)
                        .gridCellColumns(2)

                    // 4. Wide card - Beosztás (2 columns wide)
                    WideCard(
                        icon: "👥",
                        title: "Beosztás",
                        subtitle: "Csapatod és műszakok",
                        action: {
                            // TODO: Navigate to Beosztás tab (not implemented yet)
                        }
                    )
                    .gridCellColumns(2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background((colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea())
            .navigationTitle("Store 343")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Computed Properties (Real Data)

    /// Count urgent NapiInfos (deadline contains "ma" = today)
    private var urgentCount: Int {
        let today = Calendar.current.startOfDay(for: Date())

        return napiInfos.filter { info in
            guard info.feldolgozva,
                  let termekListaJSON = info.termekLista,
                  let termekData = termekListaJSON.data(using: .utf8),
                  let blocks = try? JSONSerialization.jsonObject(with: termekData) as? [[String: Any]] else {
                return false
            }

            // Check if any block has deadline today
            return blocks.contains { block in
                guard let deadline = block["hatarido"] as? String, !deadline.isEmpty else {
                    return false
                }
                return deadline.lowercased().contains("ma")
            }
        }.count
    }

    /// Count daily NapiInfos (today's date)
    private var dailyCount: Int {
        let today = Calendar.current.startOfDay(for: Date())

        return napiInfos.filter { info in
            guard let datum = info.datum else { return false }
            return Calendar.current.isDate(datum, inSameDayAs: today)
        }.count
    }

    /// Count weekly NapiInfos (this week)
    private var weeklyCount: Int {
        let today = Date()
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return 0
        }

        return napiInfos.filter { info in
            guard let datum = info.datum else { return false }
            return weekInterval.contains(datum)
        }.count
    }
}

// MARK: - Greeting Card Component
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
