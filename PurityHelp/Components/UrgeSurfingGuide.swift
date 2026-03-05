//
//  UrgeSurfingGuide.swift
//  PurityHelp
//
//  Step-by-step urge surfing: notice, breathe, observe like a wave, ride it out. Optional timer.
//

import SwiftUI

struct UrgeSurfingGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: Int = 0
    @State private var timerSeconds: Int = 0
    @State private var timerRunning = false

    private let steps = [
        ("Notice", "Acknowledge the urge without acting. Say to yourself: \"I notice an urge.\""),
        ("Breathe", "Take a few slow breaths. You don't have to fight the urge—just breathe."),
        ("Observe", "Imagine the urge as a wave. It rises, peaks, and then passes. Watch it like you'd watch the ocean."),
        ("Ride it out", "Stay with the sensation without giving in. Urges typically peak in 10–30 minutes and then subside."),
        ("You're still here", "You didn't act. This moment of resistance is part of your purification.")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Urge surfing")
                .font(.title2)
                .fontWeight(.semibold)

            if step < steps.count {
                let (title, bodyText) = steps[step]
                VStack(spacing: 12) {
                    Text(title)
                        .font(.headline)
                    Text(bodyText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()

                if step == 3 {
                    if timerRunning {
                        Text("\(timerSeconds / 60):\(String(format: "%02d", timerSeconds % 60))")
                            .font(.system(.title, design: .monospaced))
                        Button("Stop timer") { timerRunning = false }
                    } else {
                        Button("Start 15 min timer") {
                            timerRunning = true
                            timerSeconds = 15 * 60
                        }
                        .buttonStyle(.bordered)
                    }
                }

                HStack {
                    if step > 0 {
                        Button("Back") { step -= 1 }
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(step < 4 ? "Next" : "Done") {
                        if step < 4 { step += 1 } else { dismiss() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerRunning, timerSeconds > 0 {
                timerSeconds -= 1
            } else if timerRunning, timerSeconds <= 0 {
                timerRunning = false
            }
        }
    }
}

#Preview {
    UrgeSurfingGuideView()
}
