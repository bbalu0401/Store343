// NfTermekListView.swift
// Product list with search and quantity tracking

import SwiftUI
import CoreData

struct NfTermekListView: View {
    let bizonylat: NfBizonylat
    let onBack: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchText = ""
    @State private var editingProduct: NfTermek? = nil
    @State private var editTotalAmount = ""
    @State private var showEditDialog = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Bizonylat: \(bizonylat.bizonylatSzam ?? "N/A")")
                    }
                    .foregroundColor(.lidlBlue)
                }

                Spacer()
            }
            .padding()
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .overlay(
                Divider()
                    .background(Color.secondary.opacity(0.3)),
                alignment: .bottom
            )

            // Search Bar (always visible, sticky)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Cikkszám keresése...", text: $searchText)
                    .font(.system(size: 16))
                    .keyboardType(.numberPad)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.adaptiveBackground(colorScheme: colorScheme))

            // Total items count
            HStack {
                Text("\(filteredProducts.count) tétel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.adaptiveBackground(colorScheme: colorScheme))

            // Product List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredProducts, id: \.id) { product in
                        ProductCard(
                            product: product,
                            onQuantityAdd: { amount in
                                addQuantity(to: product, amount: amount)
                            },
                            onTotalTap: {
                                editingProduct = product
                                editTotalAmount = "\(product.osszesen)"
                                showEditDialog = true
                            },
                            onCheckToggle: {
                                toggleCheck(product)
                            }
                        )
                    }
                }
                .padding()
            }
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
        }
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationBarHidden(true)
        .alert("Összeg szerkesztése", isPresented: $showEditDialog) {
            TextField("Új összeg", text: $editTotalAmount)
                .keyboardType(.numberPad)
            Button("Mentés") {
                saveEditedTotal()
            }
            Button("Mégse", role: .cancel) {}
        }
    }

    // MARK: - Filtered Products
    var filteredProducts: [NfTermek] {
        guard let termekekSet = bizonylat.termekekRelation as? Set<NfTermek> else {
            return []
        }

        var products = Array(termekekSet)

        // Filter by search text
        if !searchText.isEmpty {
            products = products.filter { product in
                product.cikkszam?.contains(searchText) ?? false
            }
        }

        // Sort by sorrend (order)
        products.sort { $0.sorrend < $1.sorrend }

        return products
    }

    // MARK: - Add Quantity
    func addQuantity(to product: NfTermek, amount: Int16) {
        guard amount > 0 else { return }

        // Update total
        product.osszesen += amount

        // Update history (talalasok)
        var history = product.talalasok?.split(separator: ",").compactMap { Int16($0.trimmingCharacters(in: .whitespaces)) } ?? []
        history.append(amount)
        product.talalasok = history.map { String($0) }.joined(separator: ",")

        // Auto-check if first quantity
        if !product.osszeszedve {
            product.osszeszedve = true
        }

        // Save
        try? viewContext.save()

        // Update bizonylat status
        updateBizonylatStatus()
    }

    // MARK: - Toggle Check
    func toggleCheck(_ product: NfTermek) {
        product.osszeszedve.toggle()

        // If unchecked, confirm and clear quantities
        if !product.osszeszedve {
            // For now, just toggle - in production, add confirmation dialog
            product.osszesen = 0
            product.talalasok = nil
        }

        try? viewContext.save()
        updateBizonylatStatus()
    }

    // MARK: - Save Edited Total
    func saveEditedTotal() {
        guard let product = editingProduct,
              let newAmount = Int16(editTotalAmount) else {
            return
        }

        // Update total
        product.osszesen = newAmount

        // Clear history when manually editing total
        product.talalasok = nil

        // Auto-check if amount > 0
        if newAmount > 0 {
            product.osszeszedve = true
        }

        try? viewContext.save()
        updateBizonylatStatus()
    }

    // MARK: - Update Bizonylat Status
    func updateBizonylatStatus() {
        guard let termekekSet = bizonylat.termekekRelation as? Set<NfTermek> else {
            return
        }

        let allCollected = termekekSet.allSatisfy { $0.osszeszedve }
        bizonylat.kesz = allCollected && !termekekSet.isEmpty

        try? viewContext.save()
    }
}

// MARK: - Product Card Component
struct ProductCard: View {
    @ObservedObject var product: NfTermek
    let onQuantityAdd: (Int16) -> Void
    let onTotalTap: () -> Void
    let onCheckToggle: () -> Void

    @State private var newQuantity = ""
    @FocusState private var isFocused: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Checkbox + Title
            HStack(alignment: .top, spacing: 12) {
                Button(action: onCheckToggle) {
                    Image(systemName: product.osszeszedve ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(product.osszeszedve ? .lidlBlue : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(product.cikkszam ?? "N/A") | \(product.cikkMegnev ?? "N/A")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                        .lineLimit(2)
                }

                Spacer()
            }

            Divider()

            // Quantities
            VStack(alignment: .leading, spacing: 6) {
                // Elvi készlet (expected)
                Text("Elvi: \(product.elviKeszlet) db")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Total collected (tap to edit)
                Button(action: onTotalTap) {
                    HStack {
                        Text("Összesen: \(product.osszesen) db")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.lidlBlue)

                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // History (if multiple entries)
                if let talalasok = product.talalasok, !talalasok.isEmpty {
                    let history = talalasok.split(separator: ",").map { String($0) }
                    if history.count > 1 {
                        HStack {
                            Text("Találva: \(history.joined(separator: " + ")) = \(product.osszesen)")
                                .font(.caption)
                                .foregroundColor(.green)

                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                // Add new quantity
                HStack {
                    Text("Újabb:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("0", text: $newQuantity)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .focused($isFocused)

                    Text("db")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        if let amount = Int16(newQuantity), amount > 0 {
                            onQuantityAdd(amount)
                            newQuantity = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.lidlYellow)
                    }
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
    }
}
