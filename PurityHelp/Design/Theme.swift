//
//  Theme.swift
//

import SwiftUI

enum PurityColor {
    static let ink = Color(red: 0.11, green: 0.17, blue: 0.14)
    static let muted = Color(red: 0.36, green: 0.43, blue: 0.39)
    static let green = Color(red: 0.12, green: 0.42, blue: 0.29)
    static let gold = Color(red: 0.55, green: 0.42, blue: 0.18)
    static let clay = Color(red: 0.55, green: 0.29, blue: 0.24)
    static let paper = Color(red: 0.99, green: 0.97, blue: 0.94)
}

struct PurityBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.90, green: 0.94, blue: 0.90),
                Color(red: 0.96, green: 0.94, blue: 0.89),
                Color(red: 0.94, green: 0.90, blue: 0.84)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func purityGlass(radius: CGFloat = 22) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                }
        }
    }
}

struct GlassPanel<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .purityGlass()
    }
}
