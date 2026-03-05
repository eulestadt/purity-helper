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
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "headphones")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text("Watchfulness Meditation")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                VStack(spacing: 16) {
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
                
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                }
                
                Spacer()
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
        if let asset = NSDataAsset(name: "watchfulness_guided-2.mp3") { // Matches exact dataset name from find_by_name
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
