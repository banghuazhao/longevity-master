//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AchievementPopupView: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    @State private var animationScale: CGFloat = 0.1
    @State private var animationOpacity: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            // Achievement popup
            VStack(spacing: 20) {
                // Achievement icon with celebration
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text(achievement.icon)
                        .font(.system(size: 50))
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                }
                
                // Achievement title
                Text(String(localized: "🎉 Achievement Unlocked! 🎉"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(animationOpacity)
                
                // Achievement details
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(animationOpacity)
                
                // Share button
                ShareLink(
                    item: createAchievementShareText(achievement),
                    subject: Text(String(localized: "Achievement Unlocked!")),
                    message: Text(String(localized: "Check out this achievement I unlocked in LongevityMaster!"))
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(String(localized: "Share Achievement"))
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .opacity(animationOpacity)
                .padding(.horizontal)
                
                // Continue button
                Button(action: dismissPopup) {
                    Text(String(localized: "Continue"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .opacity(animationOpacity)
                .padding(.horizontal)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            
            // Confetti effect
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Play haptic feedback
        Haptics.shared.vibrateIfEnabled()
        
        // Animate popup appearance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationScale = 1.0
            animationOpacity = 1.0
        }
        
        // Show confetti after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showConfetti = true
            }
        }
    }
    
    private func dismissPopup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationScale = 0.1
            animationOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func createAchievementShareText(_ achievement: Achievement) -> String {
        let appName = "LongevityMaster"
        let appStoreURL = "https://apps.apple.com/app/id\(Constants.AppID.longevityMasterID)"
        
        var shareText = "🎉 Achievement Unlocked! 🎉\n\n"
        shareText += "🏆 \(achievement.title)\n"
        shareText += "📝 \(achievement.description)\n\n"
        
        if let unlockDate = achievement.unlockedDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            shareText += "📅 Unlocked on \(formatter.string(from: unlockDate))\n\n"
        }
        
        shareText += "💪 Keep building healthy habits with \(appName)!\n"
        shareText += "📱 Download: \(appStoreURL)"
        
        return shareText
    }
}

// Confetti effect view
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiParticleView(particle: particle)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                id: UUID(),
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                rotation: Double.random(in: 0...360),
                scale: Double.random(in: 0.5...1.5),
                color: [.red, .blue, .green, .yellow, .orange, .purple, .pink].randomElement() ?? .blue
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    let x: Double
    let y: Double
    let rotation: Double
    let scale: Double
    let color: Color
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    @State private var animationOffset: CGSize = .zero
    @State private var animationRotation: Double = 0
    @State private var animationOpacity: Double = 1
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: 8, height: 8)
            .scaleEffect(particle.scale)
            .position(
                x: UIScreen.main.bounds.width * particle.x + animationOffset.width,
                y: UIScreen.main.bounds.height * particle.y + animationOffset.height
            )
            .rotationEffect(.degrees(particle.rotation + animationRotation))
            .opacity(animationOpacity)
            .onAppear {
                animateParticle()
            }
    }
    
    private func animateParticle() {
        let randomOffset = CGSize(
            width: Double.random(in: -100...100),
            height: Double.random(in: -200...200)
        )
        let randomRotation = Double.random(in: -360...360)
        
        withAnimation(.easeOut(duration: 2.0)) {
            animationOffset = randomOffset
            animationRotation = randomRotation
            animationOpacity = 0
        }
    }
}

#Preview {
    AchievementPopupView(
        achievement: Achievement(
            id: 1,
            title: "First Steps",
            description: "Complete a habit 3 days in a row",
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: true,
            unlockedDate: Date(),
            habitID: nil
        ),
        isPresented: .constant(true)
    )
} 
