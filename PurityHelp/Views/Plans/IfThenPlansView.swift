//
//  IfThenPlansView.swift
//  PurityHelp
//
//  Implementation intentions: "When [trigger], I will [action]".
//

import SwiftUI
import SwiftData

struct IfThenPlansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IfThenPlan.order) private var plans: [IfThenPlan]
    @State private var showAdd = false

    private let triggerSuggestions = ["Alone at night", "Stressed", "Bored", "Lonely", "Fatigued", "Weekend", "Bored at screen"]

    var body: some View {
        List {
            ForEach(plans) { plan in
                VStack(alignment: .leading, spacing: 4) {
                    Text("When \(plan.trigger)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(plan.action)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deletePlans)
        }
        .navigationTitle("If–Then Plans")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddIfThenPlanView()
        }
    }

    private func deletePlans(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(plans[i])
        }
        try? modelContext.save()
    }
}

struct AddIfThenPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var trigger: String = ""
    @State private var action: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("When (trigger)") {
                    TextField("e.g. Alone at night", text: $trigger)
                }
                Section("I will (action)") {
                    Picker("Select action", selection: $action) {
                        Text("Select...").tag("")
                        Text("Pray the Vigil").tag("Pray the Vigil")
                        Text("Pray to God for help").tag("Pray to God for help")
                        Text("Call accountability partner").tag("Call accountability partner")
                        Text("Leave the room").tag("Leave the room")
                        Text("Do 20 push-ups").tag("Do 20 push-ups")
                    }
                    if !["Pray the Vigil", "Pray to God for help", "Call accountability partner", "Leave the room", "Do 20 push-ups"].contains(action) && !action.isEmpty {
                        TextField("or type a custom action", text: $action)
                    } else if ["Pray the Vigil", "Pray to God for help", "Call accountability partner", "Leave the room", "Do 20 push-ups"].contains(action) || action.isEmpty {
                        TextField("or type a custom action", text: Binding(
                            get: { "" },
                            set: { if !$0.isEmpty { action = $0 } }
                        ))
                    }
                }
            }
            .navigationTitle("New plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let plan = IfThenPlan(trigger: trigger, action: action, order: 0)
                        modelContext.insert(plan)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(trigger.isEmpty || action.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        IfThenPlansView()
            .modelContainer(for: IfThenPlan.self, inMemory: true)
    }
}
