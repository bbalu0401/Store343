// PersistenceController.swift
// Core Data stack and napi_info auto-generation

import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Store343")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Generate napi_info documents for 1 month ahead (Mon-Fri only)
    func generateNapiInfoDocuments() {
        let context = container.viewContext
        let calendar = Calendar.current
        let today = Date()
        
        // Check if already generated
        let fetchRequest: NSFetchRequest<NapiInfo> = NapiInfo.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        if (try? context.count(for: fetchRequest)) ?? 0 > 0 {
            return // Already generated
        }
        
        var workDaysGenerated = 0
        var currentDate = today
        
        // Generate ~22 workdays (approximately 1 month)
        while workDaysGenerated < 22 {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Monday = 2, Friday = 6 (Sunday = 1, Saturday = 7)
            if weekday >= 2 && weekday <= 6 {
                let info = NapiInfo(context: context)
                info.datum = currentDate
                
                let month = calendar.component(.month, from: currentDate)
                let day = calendar.component(.day, from: currentDate)
                info.fajlnev = "napi_info_\(month).\(day)"
                info.feldolgozva = false
                
                workDaysGenerated += 1
            }
            
            // Move to next day
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // Save
        try? context.save()
    }
}
