// NfVisszakuldesView.swift
// Simplified NF visszaküldés view

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct NfVisszakuldesView: View {
    @Binding var selectedType: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NfBizonylat.bizonylatSzam, ascending: true)],
        animation: .default)
    private var bizonylatok: FetchedResults<NfBizonylat>

    @State private var showDocumentPicker = false
    @State private var selectedDocumentURL: URL? = nil
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var successMessage: String? = nil
    @State private var showSuccess = false

    @State private var searchText = ""
    @State private var selectedBizonylat: NfBizonylat? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
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

                Text("NF visszaküldés")
                    .font(.headline)

                Spacer()

                // Placeholder for balance
                Color.clear.frame(width: 80)
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(Divider().background(Color.secondary.opacity(0.3)), alignment: .bottom)

            // Content
            if selectedBizonylat == nil {
                mainView
            } else if let bizonylat = selectedBizonylat {
                NfBizonylatDetailView(
                    bizonylat: bizonylat,
                    onBack: { selectedBizonylat = nil }
                )
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedDocumentURL: $selectedDocumentURL, allowedTypes: [.pdf, .spreadsheet, .commaSeparatedText])
        }
        .onChange(of: selectedDocumentURL) { oldValue, newValue in
            print("🔄 onChange triggered - oldValue: \(String(describing: oldValue?.lastPathComponent)), newValue: \(String(describing: newValue?.lastPathComponent))")
            if let documentURL = newValue {
                processDocument(documentURL: documentURL)
            }
        }
        .alert("Hiba", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Ismeretlen hiba történt")
        }
        .alert("Siker", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage ?? "Dokumentum sikeresen feldolgozva")
        }
    }

    // MARK: - Main View
    var mainView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Upload Button
                uploadButton
                    .padding(.top, 20)
                    .padding(.horizontal)

                // Bizonylatok Section
                if !bizonylatok.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FELDOLGOZOTT BIZONYLATOK")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(bizonylatok, id: \.id) { bizonylat in
                            NfBizonylatCard(bizonylat: bizonylat) {
                                selectedBizonylat = bizonylat
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }

                // Search Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("KERESÉS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // Search Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Cikkszám keresése...", text: $searchText)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Search Results
                    if !searchText.isEmpty {
                        searchResultsView
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Upload Button
    var uploadButton: some View {
        Button(action: { showDocumentPicker = true }) {
            HStack {
                Image(systemName: "doc.badge.plus")
                    .font(.title2)

                Text("Dokumentum feltöltése")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.lidlBlue)
            .cornerRadius(16)
        }
        .disabled(isProcessing)
        .overlay {
            if isProcessing {
                ProgressView()
                    .tint(.white)
            }
        }
    }

    // MARK: - Search Results
    var searchResultsView: some View {
        let allTermekek = bizonylatok.flatMap { bizonylat -> [(NfTermek, NfBizonylat)] in
            guard let termekSet = bizonylat.termekekRelation as? Set<NfTermek> else { return [] }
            return termekSet.map { ($0, bizonylat) }
        }

        let filteredTermekek = allTermekek.filter { termek, _ in
            termek.cikkszam?.contains(searchText) ?? false
        }

        return VStack(spacing: 12) {
            if filteredTermekek.isEmpty {
                Text("Nincs találat")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(filteredTermekek, id: \.0.id) { termek, bizonylat in
                    TermekSearchCard(termek: termek, bizonylat: bizonylat)
                        .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Process Document
    func processDocument(documentURL: URL) {
        print("📄 Starting document processing: \(documentURL.lastPathComponent)")
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                print("🚀 Calling backend API...")
                let claudeTermekek = try await ClaudeAPIService.shared.processNfVisszakuldesDocument(documentURL: documentURL)

                print("✅ Backend returned \(claudeTermekek.count) termékek")

                await MainActor.run {
                    saveToCoreData(claudeTermekek)

                    let bizonylatCount = Set(claudeTermekek.map { $0.bizonylat_szam }).count
                    successMessage = "Sikeresen feldolgozva: \(bizonylatCount) bizonylat, \(claudeTermekek.count) termék"
                    showSuccess = true

                    // Cleanup temp file
                    try? FileManager.default.removeItem(at: documentURL)
                    selectedDocumentURL = nil
                    isProcessing = false

                    print("💾 Saved to Core Data")
                }
            } catch {
                print("❌ Error processing document: \(error)")
                await MainActor.run {
                    errorMessage = "Feldolgozási hiba: \(error.localizedDescription)"
                    showError = true
                    isProcessing = false
                    selectedDocumentURL = nil
                }
            }
        }
    }

    // MARK: - Save to Core Data
    func saveToCoreData(_ claudeTermekek: [NfTermekResponse]) {
        // Group by bizonylat
        var bizonylatGroups: [String: [NfTermekResponse]] = [:]

        for termek in claudeTermekek {
            if bizonylatGroups[termek.bizonylat_szam] == nil {
                bizonylatGroups[termek.bizonylat_szam] = []
            }
            bizonylatGroups[termek.bizonylat_szam]?.append(termek)
        }

        // Create or update bizonylatok
        for (bizonylatSzam, termekek) in bizonylatGroups {
            // Check if bizonylat exists
            let existingBizonylat = bizonylatok.first { $0.bizonylatSzam == bizonylatSzam }

            let bizonylat = existingBizonylat ?? NfBizonylat(context: viewContext)
            if existingBizonylat == nil {
                bizonylat.id = UUID()
                bizonylat.bizonylatSzam = bizonylatSzam
                bizonylat.kesz = false
            }

            // Add termekek
            for (index, termekData) in termekek.enumerated() {
                // Check if termek already exists
                let existingTermek = (bizonylat.termekekRelation as? Set<NfTermek>)?.first {
                    $0.cikkszam == termekData.cikkszam
                }

                let termek = existingTermek ?? NfTermek(context: viewContext)
                if existingTermek == nil {
                    termek.id = UUID()
                    termek.cikkszam = termekData.cikkszam
                    termek.cikkMegnev = termekData.cikk_megnevezes
                    termek.elviKeszlet = Int16(termekData.elvi_keszlet)
                    termek.sorrend = Int16(index)
                    termek.osszesen = 0
                    termek.talalasok = ""
                    termek.osszeszedve = false
                    termek.bizonylat = bizonylat
                }
            }

            bizonylat.osszesTetel = Int16(termekek.count)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error saving: \(error)")
            errorMessage = "Mentési hiba: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - NF Bizonylat Card
struct NfBizonylatCard: View {
    let bizonylat: NfBizonylat
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.lidlBlue)

                    Text("Bizonylat: \(bizonylat.bizonylatSzam ?? "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text("\(bizonylat.osszesTetel) termék")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Progress
                if let termekSet = bizonylat.termekekRelation as? Set<NfTermek> {
                    let osszeszedett = termekSet.filter { $0.osszesen > 0 }.count
                    let total = termekSet.count

                    if osszeszedett > 0 {
                        Text("\(osszeszedett)/\(total) feldolgozva")
                            .font(.caption)
                            .foregroundColor(.green)
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

// MARK: - Termek Search Card
struct TermekSearchCard: View {
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

                HStack {
                    Text("Bizonylat: \(bizonylat.bizonylatSzam ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("Elvi: \(termek.elviKeszlet > 0 ? "\(termek.elviKeszlet) db" : "nincs adat")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Details
            if !talalasokArray.isEmpty {
                Text("Részletek: " + talalasokArray.map { "\($0)" }.joined(separator: " + "))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            // Total (big and centered)
            if osszesen > 0 {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                        Text("ÖSSZESEN: \(osszesen) DB")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.lidlBlue)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.lidlBlue.opacity(0.1))
                .cornerRadius(8)
            }

            // Input
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

                if !mostTalaltam.isEmpty {
                    Button("Mentés") {
                        saveTalalas()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.adaptiveCardBackground(colorScheme: colorScheme).opacity(0.5))
            .cornerRadius(8)
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
