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
        sortDescriptors: [NSSortDescriptor(keyPath: \NfHet.hetSzam, ascending: true)],
        animation: .default)
    private var hetek: FetchedResults<NfHet>

    @State private var showDocumentPicker = false
    @State private var selectedDocumentURL: URL? = nil
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var successMessage: String? = nil
    @State private var showSuccess = false

    @State private var searchText = ""
    @State private var selectedBizonylat: NfBizonylat? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var selectedWeek: Int = 0 // Current week number (1-52)

    // MARK: - Computed Properties

    /// Get current NfHet for selected week, or nil if doesn't exist yet
    private var currentHet: NfHet? {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        calendar.minimumDaysInFirstWeek = 4 // ISO 8601

        let currentYear = calendar.component(.year, from: Date())
        return hetek.first { $0.hetSzam == selectedWeek && $0.ev == currentYear }
    }

    /// Bizonylatok for the selected week only
    private var filteredBizonylatok: [NfBizonylat] {
        guard let het = currentHet else { return [] }
        return (het.bizonylatokRelation as? Set<NfBizonylat>)?.sorted { ($0.bizonylatSzam ?? "") < ($1.bizonylatSzam ?? "") } ?? []
    }

    /// Get date range string for selected week
    private func getWeekDateRange() -> String {
        // Prevent crash if week not set yet
        guard selectedWeek > 0 && selectedWeek <= 52 else {
            return ""
        }

        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        calendar.minimumDaysInFirstWeek = 4 // ISO 8601

        let currentYear = Calendar.current.component(.year, from: Date())

        // Find a date that is definitely in the selected week of the current year
        // Start from middle of the year and search
        guard let midYear = calendar.date(from: DateComponents(year: currentYear, month: 7, day: 1)) else {
            return ""
        }

        // Search for the correct week
        var searchDate = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 4))! // First Thursday
        var foundWeek = calendar.component(.weekOfYear, from: searchDate)

        // Safety counter to prevent infinite loop
        var iterations = 0
        let maxIterations = 60

        // Navigate to the target week
        while foundWeek < selectedWeek && iterations < maxIterations {
            searchDate = calendar.date(byAdding: .weekOfYear, value: 1, to: searchDate)!
            foundWeek = calendar.component(.weekOfYear, from: searchDate)
            iterations += 1
        }

        iterations = 0 // Reset for second loop

        while foundWeek > selectedWeek && iterations < maxIterations {
            searchDate = calendar.date(byAdding: .weekOfYear, value: -1, to: searchDate)!
            foundWeek = calendar.component(.weekOfYear, from: searchDate)
            iterations += 1
        }

        // Get the week interval
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: searchDate) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "MM.dd"

        return "\(formatter.string(from: weekInterval.start))-\(formatter.string(from: weekInterval.end.addingTimeInterval(-1)))"
    }

    var body: some View {
        ZStack {
            if selectedBizonylat == nil {
                VStack(spacing: 0) {
                    // Navigation Bar (csak lista nézetben!)
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
                    }
                    .padding()
                    .background(Color.adaptiveBackground(colorScheme: colorScheme))
                    .overlay(Divider().background(Color.secondary.opacity(0.3)), alignment: .bottom)

                    mainView
                }
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                .navigationBarHidden(true)
            }

            if let bizonylat = selectedBizonylat {
                NfBizonylatDetailView(
                    bizonylat: bizonylat,
                    onBack: { selectedBizonylat = nil }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(
                selectedDocumentURL: $selectedDocumentURL,
                allowedTypes: [
                    UTType(filenameExtension: "xlsx")!,
                    UTType(filenameExtension: "xls")!,
                    .commaSeparatedText
                ]
            )
        }
        .task(id: selectedDocumentURL) {
            print("🟢 [NF] task(id:) triggered! selectedDocumentURL: \(selectedDocumentURL?.lastPathComponent ?? "nil")")
            print("🟢 [NF] showDocumentPicker: \(showDocumentPicker)")

            guard let documentURL = selectedDocumentURL else {
                print("⚠️ [NF] No document URL to process")
                return
            }

            print("🟢 [NF] Dismissing sheet and calling processDocument...")
            await MainActor.run {
                showDocumentPicker = false
            }

            print("🟢 [NF] About to call processDocument with file: \(documentURL.lastPathComponent)")
            processDocument(documentURL: documentURL)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Kész") {
                    isSearchFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            // Set to current week on first appear using ISO 8601
            if selectedWeek == 0 {
                var calendar = Calendar.current
                calendar.firstWeekday = 2 // Monday
                calendar.minimumDaysInFirstWeek = 4 // ISO 8601
                selectedWeek = calendar.component(.weekOfYear, from: Date())
            }
        }
    }

    // MARK: - Main View
    var mainView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Week Navigation Header
                weekPickerView
                    .padding(.horizontal)
                    .padding(.top, 12)

                // Upload Button
                uploadButton
                    .padding(.horizontal)

                // Bizonylatok Section
                if !filteredBizonylatok.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FELDOLGOZOTT BIZONYLATOK (\(selectedWeek). hét)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(filteredBizonylatok, id: \.id) { bizonylat in
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
                            .focused($isSearchFocused)
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

    // MARK: - Week Picker View
    var weekPickerView: some View {
        HStack(spacing: 16) {
            // Previous week button
            Button(action: {
                if selectedWeek > 1 {
                    selectedWeek -= 1
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(selectedWeek > 1 ? .lidlBlue : .gray)
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedWeek <= 1)

            // Week display
            VStack(spacing: 4) {
                Text("\(selectedWeek). hét")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(getWeekDateRange())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Next week button
            Button(action: {
                if selectedWeek < 52 {
                    selectedWeek += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(selectedWeek < 52 ? .lidlBlue : .gray)
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedWeek >= 52)
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
    }

    // MARK: - Upload Button
    var uploadButton: some View {
        Button(action: {
            showDocumentPicker = true
        }) {
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
        // Only search in current week's bizonylatok
        let allTermekek = filteredBizonylatok.flatMap { bizonylat -> [(NfTermek, NfBizonylat)] in
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
                    TermekSearchCard(
                        termek: termek,
                        bizonylat: bizonylat,
                        onSave: {
                            // Clear search and jump back to search field
                            searchText = ""

                            // Small delay to ensure view updates before refocusing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isSearchFocused = true
                            }
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Process Document
    func processDocument(documentURL: URL) {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let claudeTermekek = try await ClaudeAPIService.shared.processNfVisszakuldesDocument(documentURL: documentURL)

                await MainActor.run {
                    saveToCoreData(claudeTermekek)

                    let bizonylatCount = Set(claudeTermekek.map { $0.bizonylat_szam }).count
                    successMessage = "Sikeresen feldolgozva: \(bizonylatCount) bizonylat, \(claudeTermekek.count) termék"
                    showSuccess = true

                    // Cleanup temp file
                    try? FileManager.default.removeItem(at: documentURL)
                    selectedDocumentURL = nil
                    isProcessing = false
                }
            } catch {
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
        // Get or create NfHet for selected week
        let currentYear = Int16(Calendar.current.component(.year, from: Date()))
        let het = getOrCreateHet(weekNumber: Int16(selectedWeek), year: currentYear)

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
            // Check if bizonylat exists in current week
            let existingBizonylat = filteredBizonylatok.first { $0.bizonylatSzam == bizonylatSzam }

            let bizonylat = existingBizonylat ?? NfBizonylat(context: viewContext)
            if existingBizonylat == nil {
                bizonylat.id = UUID()
                bizonylat.bizonylatSzam = bizonylatSzam
                bizonylat.kesz = false
                bizonylat.het = het // Assign to selected week
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

    // MARK: - Helper Functions

    /// Get or create NfHet for given week number and year
    private func getOrCreateHet(weekNumber: Int16, year: Int16) -> NfHet {
        // Check if het already exists
        if let existingHet = hetek.first(where: { $0.hetSzam == weekNumber && $0.ev == year }) {
            return existingHet
        }

        // Create new het
        let newHet = NfHet(context: viewContext)
        newHet.id = UUID()
        newHet.hetSzam = weekNumber
        newHet.ev = year
        newHet.befejezve = false

        // Calculate start and end dates for this week using ISO 8601
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        calendar.minimumDaysInFirstWeek = 4 // ISO 8601

        // Validate week number
        guard weekNumber > 0 && weekNumber <= 53 else {
            // Invalid week number, use current date as fallback
            newHet.kezdoDatum = Date()
            newHet.vegDatum = Date()
            return newHet
        }

        // Find a date in the target week
        // Start from first Thursday of the year (guaranteed to be in week 1)
        var searchDate = calendar.date(from: DateComponents(year: Int(year), month: 1, day: 4))! // First Thursday
        var foundWeek = calendar.component(.weekOfYear, from: searchDate)

        // Safety counter to prevent infinite loop
        var iterations = 0
        let maxIterations = 60

        // Navigate to the target week
        while foundWeek < weekNumber && iterations < maxIterations {
            searchDate = calendar.date(byAdding: .weekOfYear, value: 1, to: searchDate)!
            foundWeek = calendar.component(.weekOfYear, from: searchDate)
            iterations += 1
        }

        iterations = 0 // Reset for second loop

        while foundWeek > weekNumber && iterations < maxIterations {
            searchDate = calendar.date(byAdding: .weekOfYear, value: -1, to: searchDate)!
            foundWeek = calendar.component(.weekOfYear, from: searchDate)
            iterations += 1
        }

        // Get the week interval (Monday to Sunday)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: searchDate) else {
            // Fallback
            newHet.kezdoDatum = Date()
            newHet.vegDatum = Date()
            return newHet
        }

        newHet.kezdoDatum = weekInterval.start
        newHet.vegDatum = weekInterval.end.addingTimeInterval(-1) // End is exclusive, so subtract 1 second

        return newHet
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
    let onSave: () -> Void
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

            // Details with delete buttons
            if !talalasokArray.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Részletek:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Show each quantity entry with delete button
                    ForEach(Array(talalasokArray.enumerated()), id: \.offset) { index, mennyiseg in
                        HStack(spacing: 8) {
                            Text("\(mennyiseg) db")
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                deleteTalalas(at: index)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                    Text("Törlés")
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.adaptiveCardBackground(colorScheme: colorScheme).opacity(0.5))
                        .cornerRadius(8)
                    }
                }
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
            onSave() // Clear search and jump back to search field
        } catch {
            print("Error saving: \(error)")
        }
    }

    func deleteTalalas(at index: Int) {
        var array = talalasokArray
        guard index < array.count else { return }

        // Remove the item at index
        array.remove(at: index)

        // Update termek
        termek.talalasok = array.map { String($0) }.joined(separator: ",")
        termek.osszesen = array.reduce(0, +)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting talalas: \(error)")
        }
    }
}

