//
//  PurityHelpApp.swift
//  PurityHelp
//
//  iOS 26 recovery app: zero pornography, zero masturbation, journey toward a pure heart.
//

import SwiftUI
import SwiftData

@main
struct PurityHelpApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StreakRecord.self,
            ResetRecord.self,
            UrgeLog.self,
            ExamenEntry.self,
            IfThenPlan.self,
            JournalEntry.self,
            UserMission.self,
            MemorizedVerse.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        // On foreground: pull server state first, merge, then push.
                        // This is the multi-device safe cycle.
                        Task { @MainActor in
                            AutoSyncManager.shared.performPullThenSync(modelContext: sharedModelContainer.mainContext)
                        }
                    } else if newPhase == .background {
                        // On background: push local state up quickly.
                        Task { @MainActor in
                            AutoSyncManager.shared.performBackgroundSync(modelContext: sharedModelContainer.mainContext)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
                    // On login: immediately pull so this device gets the server's data
                    // (e.g. from another device) before anything is overwritten.
                    Task { @MainActor in
                        AutoSyncManager.shared.performPullThenSync(modelContext: sharedModelContainer.mainContext)
                    }
                }
        }
    }
}
