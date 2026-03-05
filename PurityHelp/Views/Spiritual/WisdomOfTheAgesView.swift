//
//  WisdomOfTheAgesView.swift
//  PurityHelp
//
//  Curated excerpts: Kempis, Bunyan, Lewis, Augustine, Francis de Sales.
//

import SwiftUI

struct WisdomQuote: Identifiable {
    let id: String
    let source: String
    let text: String
}

struct WisdomOfTheAgesView: View {
    private let quotes: [WisdomQuote] = [
        WisdomQuote(id: "kempis1", source: "Thomas à Kempis, Imitation of Christ", text: "Resist the beginnings; remedies come too late, when by long delay the evil has gained strength."),
        WisdomQuote(id: "kempis2", source: "Thomas à Kempis", text: "The enemy is more easily conquered if he is refused admittance to the mind and is met beyond the threshold when he knocks."),
        WisdomQuote(id: "lewis1", source: "C.S. Lewis, Mere Christianity", text: "Very often what God first helps us towards is not the virtue itself but just this power of always trying again."),
        WisdomQuote(id: "augustine1", source: "St. Augustine, Confessions", text: "Give me chastity and continency, only not yet—then later, the grace of conversion at the fig tree."),
        WisdomQuote(id: "francis1", source: "St. Francis de Sales", text: "The pure heart is like the mother of pearl which admits no drop of water save that which comes from Heaven."),
        WisdomQuote(id: "bunyan1", source: "John Bunyan", text: "Look well to your own hearts and to the lusts thereof; for they are deceitful above all things.")
    ]

    var body: some View {
        List {
            ForEach(quotes) { q in
                VStack(alignment: .leading, spacing: 8) {
                    Text(q.text)
                        .font(.body)
                    Text(q.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Wisdom of the Ages")
    }
}

#Preview {
    NavigationStack {
        WisdomOfTheAgesView()
    }
}
