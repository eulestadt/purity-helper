//
//  BreathingPacer.swift
//  4-4-8: inhale, hold, exhale.
//

import SwiftUI

struct BreathingPacer: View {
    @State private var scale: CGFloat = 0.72
    @State private var label = "Breathe in"
    @State private var running = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(PurityColor.green.opacity(0.16)).frame(width: 180, height: 180)
                Circle().stroke(PurityColor.green, lineWidth: 2).frame(width: 180 * scale, height: 180 * scale)
                Text(label)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(PurityColor.ink)
            }
            .frame(height: 190)
            Button(running ? "Breathing" : "Start 4-4-8") {
                guard !running else { return }
                running = true
                Task { await cycle() }
            }
            .buttonStyle(.borderedProminent)
            .tint(PurityColor.green)
            .disabled(running)
        }
    }

    private func cycle() async {
        await phase("Breathe in", scale: 1, seconds: 4)
        await phase("Hold", scale: 1, seconds: 4)
        await phase("Breathe out", scale: 0.72, seconds: 8)
        label = "Again, if you need it"
        running = false
    }

    private func phase(_ title: String, scale next: CGFloat, seconds: Double) async {
        label = title
        withAnimation(.easeInOut(duration: seconds)) { scale = next }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
