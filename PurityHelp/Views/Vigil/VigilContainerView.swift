//
//  VigilContainerView.swift
//  PurityHelp
//
//  Main container for the Vigil flow.
//

import SwiftUI
import SwiftData

struct VigilContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentPhase = 1
    @State private var selectedTrigger = ""
    @State private var activePrayer: LiturgyPrayer?
    
    @State private var vigilService = VigilService()
    @State private var showExtendedSanctuary = false
    
    var body: some View {
        ZStack {
            Group {
                switch currentPhase {
                case 1:
                    ThresholdView(currentPhase: $currentPhase)
                case 2:
                    LogismoiSelectorView(currentPhase: $currentPhase, selectedTrigger: $selectedTrigger)
                        .onDisappear {
                            activePrayer = vigilService.getPrayer(for: selectedTrigger)
                        }
                case 3:
                    if let prayer = activePrayer {
                        AntirrhetikosView(currentPhase: $currentPhase, prayer: prayer)
                    } else {
                        Text("No prayer found. Transitioning...")
                            .onAppear {
                                currentPhase = 4
                            }
                    }
                case 4:
                    ReleaseView(selectedTrigger: selectedTrigger) { stayLonger in
                        logCompletion()
                        if stayLonger {
                            showExtendedSanctuary = true
                        } else {
                            dismiss()
                        }
                    }
                default:
                    EmptyView()
                }
            }
            .transition(.opacity)
            
            // Close Button in top right
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: $showExtendedSanctuary) {
            VigilExtendedTabView()
        }
    }
    
    private func logCompletion() {
        let entry = JournalEntry(type: .vigilPrayer, tags: selectedTrigger)
        modelContext.insert(entry)
        
        // Also log as an Urge Victory for insights
        let urgeLog = UrgeLog(outcome: "held_firm", replaceActivityUsed: "Pray the Vigil")
        modelContext.insert(urgeLog)
        
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }
}

#Preview {
    VigilContainerView()
        .modelContainer(for: JournalEntry.self)
}
