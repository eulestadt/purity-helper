//
//  BeginAgainView.swift
//  PurityHelp
//
//  A grace-filled, 4-stage protocol for processing a timer reset (Relapse).
//  Collects the Autopsy root cause and Confession lie for the ResetRecord.
//

import SwiftUI
import SwiftData

struct BeginAgainView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let record: StreakRecord
    let resetType: ResetType
    let onComplete: () -> Void
    
    @State private var stage: Int = 1
    
    // Autopsy & Confession Data
    @State private var selectedRootCause: String? = nil
    @State private var confessionText: String = ""
    @AppStorage("shareRelapses") private var shareRelapses = false
    
    private let rootCauses = [
        "Profound Loneliness",
        "Exhaustion",
        "Unresolved Anger",
        "Boredom",
        "Scrolling without purpose"
    ]
    
    var body: some View {
        ZStack {
            // Dawn/Twilight Gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.25), Color(red: 0.2, green: 0.15, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    if stage > 1 {
                        Button {
                            withAnimation { stage -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(8)
                    }
                }
                .padding()
                
                Spacer()
                
                Group {
                    if stage == 1 {
                        graceScreen
                    } else if stage == 2 {
                        autopsyScreen
                    } else if stage == 3 {
                        confessionScreen
                    } else if stage == 4 {
                        surrenderScreen
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                
                Spacer()
                
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { i in
                        Circle()
                            .fill(i == stage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Screen 1 (The Grace)
    private var graceScreen: some View {
        VStack(spacing: 24) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow.opacity(0.8))
            
            Text("Begin Again")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("The journey toward a pure heart continues.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(6)
            
            Button {
                withAnimation { stage = 2 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
        }
    }
    
    // MARK: - Screen 2 (The Autopsy)
    private var autopsyScreen: some View {
        VStack(spacing: 24) {
            Text("The Autopsy")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("Where was the gate left unguarded?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            VStack(spacing: 12) {
                ForEach(rootCauses, id: \.self) { cause in
                    Button {
                        selectedRootCause = cause
                    } label: {
                        HStack {
                            Text(cause)
                                .foregroundStyle(selectedRootCause == cause ? .black : .white)
                            Spacer()
                            if selectedRootCause == cause {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.black)
                            }
                        }
                        .padding()
                        .background(selectedRootCause == cause ? Color.white : Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: selectedRootCause == cause ? 0 : 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Button {
                withAnimation { stage = 3 }
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRootCause != nil ? Color.blue : Color.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(selectedRootCause == nil)
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Screen 3 (The Confession)
    private var confessionScreen: some View {
        VStack(spacing: 24) {
            Text("The Confession")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("Name the lie the enemy sold you in that moment. \nNaming the lie strips it of its power.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 32)
            
            TextField("e.g. I believed that giving in would finally relieve my stress...", text: $confessionText, axis: .vertical)
                .lineLimit(5...10)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .tint(.white)
                .padding(.horizontal, 32)
            
            Button {
                withAnimation { stage = 4 }
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!confessionText.isEmpty ? Color.blue : Color.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(confessionText.isEmpty)
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Screen 4 (The Surrender)
    private var surrenderScreen: some View {
        VStack(spacing: 24) {
            Text("Receive Mercy")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            
            Text("\"Create in me a clean heart, O God,\nand renew a right spirit within me.\"\n— Psalm 51")
                .font(.headline)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Toggle(isOn: $shareRelapses) {
                Text("Share this reflection with my Brotherhood/Sisterhood")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .tint(.blue)
            .padding(.horizontal, 40)
            .padding(.top, 16)
            
            Button {
                executeReset()
            } label: {
                Text("Arise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Execution
    private func executeReset() {
        let service = StreakService()
        
        switch resetType {
        case .pornography:
            service.resetPornography(record: record, modelContext: modelContext, note: confessionText, tag: selectedRootCause)
        case .masturbation:
            service.resetMasturbation(record: record, modelContext: modelContext, note: confessionText, tag: selectedRootCause)
        case .pureThoughts:
            service.resetPureThoughts(record: record, modelContext: modelContext, note: confessionText, tag: selectedRootCause)
        }
        
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
        onComplete()
        dismiss()
    }
}
