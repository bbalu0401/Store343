// BeosztasView.swift
// Employee scheduling view with daily shift list

import SwiftUI
import Combine

struct BeosztasView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = BeosztasViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with date navigation
                VStack(spacing: 8) {
                    // Date navigation
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.lidlBlue)
                                .frame(width: 44, height: 44)
                        }

                        VStack(spacing: 4) {
                            Text(formatDateFull(selectedDate))
                                .font(.title3)
                                .fontWeight(.medium)

                            if Calendar.current.isDateInToday(selectedDate) {
                                Text("Ma")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.lidlYellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                            } else {
                                Text("\(getWeekNumber(for: selectedDate)) hét")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.lidlBlue)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Quick "Today" button
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedDate = Date()
                            }
                        }) {
                            Text("Vissza mára")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.lidlBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.lidlBlue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 16)
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                .overlay(
                    Divider()
                        .background(Color.secondary.opacity(0.3)),
                    alignment: .bottom
                )

                // Shifts list
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        let shifts = viewModel.getShiftsForDate(selectedDate)

                        if !shifts.isEmpty {
                            Text("\(shifts.count) munkavállaló")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom, 12)

                            ForEach(shifts) { shift in
                                ShiftRowView(shift: shift, colorScheme: colorScheme)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            }
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.top, 60)

                                Text("Nincs beosztás")
                                    .font(.title3)
                                    .fontWeight(.medium)

                                Text("Erre a napra még nem került beosztás.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { gesture in
                            handleDaySwipe(gesture)
                        }
                )
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .navigationBarTitle("Beosztás", displayMode: .inline)
        }
    }

    // MARK: - Helper Functions

    func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM d., EEEE"
        return formatter.string(from: date)
    }

    func getWeekNumber(for date: Date) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        return calendar.component(.weekOfYear, from: date)
    }

    func handleDaySwipe(_ gesture: DragGesture.Value) {
        let calendar = Calendar.current

        if gesture.translation.width < -50 {
            // Swipe left → next day
            if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = newDate
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } else if gesture.translation.width > 50 {
            // Swipe right → previous day
            if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = newDate
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Shift Row Component
struct ShiftRowView: View {
    let shift: Muszak
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Time display
            VStack(alignment: .leading, spacing: 4) {
                Text(shift.idotartam)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.lidlBlue)

                Text(getDuration())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Employee name
            Text(shift.munkavallaloNev)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    func getDuration() -> String {
        let duration = shift.veg.timeIntervalSince(shift.kezdes)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if minutes == 0 {
            return "\(hours) óra"
        } else {
            return "\(hours) óra \(minutes) perc"
        }
    }
}

// MARK: - ViewModel
class BeosztasViewModel: ObservableObject {
    @Published var osszesMuszak: [Muszak] = []

    init() {
        // TODO: Load from API
        // For now, empty array - no mock data
        self.osszesMuszak = []
    }

    func getShiftsForDate(_ date: Date) -> [Muszak] {
        return BeosztasHelper.napiBeosztasok(osszesMuszak: osszesMuszak, datum: date)
    }
}
