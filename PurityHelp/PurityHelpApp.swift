//
//  PurityHelpApp.swift
//

import SwiftUI
import SwiftData

@main
struct PurityHelpApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ServerDoc.self, OutboxItem.self, SyncMeta.self])
        let configuration = ModelConfiguration(
            "PurityHelpV2",
            schema: schema,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: AppStore?

    var body: some View {
        Group {
            if let store {
                ContentView()
                    .environment(store)
            } else {
                ProgressView("Opening the day")
            }
        }
        .task {
            guard store == nil else { return }
            let created = AppStore(context: modelContext)
            store = created
            await created.syncNow()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, let store else { return }
            Task { await store.syncNow() }
        }
    }
}
