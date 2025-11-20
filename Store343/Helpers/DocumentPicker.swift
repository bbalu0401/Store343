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
        print("📄 DocumentPicker init with allowed types: \(allowedTypes.map { $0.identifier })")
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        print("🏗️ makeUIViewController called")
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        print("✅ UIDocumentPickerViewController created with delegate set")
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        print("🔄 updateUIViewController called")
    }

    func makeCoordinator() -> Coordinator {
        print("👥 makeCoordinator called")
        return Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
            print("👤 Coordinator initialized")
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("🎉 documentPicker delegate CALLED!")
            print("📎 Document picker: Selected \(urls.count) documents")

            guard let url = urls.first else {
                print("⚠️ No URL selected")
                return
            }

            print("📎 Selected file: \(url.lastPathComponent)")

            // asCopy: true means file is already copied, no need for security-scoped resource access
            // Copy file to temporary directory with unique name
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }

                // Copy file
                try FileManager.default.copyItem(at: url, to: tempURL)

                print("✅ File copied to temp: \(tempURL.path)")

                // Set binding on main thread after successful copy
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
            print("🚫 documentPickerWasCancelled delegate CALLED!")
            print("❌ Document picker cancelled by user")
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
