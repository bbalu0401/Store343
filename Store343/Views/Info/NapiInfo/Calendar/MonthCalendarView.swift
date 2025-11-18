// MonthCalendarView.swift
// Month grid view

import SwiftUI
import CoreData

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var calendarView: NapiInfoMainView.CalendarViewType
    let napiInfos: FetchedResults<NapiInfo>
    @Environment(\.colorScheme) var colorScheme
    
    let daysOfWeek = ["H", "K", "Sz", "Cs", "P", "Sz", "V"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month/Year header
                HStack {
                    Button(action: {
                        calendarView = .year
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(String(format: "%d.", Calendar.current.component(.year, from: selectedDate)))
                                .kerning(-0.5)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text(getMonthName())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 80)
                }
                .padding(.horizontal)
                
                // Day names
                HStack(spacing: 4) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Month grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(getMonthDays(), id: \.self) { date in
                        if let date = date {
                            let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            let isToday = Calendar.current.isDateInToday(date)
                            
                            Button(action: {
                                selectedDate = date
                                calendarView = .week
                            }) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 16))
                                    .foregroundColor(isSelected ? .white : Color.adaptiveText(colorScheme: colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(isSelected ? Color.lidlBlue : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isToday && !isSelected ? Color.lidlBlue : Color.clear, lineWidth: 2)
                                    )
                                    .cornerRadius(8)
                            }
                        } else {
                            Color.clear.frame(height: 44)
                        }
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
                        // Swipe left - next month
                        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    } else if gesture.translation.width > 30 {
                        // Swipe right - previous month
                        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
                }
        )
    }
    
    func getMonthName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedDate).capitalized
    }
    
    func getMonthDays() -> [Date?] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        
        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }
        
        let firstWeekday = (calendar.component(.weekday, from: firstDay) + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }
        
        return days
    }
}
