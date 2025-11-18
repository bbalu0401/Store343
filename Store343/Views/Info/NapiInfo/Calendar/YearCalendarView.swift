// YearCalendarView.swift
// Year overview with 12 months

import SwiftUI

struct YearCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var calendarView: NapiInfoMainView.CalendarViewType
    @Environment(\.colorScheme) var colorScheme
    
    let monthNames = ["Jan.", "Febr.", "Márc.", "Ápr.", "Máj.", "Jún.", "Júl.", "Aug.", "Sept.", "Okt.", "Nov.", "Dec."]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text(String(format: "%d.", Calendar.current.component(.year, from: selectedDate)))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.lidlBlue)
                        .kerning(-0.5)

                    Rectangle()
                        .fill(Color.lidlYellow)
                        .frame(width: 4, height: 36)
                        .cornerRadius(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(0..<12, id: \.self) { month in
                        MonthMiniCard(
                            monthName: monthNames[month],
                            monthIndex: month,
                            selectedDate: $selectedDate,
                            calendarView: $calendarView
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { gesture in
                    let calendar = Calendar.current
                    if gesture.translation.width < -30 {
                        // Swipe left - next year
                        if let newDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    } else if gesture.translation.width > 30 {
                        // Swipe right - previous year
                        if let newDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
                }
        )
    }
}

// MARK: - Month Mini Card
struct MonthMiniCard: View {
    let monthName: String
    let monthIndex: Int
    @Binding var selectedDate: Date
    @Binding var calendarView: NapiInfoMainView.CalendarViewType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            let calendar = Calendar.current
            let year = calendar.component(.year, from: selectedDate)
            if let newDate = calendar.date(from: DateComponents(year: year, month: monthIndex + 1, day: 1)) {
                selectedDate = newDate
                calendarView = .month
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(monthName)
                    .font(.subheadline)
                    .fontWeight(isCurrentMonth ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? .lidlRed : Color.adaptiveText(colorScheme: colorScheme))
                
                // Mini calendar preview
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                    ForEach(0..<28, id: \.self) { day in
                        Text("\(day + 1)")
                            .font(.system(size: 6))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
            .cornerRadius(12)
        }
    }
    
    var isCurrentMonth: Bool {
        Calendar.current.component(.month, from: selectedDate) == monthIndex + 1
    }
}
