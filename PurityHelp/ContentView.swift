//
//  ContentView.swift
//  PurityHelp
//
//  Root view: Tab-based navigation (Home, Reflect, Settings); Urge accessible from Home.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showUrgeMoment = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showUrgeMoment: $showUrgeMoment)
                .tabItem {
                    Label("Home", systemImage: "leaf.fill")
                }
                .tag(0)

            NavigationStack {
                HideInYourHeartView()
            }
            .tabItem {
                Label("Memorize", systemImage: "book.closed.fill")
            }
            .tag(1)

            ExamenView()
                .tabItem {
                    Label("Examen", systemImage: "heart.text.square.fill")
                }
                .tag(2)

            NavigationStack {
                StoriesOfHopeView()
            }
            .tabItem {
                Label("Stories", systemImage: "book.fill")
            }
            .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.accentColor)
        .fullScreenCover(isPresented: $showUrgeMoment) {
            UrgeMomentView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StreakRecord.self, ResetRecord.self, UserMission.self], inMemory: true)
}
