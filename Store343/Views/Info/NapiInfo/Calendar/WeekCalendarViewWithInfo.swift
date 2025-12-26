// WeekCalendarViewWithInfo.swift
// Week calendar with integrated expandable info sections

import SwiftUI
import CoreData

struct WeekCalendarViewWithInfo: View {
    @Binding var selectedDate: Date
    @Binding var expandedDate: Date
    let napiInfos: FetchedResults<NapiInfo>
    let onToggleCalendar: () -> Void
    let onSelectInfo: (NapiInfo) -> Void
    let onAddPhoto: (NapiInfo) -> Void
    let onDeleteInfo: (NapiInfo) -> Void
    let onCreateNew: (Date) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedDateLocal: Date?

    let daysOfWeek = ["H", "K", "Sz", "Cs", "P", "Sz", "V"]

    var body: some View {
        VStack(spacing: 0) {
            // Week days header
            HStack(spacing: 4) {
                ForEach(Array(getWeekDays().enumerated()), id: \.offset) { index, date in
                    dayButton(for: date, dayLetter: daysOfWeek[index])
                }

                // Calendar toggle icon
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
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            // Expandable info sections for each day
            ForEach(getWeekDays(), id: \.self) { date in
                expandableInfoSection(for: date)
            }
        }
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
        let infoCount = getInfosForDate(date).count

        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = date
                expandedDateLocal = Calendar.current.isDate(expandedDateLocal ?? Date(), inSameDayAs: date) ? nil : date
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    Text(dayLetter)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

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
                
                // Info count badge
                if infoCount > 0 {
                    Text("\(infoCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.lidlRed)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
    }

    @ViewBuilder
    private func expandableInfoSection(for date: Date) -> some View {
        let isExpanded = Calendar.current.isDate(expandedDateLocal ?? Date(), inSameDayAs: date)
        let infos = getInfosForDate(date)
        
        if isExpanded {
            VStack(alignment: .leading, spacing: 12) {
                // Date header
                HStack {
                    Text(formatDateWithWeekday(date))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if infos.count > 0 {
                        Text("\(infos.count) téma")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Info list or empty state
                if infos.isEmpty {
                    // Empty state - big button
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("Nincs információ")
                            .font(.title3)
                            .fontWeight(.medium)

                        Button(action: {
                            onCreateNew(date)
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Fotó feltöltése")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.lidlBlue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Info list
                    ForEach(infos, id: \.objectID) { info in
                        Button(action: {
                            onSelectInfo(info)
                        }) {
                            NapiInfoListItem(info: info, onAddPhoto: {
                                onAddPhoto(info)
                            })
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                onDeleteInfo(info)
                            } label: {
                                Label("Törlés", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Add more pages button
                    if let firstInfo = infos.first {
                        Button(action: {
                            onAddPhoto(firstInfo)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Újabb oldal hozzáadása")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.lidlBlue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.lidlBlue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 16)
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value) {
        let calendar = Calendar.current
        if gesture.translation.width < -30 {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                    expandedDateLocal = nil
                }
            }
        } else if gesture.translation.width > 30 {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                withAnimation {
                    selectedDate = newDate
                    expandedDateLocal = nil
                }
            }
        }
    }

    private func getWeekDays() -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
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

    private func getInfosForDate(_ date: Date) -> [NapiInfo] {
        let calendar = Calendar.current
        return napiInfos.filter { info in
            guard let infoDate = info.datum else { return false }
            return calendar.isDate(infoDate, inSameDayAs: date)
        }
    }
    
    private func formatDateWithWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "MMMM d., EEEE"
        return formatter.string(from: date)
    }
}
