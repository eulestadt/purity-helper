//
//  LitanyView.swift
//  PurityHelp
//
//  Extended Sanctuary: Call and response litany.
//

import SwiftUI

struct LitanyView: View {
    @State private var vigilService = VigilService()
    @State private var litany: LiturgyPrayer?
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let litany = litany, let calls = litany.calls, let response = litany.response {
                VStack(spacing: 40) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 24) {
                                ForEach(0...currentIndex, id: \.self) { index in
                                    if index < calls.count {
                                        Text(calls[index])
                                            .font(.title3)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(index == currentIndex ? .white : .white.opacity(0.3))
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                            .id(index)
                                    } else if index == calls.count {
                                        // Finished
                                        Text("Amen.")
                                            .font(.title)
                                            .foregroundStyle(.white)
                                            .transition(.opacity)
                                            .id(index)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .onChange(of: currentIndex) { _, newIndex in
                            withAnimation {
                                proxy.scrollTo(newIndex, anchor: .bottom)
                            }
                        }
                    }
                    
                    if currentIndex < calls.count {
                        Button {
                            advanceStep()
                        } label: {
                            Text(response)
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 20)
                    } else {
                        Text(litany.citation)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.bottom, 40)
                    }
                }
            } else {
                ProgressView()
                    .onAppear {
                        litany = vigilService.getLitany()
                    }
            }
        }
    }
    
    private func advanceStep() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.8)) {
            currentIndex += 1
        }
    }
}

#Preview {
    LitanyView()
}
