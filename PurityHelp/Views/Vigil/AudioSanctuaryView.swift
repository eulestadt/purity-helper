//
//  AudioSanctuaryView.swift
//  PurityHelp
//
//  Extended Sanctuary: Guided audio watchfulness meditation.
//

import SwiftUI
import AVFoundation

struct AudioSanctuaryView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var isDragging = false
    
    @State private var breathe = false
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Calming premium dark background
            LinearGradient(
                colors: [
                    Color(red: 25/255, green: 25/255, blue: 45/255),
                    Color(red: 10/255, green: 10/255, blue: 15/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Animated Breathing Orb
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 240, height: 240)
                        .scaleEffect(breathe ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathe)
                        
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 260, height: 260)
                        .scaleEffect(breathe ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(0.5), value: breathe)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .shadow(color: .white.opacity(0.2), radius: breathe ? 30 : 10)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathe)

                    Image(systemName: "headphones")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 20)
                
                VStack(spacing: 8) {
                    Text("Watchfulness")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Guided Meditation")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Slider(value: $progress, in: 0...1, onEditingChanged: { editing in
                        isDragging = editing
                        if !editing, let player = audioPlayer {
                            player.currentTime = progress * player.duration
                        }
                    })
                    .tint(.white)
                    .padding(.horizontal, 40)
                    
                    HStack {
                        Text(formatTime(audioPlayer?.currentTime ?? 0))
                        Spacer()
                        Text(formatTime(audioPlayer?.duration ?? 0))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 20)
                
                Button {
                    togglePlayback()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(red: 15/255, green: 15/255, blue: 25/255))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupAudio()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            audioPlayer?.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) { _ in
            guard let player = audioPlayer, isPlaying, !isDragging else { return }
            progress = player.currentTime / player.duration
        }
    }
    
    private func setupAudio() {
        if let asset = NSDataAsset(name: "watchfulness_guided") {
            do {
                audioPlayer = try AVAudioPlayer(data: asset.data)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error setting up audio: \(error)")
            }
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isNormal || time.isZero else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    AudioSanctuaryView()
}
