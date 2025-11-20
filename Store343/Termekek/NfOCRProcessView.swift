// NfOCRProcessView.swift
// Multi-page OCR upload flow with "Van még oldal?" dialog

import SwiftUI
import CoreData

struct NfOCRProcessView: View {
    let week: NfHet
    let onComplete: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var currentPage = 0
    @State private var allResults: [[NfOCRResult]] = []
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var showSourceSelector = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage? = nil
    @State private var selectedDocumentURL: URL? = nil
    @State private var processingOCR = false
    @State private var showMorePagesDialog = false
    @State private var pageProcessed = false
    @State private var lastPageBizonylatNumbers: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Mégse")
                    }
                    .foregroundColor(.lidlBlue)
                }

                Spacer()

                Text("Dokumentum feltöltés")
                    .font(.headline)

                Spacer()

                // Placeholder for symmetry
                Color.clear.frame(width: 70)
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(
                Divider()
                    .background(Color.secondary.opacity(0.3)),
                alignment: .bottom
            )

            // Content
            if !pageProcessed {
                // First step: Take photo
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.lidlBlue)

                    VStack(spacing: 8) {
                        Text("Fotózd le \(currentPage == 0 ? "az első" : "a következő") oldalt")
                            .font(.title2)
                            .fontWeight(.light)

                        if currentPage > 0 {
                            Text("\(currentPage). oldal már feldolgozva")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showSourceSelector = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Second step: Page processed
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    VStack(spacing: 8) {
                        Text("\(currentPage + 1). oldal feldolgozva")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if !lastPageBizonylatNumbers.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(lastPageBizonylatNumbers, id: \.self) { bizonylat in
                                    Text("- Found bizonylat: \(bizonylat)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Text("Van még oldal?")
                        .font(.headline)
                        .padding(.top)

                    HStack(spacing: 16) {
                        Button(action: {
                            // More pages
                            currentPage += 1
                            pageProcessed = false
                            lastPageBizonylatNumbers = []
                            showSourceSelector = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Igen, fotózok")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.lidlBlue)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            // No more pages, save to CoreData
                            saveToCoreData()
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Nem, kész")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .actionSheet(isPresented: $showSourceSelector) {
            ActionSheet(
                title: Text("Dokumentum feltöltése"),
                message: Text("Válassz forrást"),
                buttons: [
                    .default(Text("📷 Fotó készítése")) {
                        imageSourceType = .camera
                        showImagePicker = true
                    },
                    .default(Text("🖼️ Galéria")) {
                        imageSourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .default(Text("📄 PDF/Dokumentum")) {
                        showDocumentPicker = true
                    },
                    .cancel(Text("Mégse"))
                ]
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: imageSourceType)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedDocumentURL: $selectedDocumentURL)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                processOCR(image: image)
            }
        }
        .onChange(of: selectedDocumentURL) { oldValue, newValue in
            if let documentURL = newValue {
                processDocument(documentURL: documentURL)
            }
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
    }

    // MARK: - Process OCR (Image)
    func processOCR(image: UIImage) {
        processingOCR = true

        Task {
            do {
                // Call Claude API for accurate OCR
                let claudeTermekek = try await ClaudeAPIService.shared.processNfVisszakuldes(image: image)

                // Update UI on main thread
                await MainActor.run {
                    // Group termekek by bizonylatSzam
                    var bizonylatGrouped: [String: [NfTermekData]] = [:]
                    let startingSorrend = Int16(allResults.flatMap { $0 }.flatMap { $0.termekek }.count)

                    for (index, claudeTermek) in claudeTermekek.enumerated() {
                        let termek = NfTermekData(
                            cikkszam: claudeTermek.cikkszam,
                            cikkMegnev: claudeTermek.cikk_megnevezes,
                            elviKeszlet: Int16(claudeTermek.elvi_keszlet),
                            sorrend: startingSorrend + Int16(index)
                        )

                        if bizonylatGrouped[claudeTermek.bizonylat_szam] == nil {
                            bizonylatGrouped[claudeTermek.bizonylat_szam] = []
                        }
                        bizonylatGrouped[claudeTermek.bizonylat_szam]?.append(termek)
                    }

                    // Convert to NfOCRResult array
                    let results = bizonylatGrouped.map { (bizonylatSzam, termekek) in
                        NfOCRResult(bizonylatSzam: bizonylatSzam, termekek: termekek)
                    }.sorted { $0.bizonylatSzam < $1.bizonylatSzam }

                    // Store results
                    allResults.append(results)

                    // Extract bizonylat numbers for display
                    lastPageBizonylatNumbers = results.map { $0.bizonylatSzam }

                    // Mark page as processed
                    pageProcessed = true
                    processingOCR = false
                    selectedImage = nil
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    processingOCR = false
                    selectedImage = nil

                    // Show error to user
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Process Document (PDF)
    func processDocument(documentURL: URL) {
        processingOCR = true

        Task {
            do {
                // Call Claude API for document processing
                let claudeTermekek = try await ClaudeAPIService.shared.processNfVisszakuldesDocument(documentURL: documentURL)

                // Update UI on main thread
                await MainActor.run {
                    // Group termekek by bizonylatSzam
                    var bizonylatGrouped: [String: [NfTermekData]] = [:]
                    let startingSorrend = Int16(allResults.flatMap { $0 }.flatMap { $0.termekek }.count)

                    for (index, claudeTermek) in claudeTermekek.enumerated() {
                        let termek = NfTermekData(
                            cikkszam: claudeTermek.cikkszam,
                            cikkMegnev: claudeTermek.cikk_megnevezes,
                            elviKeszlet: Int16(claudeTermek.elvi_keszlet),
                            sorrend: startingSorrend + Int16(index)
                        )

                        if bizonylatGrouped[claudeTermek.bizonylat_szam] == nil {
                            bizonylatGrouped[claudeTermek.bizonylat_szam] = []
                        }
                        bizonylatGrouped[claudeTermek.bizonylat_szam]?.append(termek)
                    }

                    // Convert to NfOCRResult array
                    let results = bizonylatGrouped.map { (bizonylatSzam, termekek) in
                        NfOCRResult(bizonylatSzam: bizonylatSzam, termekek: termekek)
                    }.sorted { $0.bizonylatSzam < $1.bizonylatSzam }

                    // Store results
                    allResults.append(results)

                    // Extract bizonylat numbers for display
                    lastPageBizonylatNumbers = results.map { $0.bizonylatSzam }

                    // Mark page as processed
                    pageProcessed = true
                    processingOCR = false
                    selectedDocumentURL = nil

                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: documentURL)
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    processingOCR = false
                    selectedDocumentURL = nil

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

    // MARK: - Save to CoreData
    func saveToCoreData() {
        // Merge all results
        let mergedResults = NfOCRHelper.mergeOCRResults(allResults, preserveOrder: true)

        // Create or update bizonyláts and products
        for result in mergedResults {
            // Check if bizonylat already exists
            let fetchRequest: NSFetchRequest<NfBizonylat> = NfBizonylat.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "bizonylatSzam == %@ AND het == %@", result.bizonylatSzam, week)

            let existingBizonylatList = (try? viewContext.fetch(fetchRequest)) ?? []
            let bizonylat: NfBizonylat

            if let existing = existingBizonylatList.first {
                bizonylat = existing
            } else {
                bizonylat = NfBizonylat(context: viewContext)
                bizonylat.id = UUID()
                bizonylat.bizonylatSzam = result.bizonylatSzam
                bizonylat.het = week
                bizonylat.kesz = false
            }

            // Update item count
            bizonylat.osszesTetel = Int16(result.termekek.count)

            // Add products
            for termekData in result.termekek {
                // Check if product already exists
                let productFetchRequest: NSFetchRequest<NfTermek> = NfTermek.fetchRequest()
                productFetchRequest.predicate = NSPredicate(format: "cikkszam == %@ AND bizonylat == %@", termekData.cikkszam, bizonylat)

                let existingProducts = (try? viewContext.fetch(productFetchRequest)) ?? []

                if existingProducts.isEmpty {
                    let product = NfTermek(context: viewContext)
                    product.id = UUID()
                    product.cikkszam = termekData.cikkszam
                    product.cikkMegnev = termekData.cikkMegnev
                    product.elviKeszlet = termekData.elviKeszlet
                    product.sorrend = termekData.sorrend
                    product.osszesen = 0
                    product.osszeszedve = false
                    product.talalasok = nil
                    product.bizonylat = bizonylat
                }
            }
        }

        // Save
        do {
            try viewContext.save()
            onComplete()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving to CoreData: \(error)")
        }
    }
}
