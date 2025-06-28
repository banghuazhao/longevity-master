//
//  MoreAppsView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/6/27.
//

import SwiftUI

struct MoreAppsView: View {
    let apps = AppItemStore.allItems

    var body: some View {
        List(apps) { app in
            Button(action: {
                if let url = app.url {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 16) {
                    if let icon = app.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.title)
                            .font(.headline)

                        Text(app.detail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("More Apps")
    }
}
