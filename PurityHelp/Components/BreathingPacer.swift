//
//  BreathingPacer.swift
//  PurityHelp
//
//  4-4-8 breathing: inhale 4, hold 4, exhale 8.
//

import SwiftUI

struct BreathingPacerView: View {
    enum Phase: String {
        case inhale = "Breathe in"
        case hold = "Hold"
        case exhale = "Breathe out"
    }

    @State private var phase: Phase = .inhale
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6

    private let inhaleSeconds: Double = 4
    private let holdSeconds: Double = 4
    private let exhaleSeconds: Double = 8

    var body: some View {
        VStack(spacing: 24) {
            Text(phase.rawValue)
                .font(.title2)
                .fontWeight(.medium)
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(opacity))
                    .scaleEffect(scale)
                    .frame(width: 120, height: 120)
            }
            .frame(height: 140)
            Text("4-4-8 breathing")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            runCycle()
        }
    }

    private func runCycle() {
        withAnimation(.easeInOut(duration: inhaleSeconds)) {
            phase = .inhale
            scale = 1.2
            opacity = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleSeconds) {
            withAnimation(.easeInOut(duration: holdSeconds)) {
                phase = .hold
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleSeconds + holdSeconds) {
            withAnimation(.easeInOut(duration: exhaleSeconds)) {
                phase = .exhale
                scale = 0.8
                opacity = 0.6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleSeconds + holdSeconds + exhaleSeconds) {
            runCycle()
        }
    }
}

#Preview {
    BreathingPacerView()
        .padding()
}
