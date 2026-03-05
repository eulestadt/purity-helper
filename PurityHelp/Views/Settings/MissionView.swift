//
//  MissionView.swift
//  PurityHelp
//
//  Edit personal "why" / mission.
//

import SwiftUI
import SwiftData

struct MissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var missions: [UserMission]

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    private var mission: UserMission? { missions.first }

    var body: some View {
        Form {
            Section {
                TextField("e.g. For my marriage, To be the man God made me to be, For my kids, Freedom to love", text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($isFocused)
            } header: {
                Text("Your why")
            } footer: {
                Text("Shown on the home screen and at the top of Urge Moment when you're tempted.")
            }
        }
        .navigationTitle("Mission")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            text = mission?.text ?? ""
        }
        .onDisappear {
            saveMission()
        }
    }

    private func saveMission() {
        if let m = mission {
            m.text = text
            m.updatedAt = .now
        } else if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let m = UserMission(text: text)
            modelContext.insert(m)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        MissionView()
            .modelContainer(for: UserMission.self, inMemory: true)
    }
}
