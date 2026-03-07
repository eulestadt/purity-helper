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
        WisdomQuote(id: "bunyan1", source: "John Bunyan", text: "Look well to your own hearts and to the lusts thereof; for they are deceitful above all things."),
        WisdomQuote(id: "augustine_habit", source: "St. Augustine, Confessions", text: "I was bound, not by another's irons, but by my own iron will. From a distorted will came lust; and lust yielded to, became habit; and habit not resisted, became necessity."),
        WisdomQuote(id: "pascal1", source: "Blaise Pascal, Pensées", text: "All of humanity's problems stem from man's inability to sit quietly in a room alone."),
        WisdomQuote(id: "aquinas1", source: "St. Thomas Aquinas", text: "In the realm of evil thoughts none induces to sin as much as do thoughts that concern the pleasure of the flesh."),
        WisdomQuote(id: "aquinas2", source: "St. Thomas Aquinas", text: "I pray Thee to defend, with Thy grace, chastity and purity in my soul as well as in my body."),
        WisdomQuote(id: "aquinas3", source: "St. Thomas Aquinas", text: "Holy virginity refrains from all venereal pleasure in order more freely to have leisure for Divine contemplation."),
        WisdomQuote(id: "kempis3", source: "Thomas à Kempis, Imitation of Christ", text: "By two wings a man is lifted up from things earthly, namely, by Simplicity and Purity. Simplicity ought to be in our intention; purity in our affections."),
        WisdomQuote(id: "kempis4", source: "Thomas à Kempis, Imitation of Christ", text: "A pure heart penetrates heaven and hell."),
        WisdomQuote(id: "kempis5", source: "Thomas à Kempis, Imitation of Christ", text: "If thy heart were sincere and upright, then every creature would be unto thee a looking-glass of life, and a book of holy doctrine."),
        WisdomQuote(id: "dante1", source: "Dante Alighieri, The Divine Comedy", text: "Consider your origin. You were not formed to live like brutes but to follow virtue and knowledge."),
        WisdomQuote(id: "benedict1", source: "St. Benedict, Rule of St. Benedict", text: "Your way of acting should be different from the world's way; the love of Christ must come before all else.")
    ]

    var body: some View {
        List {
            ForEach(quotes) { q in
                VStack(alignment: .leading, spacing: 8) {
                    Text(q.text)
                        .font(.body)
                    Text(q.source)
                        .font(.caption)
                        
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
