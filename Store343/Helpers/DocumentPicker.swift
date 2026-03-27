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

            // Note: asCopy: true means file is already copied by iOS
            // No need for startAccessingSecurityScopedResource()

            // Use the URL directly (already points to a copy)
            print("✅ File already copied by iOS to: \(url.path)")

            // Set binding on main thread (parent will handle dismiss)
            DispatchQueue.main.async {
                print("🔄 Setting selectedDocumentURL to: \(url.lastPathComponent)")
                self.parent.selectedDocumentURL = url
                print("✅ selectedDocumentURL set successfully")
                print("✅ Parent view will handle sheet dismiss")
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
