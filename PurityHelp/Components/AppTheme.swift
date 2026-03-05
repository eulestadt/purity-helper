//
//  AppTheme.swift
//  PurityHelp
//
//  Shared gradient background and glass card styling.
//

import SwiftUI

struct PurityBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.85, green: 0.9, blue: 0.95),
                Color(red: 0.95, green: 0.9, blue: 0.85),
                Color(red: 0.9, green: 0.95, blue: 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

