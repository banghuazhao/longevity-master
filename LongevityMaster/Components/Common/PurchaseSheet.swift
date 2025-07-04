import SwiftUI
import Dependencies

struct PurchaseSheet: View {
    @Dependency(\.purchaseManager) var purchaseManager
    @Dependency(\.themeManager) var themeManager
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    Text("Unlock the full power of Longevity Master with these exclusive benefits:")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text("• ").font(.title3).fontWeight(.bold)
                            Text("No Ads: ")
                                .fontWeight(.semibold) + Text("Enjoy a clean, ad-free habit tracking experience.")
                        }
//                        HStack(alignment: .top) {
//                            Text("• ").font(.title3).fontWeight(.bold)
//                            Text("Unlimited Habits: ")
//                                .fontWeight(.semibold) + Text("Create and track as many healthy habits as you want—no limits.")
//                        }
                    }
                    .font(.body)
                    .padding(.horizontal)
                    .padding(.bottom)
                    
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
                                .background(themeManager.current.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                        .padding(.horizontal)
                        .disabled(purchaseManager.isRemoveAdsPurchased)
                    } else {
                        ProgressView()
                    }
                    
                    // Links
                    VStack(spacing: 16) {
                        Button("Restore Purchases") {
                            Task { await purchaseManager.restorePurchases() }
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
        .task {
            await purchaseManager.loadProducts()
        }
    }
}

#Preview {
    PurchaseSheet()
} 
