// UjHianycikkView.swift
// View for adding new shortage items

import SwiftUI
import CoreData

struct UjHianycikkView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var cikkszam: String = ""
    @State private var cikkMegnev: String = ""
    @State private var vonalkod: String = ""
    @State private var selectedKategoria: HianycikkKategoria = .troso
    @State private var selectedPrioritas: HianycikkPrioritas = .normal
    @State private var jegyzetek: String = ""
    @State private var elviKeszlet: String = "0"
    @State private var raktarKeszlet: String = "0"
    @State private var minKeszlet: String = "5"

    @State private var showAlert = false
    @State private var alertMessage = ""

    // OCR states
    @State private var showImagePicker = false
    @State private var showSourceSelector = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage? = nil
    @State private var processingOCR = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 1️⃣ Termék keresése
                    SectionCard(title: "1️⃣  Termék keresése") {
                        VStack(spacing: 16) {
                            // OCR Button
                            Button(action: {
                                showSourceSelector = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("📸 Ártábla fotózása (OCR)")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.lidlYellow)
                                .cornerRadius(12)
                            }

                            Divider()
                                .padding(.vertical, 4)

                            // Cikkszám
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🔍 Cikkszám vagy vonalkód")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                                TextField("Cikkszám", text: $cikkszam)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            Text("vagy")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Megnevezés
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🔍 Név szerinti keresés")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                                TextField("Termék megnevezése", text: $cikkMegnev)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            // Vonalkód (optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vonalkód (opcionális)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Vonalkód", text: $vonalkod)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                        }
                    }

                    // 2️⃣ Kategória kiválasztása
                    SectionCard(title: "2️⃣  Kategória kiválasztása") {
                        VStack(spacing: 12) {
                            ForEach(HianycikkKategoria.allCases) { kategoria in
                                Button(action: {
                                    selectedKategoria = kategoria
                                }) {
                                    HStack {
                                        Text(kategoria.emoji)
                                            .font(.title3)
                                        Image(systemName: selectedKategoria == kategoria ? "largecircle.fill.circle" : "circle")
                                        Text(kategoria.displayName)
                                            .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    // 3️⃣ Prioritás
                    SectionCard(title: "3️⃣  Prioritás") {
                        VStack(spacing: 12) {
                            ForEach(HianycikkPrioritas.allCases) { prioritas in
                                Button(action: {
                                    selectedPrioritas = prioritas
                                }) {
                                    HStack {
                                        Image(systemName: selectedPrioritas == prioritas ? "largecircle.fill.circle" : "circle")
                                        Text(prioritas.displayName)
                                            .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    // 4️⃣ Készlet információk
                    SectionCard(title: "4️⃣  Készlet információk") {
                        VStack(spacing: 12) {
                            // Elvi készlet
                            HStack {
                                Text("Elvi készlet:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("0", text: $elviKeszlet)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                Text("db")
                            }

                            // Raktár készlet
                            HStack {
                                Text("Raktár készlet:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("0", text: $raktarKeszlet)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                Text("db")
                            }

                            // Min. készlet
                            HStack {
                                Text("Min. készlet:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("5", text: $minKeszlet)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                Text("db")
                            }
                        }
                    }

                    // 5️⃣ Jegyzetek (opcionális)
                    SectionCard(title: "5️⃣  Jegyzetek (opcionális)") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $jegyzetek)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.adaptiveBackground(colorScheme: colorScheme))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    // Rögzítés gomb
                    Button(action: rogzitHianycikk) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("✅ Hiánycikk rögzítése")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lidlBlue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .navigationTitle("Új hiánycikk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Mégse") {
                        dismiss()
                    }
                }
            }
            .alert("Hiánycikk rögzítése", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("Sikeres") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .actionSheet(isPresented: $showSourceSelector) {
                ActionSheet(
                    title: Text("Ártábla fotózása"),
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
                        .cancel(Text("Mégse"))
                    ]
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: imageSourceType)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    processOCR(image: image)
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

                                Text("Apple Vision feldolgozás...")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Ártábla elemzése folyamatban")
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
    }

    // MARK: - Helper Functions
    private func rogzitHianycikk() {
        // Validation
        guard !cikkszam.isEmpty || !cikkMegnev.isEmpty else {
            alertMessage = "Kérlek add meg a cikkszámot vagy a terméknevet!"
            showAlert = true
            return
        }

        // Create new entity
        let ujHianycikk = HianycikkEntity(context: viewContext)
        ujHianycikk.id = UUID()
        ujHianycikk.cikkszam = cikkszam.isEmpty ? nil : cikkszam
        ujHianycikk.cikkMegnev = cikkMegnev.isEmpty ? nil : cikkMegnev
        ujHianycikk.vonalkod = vonalkod.isEmpty ? nil : vonalkod
        ujHianycikk.kategoria = selectedKategoria.rawValue
        ujHianycikk.prioritas = selectedPrioritas.rawValue
        ujHianycikk.statusz = HianycikkStatusz.uj.rawValue
        ujHianycikk.jegyzetek = jegyzetek.isEmpty ? nil : jegyzetek
        ujHianycikk.elviKeszlet = Int16(elviKeszlet) ?? 0
        ujHianycikk.raktarKeszlet = Int16(raktarKeszlet) ?? 0
        ujHianycikk.minKeszlet = Int16(minKeszlet) ?? 5
        ujHianycikk.hianyKezdete = Date()
        ujHianycikk.lezarva = false
        ujHianycikk.letrehozva = Date()
        ujHianycikk.modositva = Date()
        ujHianycikk.rendeltMennyiseg = 0

        // Save
        do {
            try viewContext.save()
            alertMessage = "Sikeres rögzítés! A hiánycikk hozzáadva."
            showAlert = true
        } catch {
            alertMessage = "Hiba történt a mentés során: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - OCR Processing
    private func processOCR(image: UIImage) {
        processingOCR = true

        Task {
            do {
                // Use Apple Vision Framework
                let result = try await AppleVisionOCRService.shared.recognizeText(from: image)

                // Update UI on main thread
                await MainActor.run {
                    if let recognizedCikkszam = result.cikkszam {
                        cikkszam = recognizedCikkszam
                    }

                    if let recognizedMegnev = result.cikkMegnev {
                        cikkMegnev = recognizedMegnev
                    }

                    // Show success message
                    if result.isValid {
                        alertMessage = "✅ OCR sikeres!\n\nFelismert adatok:\n" +
                                     (result.cikkszam != nil ? "Cikkszám: \(result.cikkszam!)\n" : "") +
                                     (result.cikkMegnev != nil ? "Megnevezés: \(result.cikkMegnev!)" : "")
                        showAlert = true
                    } else {
                        alertMessage = "⚠️ Nem sikerült felismerni a cikkszámot vagy a terméknevet.\nKérlek add meg manuálisan!"
                        showAlert = true
                    }

                    processingOCR = false
                    selectedImage = nil
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    alertMessage = "❌ Hiba az OCR feldolgozás során:\n\(error.localizedDescription)"
                    showAlert = true
                    processingOCR = false
                    selectedImage = nil
                }
            }
        }
    }
}
