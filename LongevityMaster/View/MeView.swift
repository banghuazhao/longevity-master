//
// Created by Banghua Zhao on 21/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct MeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    moreView
                }
            }
            .navigationTitle("Me")
        }
    }

    private var moreView: some View {
        VStack(alignment: .leading) {
            Text("More")
                .font(.subheadline)
                .padding(.leading)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                moreItem(icon: "storefront", title: "More Apps")
                moreItem(icon: "star.fill", title: "Rate Us")
                moreItem(icon: "envelope.fill", title: "Email")
            }
            .padding()
        }
    }

    private func moreItem(icon: String, title: String) -> some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.red)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MeView()
}
