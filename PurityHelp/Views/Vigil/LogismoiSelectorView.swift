//
//  LogismoiSelectorView.swift
//  PurityHelp
//
//  Phase 2: Naming the Trigger.
//

import SwiftUI

struct LogismoiSelectorView: View {
    @Binding var currentPhase: Int
    @Binding var selectedTrigger: String
    
    let triggers = [
        ("Lust", "Porneia"),
        ("Boredom", "Acedia"),
        ("Anger", "Ogre"),
        ("Loneliness", "Lype")
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Name the thought.")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(triggers, id: \.0) { trigger in
                    Button {
                        selectedTrigger = trigger.0
                        withAnimation(.easeIn) {
                            currentPhase = 3
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(trigger.1)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(trigger.0)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    LogismoiSelectorView(currentPhase: .constant(2), selectedTrigger: .constant(""))
}
