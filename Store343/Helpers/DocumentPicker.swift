// DocumentPicker.swift
// PDF and document file picker

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedDocumentURL: URL?
    @Environment(\.presentationMode) var presentationMode
    var allowedTypes: [UTType]

    init(selectedDocumentURL: Binding<URL?>, allowedTypes: [UTType] = [.pdf, .commaSeparatedText]) {
        self._selectedDocumentURL = selectedDocumentURL
        self.allowedTypes = allowedTypes
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("📎 Document picker: Selected \(urls.count) documents")
            guard let url = urls.first else {
                print("⚠️ No URL selected")
                return
            }

            print("📎 Selected file: \(url.lastPathComponent)")

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Failed to access security-scoped resource")
                parent.presentationMode.wrappedValue.dismiss()
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // Copy file to temporary directory
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }

                // Copy file
                try FileManager.default.copyItem(at: url, to: tempURL)

                print("✅ File copied to temp: \(tempURL.path)")

                // IMPORTANT: Set binding on main thread after successful copy
                DispatchQueue.main.async {
                    print("🔄 Setting selectedDocumentURL to: \(tempURL.lastPathComponent)")
                    self.parent.selectedDocumentURL = tempURL
                    print("✅ selectedDocumentURL set successfully")
                }
            } catch {
                print("❌ Error copying document: \(error)")
            }

            // Dismiss on main thread
            DispatchQueue.main.async {
                print("👋 Dismissing document picker")
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("❌ Document picker cancelled by user")
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
