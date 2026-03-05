//
//  PurityTreeView.swift
//  PurityHelp
//
//  Seedling → tree by days of purity (1–6 Seedling, 7–13 Sprout, 14–29 Sapling, 30–89 Young tree, 90+ Mature tree).
//

import SwiftUI

struct PurityTreeView: View {
    let days: Int
    let stage: PurityTreeStage
    var showsDetails: Bool

    init(days: Int, showsDetails: Bool = true) {
        self.days = days
        self.stage = StreakService().treeStage(days: days)
        self.showsDetails = showsDetails
    }

    var body: some View {
        VStack(spacing: 12) {
            treeImage
            if showsDetails {
                Text(stage.label)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(stage.dayRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(days) days of purity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var treeImage: some View {
        let size: CGFloat = 80
        Image(stage.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size + 24, height: size + 24)
            .frame(width: size + 20, height: size + 20)
    }
}

private extension PurityTreeStage {
    // Exact asset mapping requested by user.
    var assetName: String {
        switch self {
        case .seedling:
            return "seedling"
        case .sprout:
            return "sprout"
        case .sapling:
            return "sapling"
        case .youngTree:
            return "tree"
        case .matureTree:
            return "mature"
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        PurityTreeView(days: 3)
        PurityTreeView(days: 10)
        PurityTreeView(days: 45)
        PurityTreeView(days: 90)
    }
    .padding()
}
