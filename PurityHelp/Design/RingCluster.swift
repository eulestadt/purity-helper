//
//  RingCluster.swift
//

import SwiftUI

struct RingGauge: View {
    var label: String
    var value: Double
    var tint: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(tint.opacity(0.16), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0, min(1, value)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int((value * 100).rounded()))")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(PurityColor.ink)
            }
            .frame(width: 72, height: 72)
            Text(label)
                .font(.caption2)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(PurityColor.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(Int((value * 100).rounded())) percent")
    }
}

struct RingCluster: View {
    var rings: DayRings

    var body: some View {
        HStack(spacing: 16) {
            RingGauge(label: "Clear", value: rings.clear, tint: PurityColor.green)
            RingGauge(label: "Watch", value: rings.watch, tint: PurityColor.gold)
            RingGauge(label: "Prayer", value: rings.prayer, tint: PurityColor.ink)
            RingGauge(label: "Word", value: rings.word, tint: Color(red: 0.29, green: 0.39, blue: 0.55))
        }
        .frame(maxWidth: .infinity)
    }
}
