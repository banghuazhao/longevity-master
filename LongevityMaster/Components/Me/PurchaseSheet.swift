import SwiftUI
import Dependencies

struct PurchaseSheet: View {
    @Dependency(\.purchaseManager) var purchaseManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemYellow).opacity(0.08).ignoresSafeArea()
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.leading, 12)
                .padding(.bottom, 8)
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
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(width: 90, height: 90)
                .padding(.bottom, 16)
                // Title & description
                Text("Upgrade to Premium and build better habits!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                Text("Unlock the full power of Longevity Master with these exclusive benefits:")
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
                    HStack(alignment: .top) {
                        Text("• ").font(.title3).fontWeight(.bold)
                        Text("Unlimited Habits: ")
                            .fontWeight(.semibold) + Text("Create and track as many healthy habits as you want—no limits.")
                    }
                }
                .font(.body)
                .padding(.horizontal)
                .padding(.bottom, 24)
                // Purchase button
                if let product = purchaseManager.removeAdsProduct {
                    Button(action: {
                        Task {
                            await purchaseManager.purchaseRemoveAds()
                            if purchaseManager.isRemoveAdsPurchased {
                                dismiss()
                            }
                        }
                    }) {
                        Text("\(product.displayPrice) - Upgrade to Premium")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(22)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 18)
                    .disabled(purchaseManager.isRemoveAdsPurchased)
                } else {
                    ProgressView()
                }
                // Links
                VStack(spacing: 10) {
                    Button("Restore Purchases") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .foregroundColor(.blue)
                    Button("Contact Support") {
                        if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/contact/") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.blue)
                    Button("Privacy Policy") {
                        if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/privacy/") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.blue)
                }
                .font(.body)
                .padding(.bottom, 24)
                Spacer()
            }
        }
        .task {
            await purchaseManager.loadProducts()
        }
    }
}

#Preview {
    PurchaseSheet()
} 
