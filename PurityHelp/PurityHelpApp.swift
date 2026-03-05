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
        }
    }
}
