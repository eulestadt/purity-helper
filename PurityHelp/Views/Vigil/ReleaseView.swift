//
//  ReleaseView.swift
//  PurityHelp
//
//  Phase 4: The Release. Drag vertically to finish.
//

import SwiftUI
import AVFoundation

struct ReleaseView: View {
    let selectedTrigger: String
    let onCompletion: (Bool) -> Void // bool indicates if extended sanctuary is needed
    
    @State private var dragOffset: CGFloat = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var hasReleased = false
    @State private var timeRemaining: CGFloat = 10.0
    private let totalTime: CGFloat = 10.0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 60) {
            Text("Pass by without entering.")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 150, height: 150)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                
                Text(selectedTrigger.isEmpty ? "Urge" : selectedTrigger)
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 { // only allow drag up
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height < -150 {
                            releaseObject()
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            
            if !hasReleased {
                VStack(spacing: 8) {
                    Image(systemName: "chevron.up")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Swipe symbol up to release")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .offset(y: 40)
            } else {
                VStack(spacing: 24) {
                    Text("You have passed by the urge.")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    // Animated Progress Bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(.white)
                            .frame(width: (totalTime - timeRemaining) / totalTime * (UIScreen.main.bounds.width - 80), height: 8)
                            .animation(.linear(duration: 0.1), value: timeRemaining)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    
                    HStack(spacing: 16) {
                        Button {
                            openBibleApp()
                            onCompletion(false)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .font(.title2)
                                Text("Read")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button {
                            onCompletion(false)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "door.right.hand.open")
                                    .font(.title2)
                                Text("Leave")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    Button {
                        timeRemaining = -1
                        onCompletion(true)
                    } label: {
                        Text("Stay Longer (10 mins)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 40)
                .transition(.opacity)
                .onReceive(timer) { _ in
                    if hasReleased && timeRemaining > 0 {
                        timeRemaining -= 0.1
                        if timeRemaining <= 0 {
                            onCompletion(false)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
    
    private func releaseObject() {
        withAnimation(.easeIn(duration: 0.5)) {
            dragOffset = -UIScreen.main.bounds.height
        }
        
        playBellSound()
        
        // Let the animation finish, then show the buttons
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                hasReleased = true
            }
        }
    }
    
    private func playBellSound() {
        if let asset = NSDataAsset(name: "Glocke") { // Using generic asset name
            do {
                audioPlayer = try AVAudioPlayer(data: asset.data)
                audioPlayer?.play()
            } catch {
                print("Error playing bell: \(error)")
            }
        }
    }
    
    private func openBibleApp() {
        // Try Logos first, then Bible app (YouVersion)
        let logosURL = URL(string: "logosres:")!
        let bibleURL = URL(string: "bible://")!
        
        if UIApplication.shared.canOpenURL(logosURL) {
            UIApplication.shared.open(logosURL)
        } else if UIApplication.shared.canOpenURL(bibleURL) {
            UIApplication.shared.open(bibleURL)
        } else {
            // Fallback to a generic bible website if no apps installed
            if let webURL = URL(string: "https://www.bible.com") {
                UIApplication.shared.open(webURL)
            }
        }
    }
}

