//
//  VigilService.swift
//  PurityHelp
//
//  Service to parse liturgies and handle logic for the Vigil module.
//

import Foundation
import SwiftUI

struct LiturgyPrayer: Codable, Identifiable {
    let id: String
    let tradition: String
    let type: String? // "call_and_response" or nil
    let triggerFilter: [String]
    let timeFilter: [String]
    let prayerText: String?
    let calls: [String]?
    let response: String?
    let citation: String
}

@Observable
final class VigilService {
    var prayers: [LiturgyPrayer] = []
    
    init() {
        loadPrayers()
    }
    
    private func loadPrayers() {
        let url = Bundle.main.url(forResource: "liturgies", withExtension: "json", subdirectory: "Resources/Prayers")
            ?? Bundle.main.url(forResource: "liturgies", withExtension: "json", subdirectory: "Prayers")
            ?? Bundle.main.url(forResource: "liturgies", withExtension: "json")
        
        guard let u = url else {
            print("VigilService: liturgies.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: u)
            prayers = try JSONDecoder().decode([LiturgyPrayer].self, from: data)
        } catch {
            print("VigilService: Failed to decode liturgies.json - \(error)")
        }
    }
    
    func currentTimeString() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Morning"
        case 12..<20:
            return "Day"
        default:
            return "Night"
        }
    }
    
    func getPrayer(for trigger: String) -> LiturgyPrayer? {
        let time = currentTimeString()
        let tradition = UserDefaults.standard.string(forKey: "vigilTradition") ?? "Ecumenical"
        
        // Match tradition strictly if not Ecumenical, or allow Ecumenical as fallback
        let candidates = prayers.filter { prayer in
            let matchesTrigger = prayer.triggerFilter.contains(trigger) || prayer.triggerFilter.contains("All")
            let matchesTime = prayer.timeFilter.contains(time) || prayer.timeFilter.contains("All")
            let matchesTradition = (prayer.tradition == tradition) || (prayer.tradition == "Ecumenical") || (tradition == "Ecumenical")
            return matchesTrigger && matchesTime && matchesTradition && prayer.type == nil // exclude litany types
        }
        
        return candidates.randomElement()
    }
    
    func getLitany() -> LiturgyPrayer? {
        return prayers.filter { $0.type == "call_and_response" }.randomElement()
    }
}
