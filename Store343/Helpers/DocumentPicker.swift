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

            // DEBUG: Create alert to show delegate was called
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = UIAlertController(
                    title: "DEBUG",
                    message: "Delegate called! \(urls.count) files",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(alert, animated: true)
                }
            }

            guard let url = urls.first else {
                print("⚠️ No URL selected")
                return
            }

            print("📎 Selected file: \(url.lastPathComponent)")

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Failed to access security-scoped resource")

                // DEBUG: Show alert for security-scoped resource failure
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "DEBUG ERROR",
                        message: "Failed to access security-scoped resource",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(alert, animated: true)
                    }
                }

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

                // DEBUG: Show alert for successful copy
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "DEBUG SUCCESS",
                        message: "File copied: \(tempURL.lastPathComponent)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(alert, animated: true)
                    }
                }

                // IMPORTANT: Set binding on main thread after successful copy
                DispatchQueue.main.async {
                    print("🔄 Setting selectedDocumentURL to: \(tempURL.lastPathComponent)")
                    self.parent.selectedDocumentURL = tempURL
                    print("✅ selectedDocumentURL set successfully")
                }
            } catch {
                print("❌ Error copying document: \(error)")

                // DEBUG: Show alert for copy error
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "DEBUG COPY ERROR",
                        message: "Error: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(alert, animated: true)
                    }
                }
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
