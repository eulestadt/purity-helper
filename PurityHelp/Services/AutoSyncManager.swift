//
//  AutoSyncManager.swift
//  PurityHelp
//
//  Handles automated Cloud Sync pushing when the application enters the background.
//

import SwiftUI
import SwiftData

@MainActor
final class AutoSyncManager {
    static let shared = AutoSyncManager()
    
    private init() {}
    
    func performBackgroundSync(modelContext: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "cloudSyncEnabled") else { return }
        
        let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey)
        guard token != nil else { return } // Must be logged in
        
        CloudSyncService.baseURL = "https://purity-helper-api.onrender.com"
        
        do {
            let engine = FullSyncEngine(context: modelContext)
            var fullModels = try engine.exportFullData()
            
            // Apply Privacy Controls globally
            let shareExamens = UserDefaults.standard.bool(forKey: "shareExamens")
            let shareUrges = UserDefaults.standard.bool(forKey: "shareUrges")
            let shareRelapses = UserDefaults.standard.bool(forKey: "shareRelapses")
            
            if !shareExamens { fullModels.examenEntries = [] }
            if !shareUrges { fullModels.urgeLogs = [] }
            if !shareRelapses { fullModels.resetRecords = [] }
            
            // Pull Top-Level Streak details
            let descriptor = FetchDescriptor<StreakRecord>()
            let streakRecord = try? modelContext.fetch(descriptor).first
            
            let minutesPerDay = UserDefaults.standard.integer(forKey: "minutesPerDayReclaimed")
            let actualMinutes = minutesPerDay == 0 ? 30 : minutesPerDay
            let hours = ((streakRecord?.effectiveBehavioralStreak ?? 0) * actualMinutes) / 60
            
            let urgeCount = (try? modelContext.fetch(FetchDescriptor<UrgeLog>()).count) ?? 0
            
            let payload = CloudSyncService.buildPayload(
                pornographyDays: streakRecord?.pornographyStreakDays ?? 0,
                masturbationDays: streakRecord?.masturbationStreakDays ?? 0,
                pureThoughtsDays: streakRecord?.pureThoughtsStreakDays ?? 0,
                pureThoughtsEnabled: streakRecord?.pureThoughtsEnabled ?? false,
                urgeCount: urgeCount,
                hoursReclaimed: hours > 0 ? hours : nil,
                fullModels: fullModels
            )
            
            CloudSyncService.sync(payload: payload) { result in
                switch result {
                case .success:
                    print("Auto-sync completed successfully in background.")
                case .failure(let error):
                    print("Auto-sync failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Auto-sync export failed: \(error.localizedDescription)")
        }
    }
}
