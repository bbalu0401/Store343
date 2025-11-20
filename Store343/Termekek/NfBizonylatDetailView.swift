// NfBizonylatDetailView.swift
// Detailed view for a single bizonylat showing all termékek

import SwiftUI
import CoreData

struct NfBizonylatDetailView: View {
    let bizonylat: NfBizonylat
    let onBack: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var termekek: [NfTermek] {
        guard let termekSet = bizonylat.termekekRelation as? Set<NfTermek> else { return [] }
        return termekSet.sorted { $0.sorrend < $1.sorrend }
    }

    var osszesTermekMennyiseg: Int {
        termekek.reduce(0) { $0 + Int($1.osszesen) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Vissza")
                    }
                    .foregroundColor(.lidlBlue)
                }

                Spacer()

                Text("NF visszaküldés")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 80)
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(Divider().background(Color.secondary.opacity(0.3)), alignment: .bottom)

            // Content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bizonylat szám")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(bizonylat.bizonylatSzam ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()
                    }

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Termékek")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(bizonylat.osszesTetel)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Divider()
                            .frame(height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Feldolgozva")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            let feldolgozott = termekek.filter { $0.osszesen > 0 }.count
                            Text("\(feldolgozott)/\(termekek.count)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(feldolgozott == termekek.count ? .green : .orange)
                        }

                        Divider()
                            .frame(height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Összesen")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(osszesTermekMennyiseg) db")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.lidlBlue)
                        }
                    }
                }
                .padding()
                .background(Color.adaptiveCardBackground(colorScheme: colorScheme))

                // Termékek List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(termekek, id: \.id) { termek in
                            TermekDetailCard(termek: termek, bizonylat: bizonylat)
                                .padding(.horizontal)
                        }

                        Color.clear.frame(height: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
    }
}

// MARK: - Termek Detail Card
struct TermekDetailCard: View {
    let termek: NfTermek
    let bizonylat: NfBizonylat
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @State private var mostTalaltam: String = ""
    @FocusState private var isFocused: Bool

    var talalasokArray: [Int16] {
        guard let talalasok = termek.talalasok, !talalasok.isEmpty else { return [] }
        return talalasok.split(separator: ",").compactMap { Int16($0.trimmingCharacters(in: .whitespaces)) }
    }

    var osszesen: Int16 {
        talalasokArray.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(termek.cikkszam ?? "")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(termek.cikkMegnev ?? "")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if termek.elviKeszlet > 0 {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Elvi készlet: \(termek.elviKeszlet) db")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Elvi készlet: nincs adat")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Divider()

            // Details Section
            if !talalasokArray.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Részletek:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(talalasokArray.map { "\($0)" }.joined(separator: " + "))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }

            // Total (big and centered)
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title3)
                    Text("ÖSSZESEN: \(osszesen) DB")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(osszesen > 0 ? .lidlBlue : .secondary)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(osszesen > 0 ? Color.lidlBlue.opacity(0.1) : Color.secondary.opacity(0.05))
            .cornerRadius(8)

            // Input Section
            VStack(spacing: 8) {
                HStack {
                    Text("+")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    TextField("Most találtam", text: $mostTalaltam)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .font(.subheadline)

                    Text("db")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                .cornerRadius(8)

                if !mostTalaltam.isEmpty {
                    Button(action: saveTalalas) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mentés")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func saveTalalas() {
        guard let mennyiseg = Int16(mostTalaltam), mennyiseg > 0 else { return }

        // Add to talalasok
        var currentTalalasok = termek.talalasok ?? ""
        if !currentTalalasok.isEmpty {
            currentTalalasok += ","
        }
        currentTalalasok += "\(mennyiseg)"

        termek.talalasok = currentTalalasok
        termek.osszesen = osszesen + mennyiseg

        do {
            try viewContext.save()
            mostTalaltam = ""
            isFocused = false
        } catch {
            print("Error saving: \(error)")
        }
    }
}
