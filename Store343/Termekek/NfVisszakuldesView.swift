// NfVisszakuldesView.swift
// Main NF (Nonfood) visszaküldés view with weekly list

import SwiftUI
import CoreData

struct NfVisszakuldesView: View {
    @Binding var selectedType: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \NfHet.ev, ascending: true),
            NSSortDescriptor(keyPath: \NfHet.hetSzam, ascending: true)
        ],
        animation: .default)
    private var weeks: FetchedResults<NfHet>

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showYearPicker = false
    @State private var selectedWeek: NfHet? = nil
    @State private var showOCRFlow = false
    @State private var weekForUpload: NfHet? = nil

    let availableYears = [2024, 2025, 2026, 2027]

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

                Text("Nf visszaküldés")
                    .font(.headline)

                Spacer()

                // Year selector
                Button(action: {
                    showYearPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(String(selectedYear))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.lidlBlue)
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
            if selectedWeek == nil {
                weekListView
            } else if let week = selectedWeek {
                // Navigate to bizonylat list
                NfBizonylatListView(
                    week: week,
                    onBack: {
                        selectedWeek = nil
                    },
                    onAddPages: {
                        weekForUpload = week
                        showOCRFlow = true
                    }
                )
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
        .onAppear {
            generateWeeksIfNeeded()
        }
        .actionSheet(isPresented: $showYearPicker) {
            ActionSheet(
                title: Text("Válassz évet"),
                buttons: availableYears.map { year in
                        .default(Text("\(year)")) {
                        selectedYear = year
                        generateWeeksIfNeeded()
                    }
                } + [.cancel()]
            )
        }
        .sheet(isPresented: $showOCRFlow) {
            if let week = weekForUpload {
                NfOCRProcessView(week: week, onComplete: {
                    // Refresh view after completion
                    showOCRFlow = false
                })
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    // MARK: - Week List View
    var weekListView: some View {
        let filteredWeeks = weeks.filter { $0.ev == selectedYear }

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                if filteredWeeks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("Nincsenek hetek")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("Nyomd meg a gombot a hetek generálásához.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            generateWeeksIfNeeded()
                        }) {
                            Text("Hetek generálása")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.lidlBlue)
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    // Group weeks by month
                    let groupedWeeks = groupWeeksByMonth(filteredWeeks)

                    ForEach(groupedWeeks.indices, id: \.self) { index in
                        let monthGroup = groupedWeeks[index]

                        VStack(alignment: .leading, spacing: 0) {
                            // Month header
                            Text(monthGroup.monthName.uppercased())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, index == 0 ? 16 : 24)
                                .padding(.bottom, 12)

                            // Weeks in this month
                            ForEach(monthGroup.weeks, id: \.id) { week in
                                WeekCard(week: week, onTap: {
                                    selectedWeek = week
                                }, onUpload: {
                                    weekForUpload = week
                                    showOCRFlow = true
                                })
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                                .id(week.id) // For ScrollViewReader
                            }
                        }
                    }

                    // Bottom padding
                    Color.clear.frame(height: 16)
                }
            }
            .onAppear {
                // Scroll to current week
                scrollToCurrentWeek(proxy: proxy, weeks: filteredWeeks)
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        }
    }

    // MARK: - Scroll to Current Week
    func scrollToCurrentWeek(proxy: ScrollViewProxy, weeks: [NfHet]) {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekNumber = calendar.component(.weekOfYear, from: today)

        // Find the week that contains today
        if let currentWeek = weeks.first(where: { week in
            guard let startDate = week.kezdoDatum,
                  let endDate = week.vegDatum else { return false }
            return today >= startDate && today <= endDate
        }) {
            // Scroll to current week with animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    proxy.scrollTo(currentWeek.id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Month Grouping
    struct MonthGroup {
        let monthName: String
        let monthNumber: Int
        let weeks: [NfHet]
    }

    func groupWeeksByMonth(_ weeks: [NfHet]) -> [MonthGroup] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "hu_HU")

        // Group weeks by month of their start date
        var monthDict: [Int: [NfHet]] = [:]

        for week in weeks {
            guard let startDate = week.kezdoDatum else { continue }
            let month = calendar.component(.month, from: startDate)

            if monthDict[month] == nil {
                monthDict[month] = []
            }
            monthDict[month]?.append(week)
        }

        // Convert to sorted array of MonthGroups
        let sortedMonths = monthDict.keys.sorted()

        return sortedMonths.map { monthNumber in
            // Get month name
            dateFormatter.dateFormat = "MMMM"
            let monthDate = calendar.date(from: DateComponents(year: selectedYear, month: monthNumber, day: 1))!
            let monthName = dateFormatter.string(from: monthDate)

            return MonthGroup(
                monthName: monthName,
                monthNumber: monthNumber,
                weeks: monthDict[monthNumber]?.sorted { $0.hetSzam < $1.hetSzam } ?? []
            )
        }
    }

    // MARK: - Generate Weeks
    func generateWeeksIfNeeded() {
        let existingWeeks = weeks.filter { $0.ev == selectedYear }

        if existingWeeks.count == 52 {
            return // Already generated
        }

        // Delete existing weeks for this year first
        for week in existingWeeks {
            viewContext.delete(week)
        }

        // Generate 52 weeks
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = Int(selectedYear)
        dateComponents.weekOfYear = 1
        dateComponents.weekday = 2 // Monday

        for weekNumber in 1...52 {
            dateComponents.weekOfYear = weekNumber

            guard let weekStart = calendar.date(from: dateComponents) else { continue }
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }

            let newWeek = NfHet(context: viewContext)
            newWeek.id = UUID()
            newWeek.ev = Int16(selectedYear)
            newWeek.hetSzam = Int16(weekNumber)
            newWeek.kezdoDatum = weekStart
            newWeek.vegDatum = weekEnd
            newWeek.befejezve = false
        }

        do {
            try viewContext.save()
        } catch {
            print("Error generating weeks: \(error)")
        }
    }
}

// MARK: - Week Card Component
struct WeekCard: View {
    let week: NfHet
    let onTap: () -> Void
    let onUpload: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Week info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(week.ev). \(week.hetSzam). hét")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                    if week.befejezve {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Text(formatDateRange(week.kezdoDatum ?? Date(), week.vegDatum ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Status
                if let bizonylatokSet = week.bizonylatokRelation as? Set<NfBizonylat>,
                   !bizonylatokSet.isEmpty {
                    let bizonylatCount = bizonylatokSet.count
                    let itemCount = bizonylatokSet.reduce(0) { $0 + Int($1.osszesTetel) }

                    Text("\(bizonylatCount) bizonylat • \(itemCount) tétel")
                        .font(.caption)
                        .foregroundColor(.lidlBlue)
                } else {
                    Text("Üres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Upload button
            Button(action: onUpload) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.lidlYellow)
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }

    func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "MMM d"

        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)

        return "\(startStr)-\(endStr)"
    }
}
