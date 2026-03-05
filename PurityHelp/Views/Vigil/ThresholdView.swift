//
//  ThresholdView.swift
//  PurityHelp
//
//  Phase 1: The Threshold. Long press for 5 seconds to enter.
//

import SwiftUI

struct ThresholdView: View {
    @Binding var currentPhase: Int
    @State private var isPressing = false
    @State private var pressProgress: CGFloat = 0.0
    
    private let duration: TimeInterval = 5.0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 40) {
            Text("Enter the Sanctuary.")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Press and hold")
                .font(.body)
                .foregroundStyle(.white.opacity(0.5))
            
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: pressProgress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: pressProgress)
                
                Image(systemName: "hand.point.up.braille.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(isPressing ? .white : .white.opacity(0.5))
                    .animation(.easeInOut, value: isPressing)
            }
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 100, pressing: { pressing in
                isPressing = pressing
                if !pressing {
                    pressProgress = 0
                }
            }, perform: {})
            .sensoryFeedback(.impact, trigger: isPressing)
            .onReceive(timer) { _ in
                if isPressing {
                    pressProgress += CGFloat(0.1 / duration)
                    if pressProgress >= 1.0 {
                        successTransition()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
    
    private func successTransition() {
        isPressing = false
        pressProgress = 0
        timer.upstream.connect().cancel()
        
        // Haptic success impact handled by system sensoryFeedback if we trigger another state,
        // but let's use UIImpactFeedbackGenerator directly for precise timing here
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            currentPhase = 2
        }
    }
}

#Preview {
    ThresholdView(currentPhase: .constant(1))
}
