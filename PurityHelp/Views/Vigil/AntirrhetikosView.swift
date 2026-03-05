//
//  AntirrhetikosView.swift
//  PurityHelp
//
//  Phase 3: The Counter-Prayer. Drag to reveal.
//

import SwiftUI

struct AntirrhetikosView: View {
    @Binding var currentPhase: Int
    let prayer: LiturgyPrayer
    
    @State private var dragOffset: CGFloat = 0
    @State private var isRevealed = false
    @State private var showNext = false
    @State private var textHeight: CGFloat = 200 // reasonable default
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .leading) {
                // Hidden/Obscured Prayer Text
                Text(prayer.prayerText ?? "")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.1))
                    .blur(radius: isRevealed ? 0 : 4)
                    .padding()
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            textHeight = geo.size.height
                        }
                    })
                
                // The glowing reveal mask
                if !isRevealed {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear, .white.opacity(0.5), .white, .white.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 60, height: textHeight + 40)
                        .offset(x: dragOffset - 30) // center the glow on the finger
                        .blur(radius: 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = max(0, value.location.x)
                                }
                                .onEnded { value in
                                    // If dragged far enough, reveal it
                                    if dragOffset > UIScreen.main.bounds.width * 0.6 {
                                        withAnimation(.easeInOut) {
                                            isRevealed = true
                                            scheduleNextButton()
                                        }
                                    } else {
                                        withAnimation {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                }
                
                // Fully visible text (shown after reveal)
                if isRevealed {
                    Text(prayer.prayerText ?? "")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)
            
            Text(prayer.citation)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 8)
            
            Spacer()
            
            if !isRevealed {
                Text("Drag finger to wipe away the fog")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 40)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: isRevealed)
            }
            
            if showNext {
                Button {
                    withAnimation {
                        currentPhase = 4
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
    
    private func scheduleNextButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation {
                showNext = true
            }
        }
    }
}
