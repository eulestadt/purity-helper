//
//  HomeView.swift
//  PurityHelp
//
//  Dashboard: streak display, seedling→tree (PurityTreeView), mission, hours reclaimed, optional Story of the Day.
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Binding var showUrgeMoment: Bool
    @State private var beginAgainType: ResetType? = nil
    @Environment(\.modelContext) private var modelContext
    @Query private var streakRecords: [StreakRecord]
    @Query private var missions: [UserMission]
    @Query private var memorizedVerses: [MemorizedVerse]

    private var streakRecord: StreakRecord? { streakRecords.first }
    private var mission: UserMission? { missions.first }
    private var missionText: String { mission?.text ?? "" }
    private var minutesPerDay: Int {
        UserDefaults.standard.object(forKey: "minutesPerDayReclaimed") as? Int ?? 30
    }
    private var hoursReclaimed: Int {
        let days = streakRecord?.effectiveBehavioralStreak ?? 0
        return (days * minutesPerDay) / 60
    }

    private static let milestones = [3, 7, 14, 30, 90]
    @State private var showMilestoneCelebration: Int? = nil
    @State private var showVigil = false

    var body: some View {
        NavigationStack {
            ZStack {
                homeBackground
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        anchorVerse
                        treeProgressCard
                        actionButtons
                        dailyScriptureSection
                        if !missionText.isEmpty {
                            missionCard
                        }
                        streakCardsSection
                        pureThoughtsCheckInSection
                    }
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // Vigil FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showVigil = true
                        } label: {
                            Image(systemName: "flame.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .sheet(item: $beginAgainType) { type in
                if let record = streakRecord {
                    BeginAgainView(record: record, resetType: type) {
                        // No-op, refresh handled by Observation
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showVigil) {
            VigilContainerView()
        }
        .onAppear {
            ensureStreakRecordExists()
            checkMilestone()
        }
        .alert("Milestone", isPresented: Binding(
            get: { showMilestoneCelebration != nil },
            set: { if !$0 { showMilestoneCelebration = nil } }
        )) {
            Button("Continue") { showMilestoneCelebration = nil }
        } message: {
            Text("\(showMilestoneCelebration ?? 0) days of purity. God's grace works with your effort—you're not alone.")
        }
    }

    private func checkMilestone() {
        let days = streakRecord?.effectiveBehavioralStreak ?? 0
        let last = UserDefaults.standard.integer(forKey: "lastCelebratedMilestone")
        if let m = Self.milestones.first(where: { $0 == days && days > last }) {
            UserDefaults.standard.set(m, forKey: "lastCelebratedMilestone")
            showMilestoneCelebration = m
        }
    }

    private var homeBackground: some View { PurityBackground() }

    private var anchorVerse: some View {
        VStack(spacing: 6) {
            Text("\"Blessed are the pure in heart, for they shall see God.\"")
                .font(.system(size: 19, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
            Text("(Mt 5:8)")
                .font(.caption)
                
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
    }

    private var dailyScriptureSection: some View {
        let verse = ScriptureService.verseForToday()
        return NavigationLink(destination: MeditateOnWordView()) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Scripture")
                    .font(.caption)
                    
                Text(verse.reference)
                    .font(.caption)
                    
                Text(verse.text)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: 16)
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your why")
                .font(.caption)
                
            Text(missionText)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 16)
    }

private var treeProgressCard: some View {
    let days = streakRecord?.effectiveBehavioralStreak ?? 0
    let stage = StreakService().treeStage(days: days)
    let imageName = stageTreeAssetName(for: stage)
    let cardShape = RoundedRectangle(cornerRadius: 24)
    return HStack(alignment: .bottom, spacing: 10) {
        VStack(alignment: .leading, spacing: 6) {
            Text("Purity Tree")
                .font(.caption)
                
            Text("\(stage.label) (\(days) days)")
                .font(.title3.weight(.bold))
        }
        Spacer()
        VStack(spacing: 12) {
            Spacer()
            fireBadge(days: days)
            hoursBadge(hours: hoursReclaimed)
            Spacer()
        }
        .frame(height: 250)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .frame(height: 280)
    .background {
        HStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 400)
                .frame(maxHeight: .infinity, alignment: .bottom)
            Spacer(minLength: 0)
        }
        .clipShape(cardShape)
    }
    .background(.ultraThinMaterial)
    .clipShape(cardShape)
    .overlay(cardShape.stroke(.white.opacity(0.55), lineWidth: 1))
}

    private func stageTreeAssetName(for stage: PurityTreeStage) -> String {
        switch stage {
        case .seedling: return "seedling"
        case .sprout: return "sprout"
        case .sapling: return "sapling"
        case .youngTree: return "tree"
        case .matureTree: return "mature"
        }
    }
    
    private func fireBadge(days: Int) -> some View {
        VStack(spacing: 0) { // Set spacing to 0
            if UIImage(named: "fire") != nil {
                Image("fire")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30) 
            } else {
                Image(systemName: "flame.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.orange)
                    .frame(width: 25, height: 25) 
            }
            
            VStack(spacing: -10) { // Negative spacing pulls the text up tight
                Text("\(days)")
                    .font(.system(size: 68, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4) 
                    .foregroundStyle(.black)
                
                Text("DAYS")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black.opacity(0.9))
            }
        }
        .frame(width: 120, height: 100) // Explicitly constrain the "invisible box"
    }

    private func hoursBadge(hours: Int) -> some View {
            VStack(spacing: 1) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    
                
                Text("\(hours)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5) 
                
                Text("HOURS RECLAIMED")
                    .font(.system(size: 10, weight: .bold))
                    
                    .multilineTextAlignment(.center)
                    .lineLimit(1) 
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .frame(maxWidth: 122, maxHeight: 92) 
            .glassCard(cornerRadius: 18)
        }
    private var actionButtons: some View {
        VStack(spacing: 12) {
            urgeButton
            NavigationLink(destination: ExamenView()) {
                Label("Daily Examen", systemImage: "cross.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .glassCard(cornerRadius: 20)
                    .foregroundStyle(.brown)
            }
            .buttonStyle(.plain)
        }
    }

    private var streakCardsSection: some View {
        VStack(spacing: 12) {
            if let record = streakRecord {
                StreakCard(title: "Days of purity (pornography)", days: record.pornographyStreakDays, onBeginAgain: {
                    beginAgainType = .pornography
                }, onFreeze: useStreakFreeze)
                StreakCard(title: "Days of purity (masturbation)", days: record.masturbationStreakDays, onBeginAgain: {
                    beginAgainType = .masturbation
                }, onFreeze: useStreakFreeze)
                if record.pureThoughtsEnabled {
                    StreakCard(title: "Days guarding thoughts", days: record.pureThoughtsStreakDays, onBeginAgain: {
                        beginAgainType = .pureThoughts
                    }, onFreeze: useStreakFreeze)
                }
            }
        }
    }

    private static let verseHeldDateKey = "verseHeldTodayDate"
    private static let verseHeldIdKey = "verseHeldTodayVerseId"

    @ViewBuilder
    private var pureThoughtsCheckInSection: some View {
        if let record = streakRecord, record.pureThoughtsEnabled {
            let service = StreakService()
            let alreadyChecked = record.pureThoughtsLastCheckDate.map { service.isSameDay($0, Date()) } ?? false
            let todayString = formatDateForVerseHeld(Date())
            if !alreadyChecked {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Did you guard your thoughts today?")
                        .font(.subheadline)
                        
                    HStack(spacing: 12) {
                        Button("I guarded my thoughts today") {
                            service.recordPureThoughtsCheck(record: record, guarded: true, modelContext: modelContext)
                            try? modelContext.save()
                            Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("No (reset)") {
                            beginAgainType = .pureThoughts
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    verseHeldPicker(todayString: todayString)
                }
                .padding()
                .glassCard(cornerRadius: 16)
            }
        }
    }

    @ViewBuilder
    private func verseHeldPicker(todayString: String) -> some View {
        let learned = memorizedVerses.filter { $0.status == "learning" || $0.status == "learned" }
        if !learned.isEmpty {
            let defaultVerses = ScriptureService.versesForMemorization()
            let customVerses = memorizedVerses.compactMap { $0.toScriptureVerse() }
            let customIds = Set(customVerses.map { $0.id })
            let staticVerses = defaultVerses.filter { !customIds.contains($0.id) }
            let combinedVerses = customVerses + staticVerses
            
            let binding = Binding<String>(
                get: {
                    let savedDate = UserDefaults.standard.string(forKey: Self.verseHeldDateKey)
                    guard savedDate == todayString else { return "none" }
                    return UserDefaults.standard.string(forKey: Self.verseHeldIdKey) ?? "none"
                },
                set: { newValue in
                    UserDefaults.standard.set(todayString, forKey: Self.verseHeldDateKey)
                    UserDefaults.standard.set(newValue, forKey: Self.verseHeldIdKey)
                }
            )
            Picker("Which verse did you hold onto today?", selection: binding) {
                Text("None / didn't use one").tag("none")
                ForEach(learned, id: \.verseId) { mv in
                    if let v = combinedVerses.first(where: { $0.id == mv.verseId }) {
                        Text(v.reference).tag(v.id)
                    }
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func formatDateForVerseHeld(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private var urgeButton: some View {
        Button {
            showUrgeMoment = true
        } label: {
            Label("I'm having an urge.", systemImage: "water.waves")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .glassCard(cornerRadius: 20)
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
    }

    private func ensureStreakRecordExists() {
        guard streakRecords.isEmpty else { return }
        let service = StreakService()
        do {
            _ = try service.fetchOrCreateStreakRecord(modelContext: modelContext)
            try modelContext.save()
        } catch {}
    }

    private func resetPornography(_ record: StreakRecord) {
        let service = StreakService()
        service.resetPornography(record: record, modelContext: modelContext)
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }

    private func resetMasturbation(_ record: StreakRecord) {
        let service = StreakService()
        service.resetMasturbation(record: record, modelContext: modelContext)
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }

    private func resetPureThoughts(_ record: StreakRecord) {
        let service = StreakService()
        service.resetPureThoughts(record: record, modelContext: modelContext)
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }

    private func useStreakFreeze() {
        let key = "streakFreezesRemaining"
        let n = max(0, UserDefaults.standard.integer(forKey: key) - 1)
        UserDefaults.standard.set(n, forKey: key)
    }
}

struct StreakCard: View {
    let title: String
    let days: Int
    let onBeginAgain: () -> Void
    var onFreeze: (() -> Void)? = nil

    private var freezesRemaining: Int {
        let key = "streakFreezesRemaining"
        let resetsKey = "streakFreezeMonth"
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        let last = UserDefaults.standard.string(forKey: resetsKey)
        let current = "\(year)-\(month)"
        if last != current {
            UserDefaults.standard.set(1, forKey: key)
            UserDefaults.standard.set(current, forKey: resetsKey)
        }
        return UserDefaults.standard.integer(forKey: key)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    
                Text("\(days)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Spacer()
            Button("Reset", role: .destructive) {
                onBeginAgain()
            }
            .font(.subheadline.bold())
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            
            if freezesRemaining > 0, let onFreeze {
                 Button {
                     onFreeze()
                 } label: {
                     Image(systemName: "snowflake")
                 }
                 .tint(.cyan)
                 .padding(.leading, 8)
            }
        }
        .padding()
        .glassCard(cornerRadius: 12)
    }
}

#Preview {
    HomeView(showUrgeMoment: .constant(false))
        .modelContainer(for: [StreakRecord.self, UserMission.self], inMemory: true)
}
