//
//  VigilExtendedTabView.swift
//  PurityHelp
//
//  Extended Sanctuary to stay longer (10 minutes).
//

import SwiftUI

struct VigilExtendedTabView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining = 600 // 10 minutes
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 10-Minute Timer Header
                HStack {
                    Image(systemName: "timer")
                    Text(timeString(time: timeRemaining))
                        .font(.headline.monospacedDigit())
                }
                .foregroundStyle(timeRemaining > 0 ? .white : .green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                
                TabView {
                    LitanyView()
                        .tabItem {
                            Label("Litany", systemImage: "list.bullet.rectangle.portrait")
                        }
                    
                    AudioSanctuaryView()
                        .tabItem {
                            Label("Listen", systemImage: "headphones")
                        }
                }
            }
            .navigationTitle("Extended Sanctuary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark").font(.headline).padding(6)
                            
                    }
                }
            }
            .onAppear {
                // Ensure tab bar is visible and styled properly against black
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .black
                
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    VigilExtendedTabView()
}
