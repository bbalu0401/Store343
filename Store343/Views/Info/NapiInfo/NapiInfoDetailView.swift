// NapiInfoDetailView.swift
// Dark mode redesign with priority-based expandable cards

import SwiftUI
import CoreData

// MARK: - Priority Enum
enum InfoPriority {
    case urgent    // 🔴 Ma este zárás
    case deadline  // 🟠 Van határidő
    case info      // 🔵 Nincs határidő

    var colors: (primary: Color, secondary: Color) {
        switch self {
        case .urgent:
            return (Color(hex: "#EF4444"), Color(hex: "#EC4899"))
        case .deadline:
            return (Color(hex: "#F97316"), Color(hex: "#F59E0B"))
        case .info:
            return (Color(hex: "#3B82F6"), Color(hex: "#06B6D4"))
        }
    }

    var badgeText: String {
        switch self {
        case .urgent: return "SÜRGŐS"
        case .deadline: return "HATÁRIDŐS"
        case .info: return "INFORMÁCIÓ"
        }
    }
}

struct NapiInfoDetailView: View {
    let info: NapiInfo
    let onBack: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showDeleteAlert = false
    @State private var expandedBlockIndex: Int? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background - Adaptive (black in dark, white in light)
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Header
                    headerView

                    // MARK: - Statistics Cards
                    if let blocks = parseInfoBlocks() {
                        statisticsView(blocks: blocks)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)

                        // MARK: - Topic Cards
                        ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                            ExpandableTopicCard(
                                block: block,
                                index: index,
                                isExpanded: expandedBlockIndex == index,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        expandedBlockIndex = (expandedBlockIndex == index) ? nil : index
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }

                    // Delete button at bottom
                    deleteButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .alert("Dokumentum törlése", isPresented: $showDeleteAlert) {
            Button("Mégse", role: .cancel) {}
            Button("Törlés", role: .destructive) {
                deleteInfo()
            }
        } message: {
            Text("Biztosan törölni szeretnéd ezt a dokumentumot? Ez a művelet nem vonható vissza.")
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Vissza")
                        .font(.body)
                }
                .foregroundColor(Color(hex: "#3B82F6"))
            }
            .padding(.leading, 16)
            .padding(.top, 8)

            // Title and date
            VStack(alignment: .leading, spacing: 2) {
                Text(info.fajlnev ?? "napi_info")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                if let datum = info.datum {
                    Text(formatDate(datum))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#94A3B8"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Statistics View
    private func statisticsView(blocks: [[String: Any]]) -> some View {
        let urgent = blocks.filter { getPriority(for: $0) == .urgent }.count
        let deadline = blocks.filter { getPriority(for: $0) == .deadline }.count

        return HStack(spacing: 12) {
            StatCard(title: "Témák", value: "\(blocks.count)", color: .white)
            StatCard(title: "Sürgős", value: "\(urgent)", color: Color(hex: "#EF4444"))
            StatCard(title: "Határidős", value: "\(deadline)", color: Color(hex: "#F97316"))
        }
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "trash")
                    .font(.body.weight(.semibold))
                Text("Dokumentum törlése")
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Functions

    func parseInfoBlocks() -> [[String: Any]]? {
        guard let termekListaJSON = info.termekLista,
              let termekData = termekListaJSON.data(using: .utf8),
              let blocks = try? JSONSerialization.jsonObject(with: termekData) as? [[String: Any]],
              !blocks.isEmpty else {
            return nil
        }
        return blocks
    }

    func getPriority(for block: [String: Any]) -> InfoPriority {
        guard let deadline = block["hatarido"] as? String, !deadline.isEmpty else {
            return .info
        }

        // Check if deadline is today
        let today = Calendar.current.startOfDay(for: Date())
        if deadline.lowercased().contains("ma") || deadline.contains(formatShortDate(today)) {
            return .urgent
        }

        return .deadline
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM d., EEEE"
        return formatter.string(from: date)
    }

    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }

    func deleteInfo() {
        viewContext.delete(info)
        try? viewContext.save()
        onBack()
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#94A3B8"))

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            Color(hex: "#1E293B")
                .opacity(colorScheme == .dark ? 0.5 : 0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#334155").opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Expandable Topic Card
struct ExpandableTopicCard: View {
    let block: [String: Any]
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var priority: InfoPriority {
        guard let deadline = block["hatarido"] as? String, !deadline.isEmpty else {
            return .info
        }

        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        let todayStr = formatter.string(from: today)

        if deadline.lowercased().contains("ma") || deadline.contains(todayStr) {
            return .urgent
        }
        return .deadline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Emoji icon
                    Text(getEmoji())
                        .font(.system(size: 32))

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text(block["tema"] as? String ?? "")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#94A3B8"))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(20)
            }
            .buttonStyle(PlainButtonStyle())

            // Badge and metadata (always visible)
            VStack(alignment: .leading, spacing: 12) {
                // Priority badge
                HStack(spacing: 8) {
                    Text(priority.badgeText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [priority.colors.primary, priority.colors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(9999)
                        .shadow(color: priority.colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)

                // Deadline (if exists)
                if let deadline = block["hatarido"] as? String, !deadline.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(priority.colors.primary)
                        Text(deadline)
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .padding(.horizontal, 20)
                }

                // Érintett (always visible)
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#3B82F6"))
                    Text(block["erintett"] as? String ?? "Mindenki")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal, 20)

                // Separator + hint
                if !isExpanded {
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 12))
                        Text("Koppints a részletekért")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#94A3B8"))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                Text(block["tartalom"] as? String ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "#E2E8F0") : Color(hex: "#334155"))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .background(gradientBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(priority.colors.primary.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: priority.colors.primary.opacity(0.2), radius: 20, x: 0, y: 10)
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }

    private var gradientBackground: some View {
        let colors: (Color, Color) = {
            switch priority {
            case .urgent:
                return (Color(hex: "#7F1D1D"), Color(hex: "#831843"))
            case .deadline:
                return (Color(hex: "#7C2D12"), Color(hex: "#78350F"))
            case .info:
                return (Color(hex: "#172554"), Color(hex: "#164E63"))
            }
        }()

        return LinearGradient(
            colors: [colors.0, colors.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(colorScheme == .dark ? 0.6 : 0.2)
    }

    private func getEmoji() -> String {
        // Try to get emoji from block (if Claude API provided it)
        if let emoji = block["emoji"] as? String, !emoji.isEmpty {
            return emoji
        }

        // Fallback to keyword matching
        if let tema = block["tema"] as? String {
            return ClaudeAPIService.getFallbackEmoji(for: tema)
        }

        return "📋"
    }
}
