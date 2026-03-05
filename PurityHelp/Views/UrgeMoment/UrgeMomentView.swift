//
//  UrgeMomentView.swift
//  PurityHelp
//
//  Crisis support: mission at top, theosis framing, breathing, delay timer, quick actions.
//

import SwiftUI
import SwiftData

struct UrgeMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var missions: [UserMission]
    @Query(sort: \IfThenPlan.order) private var ifThenPlans: [IfThenPlan]

    @State private var showBreathing = false
    @State private var showDelayTimer = false
    @State private var delaySecondsRemaining = 10 * 60
    @State private var showStoriesOfHope = false
    @State private var showUrgeSurfing = false
    @State private var sessionLog: UrgeLog?
    @AppStorage("accountabilityPartnerPhone") private var accountabilityPartnerPhone: String = ""
    @State private var showReciteVerse = false
    @State private var showVigil = false

    private var missionText: String { missions.first?.text ?? "" }
    private let timer = Timer.publish(every: 1, on: .main, in: .common)

    var body: some View {
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        theosisFraming
                        if !missionText.isEmpty {
                            missionBlock
                        }
                        if showBreathing {
                            breathingSection
                        } else if showDelayTimer {
                            delayTimerSection
                        } else {
                            ifThenPlanReminder
                            quickActionsSection
                            reciteVerseSection
                            replaceActivitySection
                            toolsSection
                            urgeSurfingSection
                            storiesOfHopeLink
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Urge support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.headline).padding(6)
                            
                    }
                }
            }
            .onReceive(timer) { _ in
                if showDelayTimer && delaySecondsRemaining > 0 {
                    delaySecondsRemaining -= 1
                }
            }
            .sheet(isPresented: $showReciteVerse) {
                ReciteVerseView()
            }
            .fullScreenCover(isPresented: $showVigil) {
                VigilContainerView()
            }
        }
    }

    private var reciteVerseSection: some View {
        Button {
            showReciteVerse = true
        } label: {
            Label("Recite a verse you've learned", systemImage: "book.closed")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .buttonStyle(.bordered)
    }

    private var theosisFraming: some View {
        Text("This struggle purifies. Resisting is part of purification—each moment you hold firm, your heart is being cleansed.")
            .font(.subheadline)
            
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 12)
    }

    private var missionBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your why")
                .font(.caption)
                
            Text(missionText)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 12)
    }

    private var breathingSection: some View {
        VStack(spacing: 16) {
            BreathingPacerView()
            Button("Done with breathing") {
                showBreathing = false
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var delayTimerSection: some View {
        VStack(spacing: 16) {
            Text("10-minute delay")
                .font(.headline)
            Text(timeFormatted(delaySecondsRemaining))
                .font(.system(.title, design: .monospaced))
            if delaySecondsRemaining > 0 {
                Text("Stay with it. The urge will pass.")
                    .font(.caption)
                    
            } else {
                Button("I made it") {
                    showDelayTimer = false
                    logUrgeHeldFirm()
                }
                .buttonStyle(.borderedProminent)
            }
            Button("Cancel timer") {
                showDelayTimer = false
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    @ViewBuilder
    private var ifThenPlanReminder: some View {
        if let plan = ifThenPlans.first {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your plan for this situation")
                    .font(.caption)
                    
                Text("When \(plan.trigger), I will \(plan.action)")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassCard(cornerRadius: 12)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick actions")
                .font(.headline)
            FlowLayout(spacing: 8) {
                QuickActionButton(title: "Call accountability partner", systemImage: "phone.fill") {
                    recordQuickAction("Call accountability partner")
                    if !accountabilityPartnerPhone.isEmpty,
                       let url = URL(string: "tel://\(accountabilityPartnerPhone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
                QuickActionButton(title: "Leave the room", systemImage: "figure.walk") {
                    recordQuickAction("Leave the room")
                }
                QuickActionButton(title: "Do 20 push-ups", systemImage: "figure.strengthtraining.traditional") {
                    recordQuickAction("Do 20 push-ups")
                }
            }
        }
    }

    private var replaceActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What will you do instead?")
                .font(.headline)
            FlowLayout(spacing: 8) {
                QuickActionButton(title: "Pray the Vigil", systemImage: "flame.fill") {
                    recordReplaceActivity("Pray the Vigil")
                    showVigil = true
                }
                QuickActionButton(title: "Read", systemImage: "book") { recordReplaceActivity("Read") }
                QuickActionButton(title: "Exercise", systemImage: "figure.run") { recordReplaceActivity("Exercise") }
                QuickActionButton(title: "Call someone", systemImage: "phone") { recordReplaceActivity("Call someone") }
                QuickActionButton(title: "Pray", systemImage: "hands.sparkles") { recordReplaceActivity("Pray") }
                QuickActionButton(title: "Leave the room", systemImage: "figure.walk") { recordReplaceActivity("Leave the room") }
            }
        }
    }

    private var urgeSurfingSection: some View {
        Button {
            showUrgeSurfing = true
        } label: {
            Label("Urge surfing guide", systemImage: "waveform.path.ecg")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $showUrgeSurfing) {
            NavigationStack {
                UrgeSurfingGuideView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: { showUrgeSurfing = false }) {
                                Image(systemName: "xmark").font(.headline).padding(6)
                                    
                            }
                        }
                    }
            }
        }
    }

    private var storiesOfHopeLink: some View {
        Button {
            showStoriesOfHope = true
        } 
        label: {
            Label("Others have been here too", systemImage: "book")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $showStoriesOfHope) {
            NavigationStack {
                StoriesOfHopeView()
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tools")
                .font(.headline)
            Button {
                showBreathing = true
            } label: {
                Label("4-4-8 breathing", systemImage: "wind")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .buttonStyle(.bordered)
            Button {
                delaySecondsRemaining = 10 * 60
                showDelayTimer = true
            } label: {
                Label("10-minute delay", systemImage: "timer")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
    }

    private func timeFormatted(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func logUrgeHeldFirm() {
        let log = UrgeLog(outcome: "held_firm")
        modelContext.insert(log)
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }

    private func recordQuickAction(_ title: String) {
        if sessionLog == nil {
            let log = UrgeLog(outcome: "in_progress")
            modelContext.insert(log)
            sessionLog = log
        }
        sessionLog?.quickActionUsed = title
        try? modelContext.save()
    }

    private func recordReplaceActivity(_ title: String) {
        if sessionLog == nil {
            let log = UrgeLog(outcome: "in_progress")
            modelContext.insert(log)
            sessionLog = log
        }
        sessionLog?.replaceActivityUsed = title
        try? modelContext.save()
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, point) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    UrgeMomentView()
        .modelContainer(for: [UserMission.self, UrgeLog.self, MemorizedVerse.self], inMemory: true)
}
