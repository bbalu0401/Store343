// WeekCalendarView.swift
// Week view with 7 days (Mon-Sun)

import SwiftUI
import CoreData

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let napiInfos: FetchedResults<NapiInfo>
    let onToggleCalendar: () -> Void
    @Environment(\.colorScheme) var colorScheme

    let daysOfWeek = ["H", "K", "Sz", "Cs", "P", "Sz", "V"]

    var body: some View {
        VStack(spacing: 0) {
            // Week days with day labels INSIDE
            HStack(spacing: 4) {
                ForEach(Array(getWeekDays().enumerated()), id: \.offset) { index, date in
                    dayButton(for: date, dayLetter: daysOfWeek[index])
                }

                // Calendar toggle icon (8th column)
                Button(action: onToggleCalendar) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.lidlBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.lidlBlue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { gesture in
                    handleSwipe(gesture)
                }
        )
    }

    @ViewBuilder
    private func dayButton(for date: Date, dayLetter: String) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)

        Button(action: {
            selectedDate = date
        }) {
            VStack(spacing: 2) {
                // Day letter at top
                Text(dayLetter)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

                // Date number below
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : Color.adaptiveText(colorScheme: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isSelected ? Color.lidlBlue : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday && !isSelected ? Color.lidlBlue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value) {
        let calendar = Calendar.current
        if gesture.translation.width < -30 {
            // Swipe left - next week
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        } else if gesture.translation.width > 30 {
            // Swipe right - previous week
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }

    private func getWeekDays() -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday (1 = Sunday, 2 = Monday)
        var weekDays: [Date] = []

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                weekDays.append(date)
            }
        }

        return weekDays
    }
}
