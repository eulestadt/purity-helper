//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {
    @State private var showUrge = false

    var body: some View {
        TabView {
            TodayView(showUrge: $showUrge)
                .tabItem { Label("Today", systemImage: "sun.max") }
            WordView()
                .tabItem { Label("Word", systemImage: "book") }
            ExamenView()
                .tabItem { Label("Examen", systemImage: "moon.stars") }
            PathView()
                .tabItem { Label("Path", systemImage: "signpost.right") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(PurityColor.green)
        .fullScreenCover(isPresented: $showUrge) {
            UrgeMomentView()
        }
    }
}
