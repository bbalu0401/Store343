// NapiInfoMainView.swift
// Main Napi Info screen with calendar views and info list

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct NapiInfoMainView: View {
    @Binding var selectedInfoType: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NapiInfo.datum, ascending: true)],
        animation: .default)
    private var napiInfos: FetchedResults<NapiInfo>
    
    @State private var selectedDate = Date()
    @State private var calendarView: CalendarViewType = .week
    @State private var selectedInfo: NapiInfo? = nil
    @State private var showDocumentPicker = false
    @State private var selectedDocumentURL: URL? = nil
    @State private var processingOCR = false
    @State private var selectedInfoForUpload: NapiInfo? = nil
    @State private var infoToDelete: NapiInfo? = nil
    @State private var showDeleteConfirmation = false

    enum CalendarViewType {
        case week, month, year
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: {
                    selectedInfoType = nil
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Vissza")
                    }
                    .foregroundColor(.lidlBlue)
                }
                
                Spacer()
                
                Text("Napi Infó")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(
                Divider()
                    .background(Color.secondary.opacity(0.3)),
                alignment: .bottom
            )
            
            if selectedInfo == nil {
                // Date header
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatDateFull(selectedDate))
                        .font(.title3)
                        .fontWeight(.light)

                    Text("\(getWeekNumber()) hét")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.lidlYellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 4)
                .background(Color.adaptiveBackground(colorScheme: colorScheme))

                // Calendar View
                VStack(spacing: 0) {
                    switch calendarView {
                    case .week:
                        WeekCalendarView(
                            selectedDate: $selectedDate,
                            napiInfos: napiInfos,
                            onToggleCalendar: toggleCalendarView
                        )
                    case .month:
                        MonthCalendarView(
                            selectedDate: $selectedDate,
                            calendarView: $calendarView,
                            napiInfos: napiInfos
                        )
                    case .year:
                        YearCalendarView(
                            selectedDate: $selectedDate,
                            calendarView: $calendarView
                        )
                    }
                }
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                .overlay(
                    Divider()
                        .background(Color.secondary.opacity(0.3)),
                    alignment: .bottom
                )
                
                // Info list for selected date
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(formatDateWithWeekday(selectedDate))
                            .font(.title2)
                            .fontWeight(.light)
                            .padding(.horizontal)
                            .padding(.top)

                        let infoCount = getInfosForDate(selectedDate).count
                        if infoCount > 0 {
                            let pageCount = getPageCount(for: selectedDate)
                            if pageCount > 0 {
                                Text("\(pageCount) oldal")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.lidlBlue)
                                    .padding(.horizontal)
                            }
                        }

                        Text("Kattints a dokumentumra a részletekért")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(getInfosForDate(selectedDate), id: \.objectID) { info in
                            Button(action: {
                                // Only open detail view if processed
                                if info.feldolgozva {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedInfo = info
                                    }
                                }
                            }) {
                                NapiInfoListItem(info: info, onAddPhoto: {
                                    // Add new PDF page to this document
                                    selectedInfoForUpload = info
                                    showDocumentPicker = true
                                })
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    infoToDelete = info
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Törlés", systemImage: "trash")
                                }
                            }
                        }

                        if getInfosForDate(selectedDate).isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("Nincs információ")
                                    .font(.title3)
                                    .fontWeight(.medium)

                                Text("Erre a napra még nem került feltöltésre napi infó.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                Button(action: {
                                    // Create new document and show PDF picker directly
                                    let existingDocs = getInfosForDate(selectedDate)
                                    if let existingInfo = existingDocs.first {
                                        selectedInfoForUpload = existingInfo
                                    } else {
                                        let newInfo = NapiInfo(context: viewContext)
                                        newInfo.datum = selectedDate
                                        newInfo.feldolgozva = false
                                        newInfo.oldalSzam = 0
                                        newInfo.tema = nil
                                        newInfo.erintett = nil
                                        newInfo.tartalom = nil
                                        try? viewContext.save()
                                        selectedInfoForUpload = newInfo
                                    }
                                    showDocumentPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "doc.fill")
                                        Text("PDF feltöltése")
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
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { gesture in
                            handleDaySwipe(gesture)
                        }
                )
            } else {
                // Detail view
                NapiInfoDetailView(info: selectedInfo!, onBack: {
                    selectedInfo = nil
                })
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedDocumentURL: $selectedDocumentURL, allowedTypes: [.pdf])
        }
        .onChange(of: selectedDocumentURL) { oldValue, newValue in
            if let documentURL = newValue, let info = selectedInfoForUpload {
                processDocument(documentURL: documentURL, for: info)
            }
        }
        .alert("Dokumentum törlése", isPresented: $showDeleteConfirmation) {
            Button("Mégse", role: .cancel) {
                infoToDelete = nil
            }
            Button("Törlés", role: .destructive) {
                if let info = infoToDelete {
                    deleteInfo(info)
                }
                infoToDelete = nil
            }
        } message: {
            Text("Biztosan törölni szeretnéd ezt a dokumentumot? Ez a művelet nem vonható vissza.")
        }
        .overlay(
            Group {
                if processingOCR {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .lidlYellow))

                            Text("Claude AI feldolgozás...")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Dokumentum elemzése folyamatban")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(30)
                        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
                        .cornerRadius(20)
                    }
                }
            }
        )
        .onAppear {
            cleanupDuplicateNapiInfos()
        }
    }

    // MARK: - Cleanup Functions

    func cleanupDuplicateNapiInfos() {
        let calendar = Calendar.current

        // Group NapiInfos by date
        var infosByDate: [Date: [NapiInfo]] = [:]

        for info in napiInfos {
            guard let datum = info.datum else { continue }

            // Normalize date to start of day
            let startOfDay = calendar.startOfDay(for: datum)

            if infosByDate[startOfDay] == nil {
                infosByDate[startOfDay] = []
            }
            infosByDate[startOfDay]?.append(info)
        }

        // For each date, keep only ONE NapiInfo
        for (date, infos) in infosByDate {
            // If there's only one, skip
            guard infos.count > 1 else {
                // Reset oldalSzam to 1 for single entries
                if let info = infos.first {
                    info.oldalSzam = 1
                }
                continue
            }

            // Sort by oldalSzam (keep the one with smallest oldalSzam, likely the first)
            let sortedInfos = infos.sorted { ($0.oldalSzam) < ($1.oldalSzam) }

            // Keep the first one (smallest oldalSzam)
            if let keepInfo = sortedInfos.first {
                keepInfo.oldalSzam = 1 // Reset to 1

                // Delete all others
                for info in sortedInfos.dropFirst() {
                    viewContext.delete(info)
                }
            }
        }

        // Save changes
        try? viewContext.save()
    }

    // MARK: - Helper Functions
    
    func toggleCalendarView() {
        switch calendarView {
        case .week:
            calendarView = .month
        case .month:
            calendarView = .year
        case .year:
            calendarView = .week
        }
    }
    
    func getInfosForDate(_ date: Date) -> [NapiInfo] {
        let calendar = Calendar.current
        return napiInfos.filter { info in
            calendar.isDate(info.datum ?? Date(), inSameDayAs: date)
        }
    }

    func getPageCount(for date: Date) -> Int {
        let infos = getInfosForDate(date)

        guard let info = infos.first else { return 0 }

        // Count unique pageNumbers from JSON blocks
        guard let jsonString = info.termekLista,
              let jsonData = jsonString.data(using: .utf8),
              let blocks = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            return 0
        }

        let pageNumbers = Set(blocks.compactMap { $0["pageNumber"] as? Int })
        return pageNumbers.count
    }
    
    func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM d., EEEE"
        return formatter.string(from: date)
    }
    
    func formatDateWithWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM d. – EEEE"
        return formatter.string(from: date)
    }
    
    func getWeekNumber() -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday (same as WeekCalendarView)
        return calendar.component(.weekOfYear, from: selectedDate)
    }

    func getCalendarIcon() -> String {
        switch calendarView {
        case .week:
            return "calendar.day.timeline.left"
        case .month:
            return "calendar"
        case .year:
            return "calendar.badge.clock"
        }
    }

    // MARK: - Day Swipe Navigation
    func handleDaySwipe(_ gesture: DragGesture.Value) {
        let calendar = Calendar.current

        if gesture.translation.width < -50 {
            // Swipe left → next day
            if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = newDate
                }
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } else if gesture.translation.width > 50 {
            // Swipe right → previous day
            if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = newDate
                }
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }

    // MARK: - OCR Processing (Claude API)
    func processOCR(image: UIImage, for info: NapiInfo) {
        processingOCR = true

        Task {
            do {
                // Call Claude API for accurate OCR
                let blocks = try await ClaudeAPIService.shared.processNapiInfo(image: image)

                // Update UI on main thread
                await MainActor.run {
                    // Convert Claude API blocks to our internal format with Hungarian text corrections
                    let ocrBlocks = blocks.map { block -> NapiInfoBlock in
                        return NapiInfoBlock(
                            tema: ClaudeAPIService.correctHungarianText(block.tema),
                            erintett: ClaudeAPIService.correctHungarianText(block.erintett),
                            hatarido: block.hatarido.map { ClaudeAPIService.correctHungarianText($0) },
                            tartalom: ClaudeAPIService.correctHungarianText(block.tartalom),
                            termekLista: nil, // Claude doesn't parse products separately
                            index: 0
                        )
                    }

                    // Store ALL info blocks within ONE document
                    updateNapiInfoFromMultipleBlocks(info, blocks: ocrBlocks)

                    try? viewContext.save()

                    processingOCR = false
                    selectedInfoForUpload = nil

                    // Show detail view after processing
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedInfo = info
                    }
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    processingOCR = false
                    selectedInfoForUpload = nil

                    // Show error to user
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Document Processing (Claude API)
    func processDocument(documentURL: URL, for info: NapiInfo) {
        processingOCR = true

        Task {
            do {
                // Call Claude API for document processing
                let blocks = try await ClaudeAPIService.shared.processNapiInfoDocument(documentURL: documentURL)

                // Update UI on main thread
                await MainActor.run {
                    // Convert Claude API blocks to our internal format with Hungarian text corrections
                    let ocrBlocks = blocks.map { block -> NapiInfoBlock in
                        return NapiInfoBlock(
                            tema: ClaudeAPIService.correctHungarianText(block.tema),
                            erintett: ClaudeAPIService.correctHungarianText(block.erintett),
                            hatarido: block.hatarido.map { ClaudeAPIService.correctHungarianText($0) },
                            tartalom: ClaudeAPIService.correctHungarianText(block.tartalom),
                            termekLista: nil,
                            index: 0
                        )
                    }

                    // Store ALL info blocks within ONE document
                    updateNapiInfoFromMultipleBlocks(info, blocks: ocrBlocks)

                    try? viewContext.save()

                    processingOCR = false
                    selectedDocumentURL = nil
                    selectedInfoForUpload = nil

                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: documentURL)

                    // Show detail view after processing
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedInfo = info
                    }
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    processingOCR = false
                    selectedDocumentURL = nil
                    selectedInfoForUpload = nil

                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: documentURL)

                    // Show error to user
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Error Alert
    private func showErrorAlert(message: String) {
        // Create alert with error message
        let alert = UIAlertController(
            title: "Feldolgozási hiba",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        // Present alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    // MARK: - Update NapiInfo from Legacy Parse
    private func updateNapiInfo(_ info: NapiInfo, with parsed: (tema: String?, erintett: String?, hatarido: String?, tartalom: String?, termekLista: [[String: String]]?)) {
        info.feldolgozva = true
        info.tema = parsed.tema ?? "Nincs téma"
        info.erintett = parsed.erintett ?? "Mindenki"
        info.hatarido = parsed.hatarido
        info.tartalom = parsed.tartalom
        info.infoIndex = 0

        if let termekek = parsed.termekLista,
           let jsonData = try? JSONSerialization.data(withJSONObject: termekek),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            info.termekLista = jsonString
        }
    }

    // MARK: - Update NapiInfo from Info Block
    private func updateNapiInfoFromBlock(_ info: NapiInfo, block: NapiInfoBlock) {
        info.feldolgozva = true
        info.tema = block.tema
        info.erintett = block.erintett
        info.hatarido = block.hatarido
        info.tartalom = block.tartalom
        info.infoIndex = Int16(block.index)

        if let termekek = block.termekLista,
           let jsonData = try? JSONSerialization.data(withJSONObject: termekek),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            info.termekLista = jsonString
        }
    }

    // MARK: - Update NapiInfo from Multiple Blocks
    private func updateNapiInfoFromMultipleBlocks(_ info: NapiInfo, blocks: [NapiInfoBlock]) {
        info.feldolgozva = true

        // Load existing blocks from JSON (if any)
        var existingBlocks: [[String: Any]] = []
        var currentPageNumber = 1

        if let existingJSON = info.termekLista,
           let existingData = existingJSON.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: existingData) as? [[String: Any]] {
            existingBlocks = parsed

            // Calculate next page number from existing blocks
            let maxPage = existingBlocks.compactMap { $0["pageNumber"] as? Int }.max() ?? 0
            currentPageNumber = maxPage + 1
        }

        // Use first block for main fields (only if this is the first page)
        if currentPageNumber == 1, let firstBlock = blocks.first {
            info.tema = firstBlock.tema
            info.erintett = firstBlock.erintett
            info.hatarido = firstBlock.hatarido
            info.tartalom = firstBlock.tartalom
        }

        // Convert new blocks to JSON format with pageNumber and completed status
        let newBlocksData: [[String: Any]] = blocks.map { block in
            var dict: [String: Any] = [
                "tema": block.tema,
                "erintett": block.erintett,
                "tartalom": block.tartalom,
                "index": block.index,
                "pageNumber": currentPageNumber, // Track which page/photo this came from
                "completed": false // Track completion status
            ]
            if let hatarido = block.hatarido {
                dict["hatarido"] = hatarido
            }
            if let termekLista = block.termekLista {
                dict["termekLista"] = termekLista
            }
            return dict
        }

        // Append new blocks to existing blocks
        let allBlocks = existingBlocks + newBlocksData

        // Save all blocks back to termekLista JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: allBlocks),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            info.termekLista = jsonString
        }

        // Update oldalSzam to reflect total number of pages
        info.oldalSzam = Int16(currentPageNumber)
    }

    // MARK: - Delete Info
    func deleteInfo(_ info: NapiInfo) {
        viewContext.delete(info)
        try? viewContext.save()
    }
}
