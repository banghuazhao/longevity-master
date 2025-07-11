import SwiftUI
import Dependencies

struct PurchaseSheet: View {
    @Dependency(\.purchaseManager) var purchaseManager
    @Dependency(\.themeManager) var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showSuccessModal = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemYellow).opacity(0.08).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Close button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .appCircularButtonStyle()
                        }
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.leading, 12)

                    // Top image
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: 90, height: 90)
                        .mask(
                            Image(systemName: "leaf.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .frame(width: 90, height: 90)
                    
                    // Title & description
                    Text("Upgrade to Premium and build better habits!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    Text("Unlock the full power of Longevity Master with exclusive benefit:")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text("• ").font(.title3).fontWeight(.bold)
                            Text("No Ads: ")
                                .fontWeight(.semibold) + Text("Enjoy a clean, ad-free habit tracking experience.")
                        }
                        //HStack(alignment: .top) {
                        //    Text("• ").font(.title3).fontWeight(.bold)
                        //    Text("Unlimited Habits: ")
                        //        .fontWeight(.semibold) + Text("Create and track as many healthy habits as you want—no limits.")
                        //}
                    }
                    .font(.body)
                    .padding(.horizontal)

                    // Purchase button
                    if let product = purchaseManager.premiumProduct {
                        if purchaseManager.isPremiumUserPurchased {
                            Text("You are now Premium user!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                        } else {
                            Button(action: {
                                Task {
                                    isPurchasing = true
                                    let result = await purchaseManager.purchasePremium()
                                    switch result {
                                    case .success:
                                        showSuccessModal = true
                                    case .failure(let error):
                                        print("Purchase failed: \(error.localizedDescription)")
                                    }
                                    isPurchasing = false
                                }
                            }) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text("\(product.displayPrice) - Upgrade to Premium")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(themeManager.current.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .disabled(isPurchasing)
                        }
                    } else {
                        ProgressView()
                    }
                    // Links
                    VStack(spacing: 16) {
                        Button("Restore Purchases") {
                            Task {
                                isPurchasing = true
                                await purchaseManager.restorePurchases()
                                isPurchasing = false
                            }
                        }
                        .foregroundColor(themeManager.current.primaryColor)
                        
                        Button("Contact Support") {
                            if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/contact/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(themeManager.current.primaryColor)
                        
                        Button("Privacy Policy") {
                            if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/privacy/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(themeManager.current.primaryColor)
                    }
                    .font(.body)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showSuccessModal) {
            PremiumSuccessView()
        }
        .task {
            await purchaseManager.loadPremiumProduct()
        }
    }
}

struct ConfettiDot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
}

struct PremiumSuccessView: View {
    var onContinue: (() -> Void)? = nil
    @State private var animate = false
    @Environment(\.dismiss) var dismiss
    
    private let confetti: [ConfettiDot] = (0..<20).map { _ in
        ConfettiDot(
            x: CGFloat.random(in: 40...340),
            y: CGFloat.random(in: 40...600),
            color: [Color.yellow, Color.orange, Color.green, Color.blue, Color.pink, Color.purple].randomElement()!,
            size: CGFloat.random(in: 8...16)
        )
    }

    var body: some View {
        ZStack {
            Color.white.opacity(0.4).ignoresSafeArea()

            // Confetti
            ForEach(confetti) { dot in
                Circle()
                    .fill(dot.color)
                    .frame(width: dot.size, height: dot.size)
                    .position(x: dot.x, y: animate ? dot.y : dot.y - 80)
                    .opacity(0.7)
                    .animation(.easeOut(duration: 1.2), value: animate)
            }

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.5), Color.orange.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 120, height: 120)
                        .blur(radius: 8)
                    Image(systemName: "crown.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow, radius: 12)
                }
                Text("Congratulations!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Text("💎 Thanks for being a Premium member!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                        Text("Ad-free experience")
                    }
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("Thank you for supporting Longevity Master!")
                    }
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.white, Color.yellow.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
            )
            .shadow(radius: 24)
            .padding(.horizontal, 24)
            .onAppear { animate = true }
        }
    }
}

#Preview {
    PurchaseSheet()
} 
