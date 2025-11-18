// Store343App.swift
// Main app entry point

import SwiftUI

@main
struct Store343App: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Generate napi_info documents on first launch
        persistenceController.generateNapiInfoDocuments()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
