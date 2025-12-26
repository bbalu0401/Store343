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
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil
    @State private var processingOCR = false
    @State private var selectedInfoForUpload: NapiInfo? = nil
    @State private var infoToDelete: NapiInfo? = nil
    @State private var showDeleteConfirmation = false

    enum CalendarViewType {
        case week, month, year
    }
    
    var body: some View {
        mainContent
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: imagePickerSourceType)
            }
            .onChange(of: selectedImage) { newImage in
                guard let image = newImage, let info = selectedInfoForUpload else { return }
                
                showImagePicker = false
                processImage(image: image, for: info)
                selectedImage = nil
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
                Text("Biztosan törlöd ezt a dokumentumot?")
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if selectedInfo == nil {
                listView
            }

            if let info = selectedInfo {
                NapiInfoDetailView(info: info, onBack: {
                    selectedInfo = nil
                })
                .transition(.move(edge: .trailing))
            }
        }
    }
    
    @ViewBuilder
    private var listView: some View {
                VStack(spacing: 0) {
                    // Navigation Bar (csak lista nézetben!)
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

                // Calendar View with integrated expandable info
                ScrollView {
                    VStack(spacing: 0) {
                        switch calendarView {
                        case .week:
                            WeekCalendarViewWithInfo(
                                selectedDate: $selectedDate,
                                expandedDate: $selectedDate,
                                napiInfos: napiInfos,
                                onToggleCalendar: toggleCalendarView,
                                onSelectInfo: { info in
                                    if info.feldolgozva {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedInfo = info
                                        }
                                    }
                                },
                                onAddPhoto: { info in
                                    selectedInfoForUpload = info
                                    showImagePicker = true
                                },
                                onDeleteInfo: { info in
                                    infoToDelete = info
                                    showDeleteConfirmation = true
                                },
                                onCreateNew: { date in
                                    let newInfo = NapiInfo(context: viewContext)
                                    newInfo.datum = date
                                    newInfo.feldolgozva = false
                                    newInfo.oldalSzam = 0
                                    newInfo.tema = nil
                                    newInfo.erintett = nil
                                    newInfo.tartalom = nil
                                    try? viewContext.save()
                                    selectedInfoForUpload = newInfo
                                    showImagePicker = true
                                }
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
                }
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                }
                .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
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
                            surgos: block.surgos,
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

    // MARK: - Image Processing (Google Vision API)
    func processImage(image: UIImage, for info: NapiInfo) {
        processingOCR = true

        Task {
            do {
                // Call Google Vision API for image processing
                let blocks = try await ClaudeAPIService.shared.processNapiInfo(image: image)

                // Update UI on main thread
                await MainActor.run {
                    // Convert Claude API blocks to our internal format with Hungarian text corrections
                    let ocrBlocks = blocks.map { block -> NapiInfoBlock in
                        return NapiInfoBlock(
                            tema: ClaudeAPIService.correctHungarianText(block.tema),
                            erintett: ClaudeAPIService.correctHungarianText(block.erintett),
                            hatarido: block.hatarido.map { ClaudeAPIService.correctHungarianText($0) },
                            surgos: block.surgos,
                            tartalom: ClaudeAPIService.correctHungarianText(block.tartalom),
                            termekLista: nil,
                            index: 0
                        )
                    }

                    // Store ALL info blocks within ONE document
                    updateNapiInfoFromMultipleBlocks(info, blocks: ocrBlocks)

                    try? viewContext.save()

                    processingOCR = false
                    selectedImage = nil
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
                    selectedImage = nil
                    selectedInfoForUpload = nil


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
                "surgos": block.surgos,
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
