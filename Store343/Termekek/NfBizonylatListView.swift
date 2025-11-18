// NfBizonylatListView.swift
// List of bizonyláts within a selected week

import SwiftUI
import CoreData

struct NfBizonylatListView: View {
    let week: NfHet
    let onBack: () -> Void
    let onAddPages: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedBizonylat: NfBizonylat? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("\(week.ev). \(week.hetSzam). hét")
                    }
                    .foregroundColor(.lidlBlue)
                }

                Spacer()

                Button(action: onAddPages) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.lidlYellow)
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
            if selectedBizonylat == nil {
                bizonylatListView
            } else if let bizonylat = selectedBizonylat {
                // Navigate to product list
                NfTermekListView(
                    bizonylat: bizonylat,
                    onBack: {
                        selectedBizonylat = nil
                    }
                )
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
    }

    // MARK: - Bizonylat List View
    var bizonylatListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let bizonylatokSet = week.bizonylatokRelation as? Set<NfBizonylat> {
                    let bizonylatArray = bizonylatokSet.sorted { $0.bizonylatSzam ?? "" < $1.bizonylatSzam ?? "" }

                    if bizonylatArray.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("Nincs bizonylat")
                                .font(.title3)
                                .fontWeight(.medium)

                            Text("Nyomd meg a + gombot dokumentumok feltöltéséhez.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(bizonylatArray, id: \.id) { bizonylat in
                            BizonylatCard(bizonylat: bizonylat, onTap: {
                                selectedBizonylat = bizonylat
                            })
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
    }
}

// MARK: - Bizonylat Card Component
struct BizonylatCard: View {
    let bizonylat: NfBizonylat
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Bizonylat info
            VStack(alignment: .leading, spacing: 4) {
                Text("Bizonylat: \(bizonylat.bizonylatSzam ?? "N/A")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                Text("\(bizonylat.osszesTetel) tétel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Progress indicator
                if let termekekSet = bizonylat.termekekRelation as? Set<NfTermek> {
                    let collectedCount = termekekSet.filter { $0.osszeszedve }.count
                    let totalCount = termekekSet.count

                    HStack(spacing: 8) {
                        Text("Progress:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Progress dots
                        HStack(spacing: 4) {
                            ForEach(0..<min(totalCount, 10), id: \.self) { index in
                                Circle()
                                    .fill(index < collectedCount ? Color.lidlBlue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }

                            if totalCount > 10 {
                                Text("...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("\(collectedCount)/\(totalCount)")
                            .font(.caption)
                            .foregroundColor(collectedCount == totalCount ? .green : .secondary)

                        if collectedCount == totalCount && totalCount > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
}
