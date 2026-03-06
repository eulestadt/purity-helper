//
//  AutoSyncManager.swift
//  PurityHelp
//
//  Handles cloud sync for logged-in users:
//  - Push (upload local data) on any data change.
//  - Pull-then-sync (download server data, merge, then re-upload) on foreground / login.
//    This is the safe multi-device pattern: always read the latest server state before writing.
//

import SwiftUI
import SwiftData

@MainActor
final class AutoSyncManager {
    static let shared = AutoSyncManager()
    private init() {}

    // MARK: - Push Only (called after local changes)
    // Requires the user to be logged in. NOT gated on cloudSyncEnabled —
    // that toggle only controls Shared Walk visibility, not personal cross-device sync.
    func performBackgroundSync(modelContext: ModelContext) {
        guard KeychainHelper.load(forKey: KeychainHelper.authTokenKey) != nil else { return }

        do {
            let engine = FullSyncEngine(context: modelContext)
            var fullModels = try engine.exportFullData()

            // Privacy controls: strip data the user doesn't want visible to partners.
            // Full unfiltered models are used for actual content sync via Pull→Merge→Push;
            // the share link view uses the filtered payload stored in `models`.
            let shareExamens  = UserDefaults.standard.bool(forKey: "shareExamens")
            let shareUrges    = UserDefaults.standard.bool(forKey: "shareUrges")
            let shareRelapses = UserDefaults.standard.bool(forKey: "shareRelapses")
            var sharedModels = fullModels
            if !shareExamens  { sharedModels.examenEntries = [] }
            if !shareUrges    { sharedModels.urgeLogs = [] }
            if !shareRelapses { sharedModels.resetRecords = [] }

            let descriptor = FetchDescriptor<StreakRecord>()
            let streakRecord = try? modelContext.fetch(descriptor).first
            let minutesPerDay = UserDefaults.standard.integer(forKey: "minutesPerDayReclaimed")
            let actualMinutes = minutesPerDay == 0 ? 30 : minutesPerDay
            let hours = ((streakRecord?.effectiveBehavioralStreak ?? 0) * actualMinutes) / 60
            let urgeCount = (try? modelContext.fetch(FetchDescriptor<UrgeLog>()).count) ?? 0

            let payload = CloudSyncService.buildPayload(
                pornographyDays:     streakRecord?.pornographyStreakDays  ?? 0,
                masturbationDays:    streakRecord?.masturbationStreakDays ?? 0,
                pureThoughtsDays:    streakRecord?.pureThoughtsStreakDays ?? 0,
                pureThoughtsEnabled: streakRecord?.pureThoughtsEnabled   ?? false,
                urgeCount:           urgeCount,
                hoursReclaimed:      hours > 0 ? hours : nil,
                fullModels:          sharedModels,   // ← privacy-filtered for the share link view
                shareExamens:        shareExamens,
                shareUrges:          shareUrges,
                shareRelapses:       shareRelapses
            )

            CloudSyncService.sync(payload: payload) { result in
                switch result {
                case .success:
                    print("[Sync] Push succeeded.")
                case .failure(let error):
                    print("[Sync] Push failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("[Sync] Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Pull → Merge → Push (safe multi-device sync)
    // Always use this when coming to the foreground or logging in.
    // Downloads the server's version, merges with local using the Delta
    // Merge Protocol (newest updatedAt wins), then pushes the merged result
    // back so every other device gets the latest combined state.
    func performPullThenSync(modelContext: ModelContext) {
        guard KeychainHelper.load(forKey: KeychainHelper.authTokenKey) != nil else { return }

        CloudSyncService.pull { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                print("[Sync] Pull failed: \(error.localizedDescription)")
                // Gracefully fall back to a plain push so we still upload local changes
                self.performBackgroundSync(modelContext: modelContext)

            case .success(let serverPayload):
                print("[Sync] Pull succeeded. Merging...")
                do {
                    // importFullData merges server state into SwiftData, saves,
                    // and at its end calls performBackgroundSync to push the merged result.
                    let engine = FullSyncEngine(context: modelContext)
                    try engine.importFullData(serverPayload)
                    print("[Sync] Merge complete. Push triggered by importFullData.")
                } catch {
                    print("[Sync] Merge/import failed: \(error.localizedDescription)")
                    self.performBackgroundSync(modelContext: modelContext)
                }
            }
        }
    }
}
