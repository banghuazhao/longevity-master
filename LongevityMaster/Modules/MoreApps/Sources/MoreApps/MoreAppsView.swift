//
//  MoreAppsView.swift
//  MoreApps
//
//  Created by Lulin Yang on 2025/6/27.
//

#if canImport(UIKit)
import SwiftUI

public struct MoreAppsView: View {
    private let apps: [AppItem]
    
    public init(apps: [AppItem] = AppItemStore.allItems) {
        self.apps = apps
    }

    public var body: some View {
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
                            .foregroundColor(.primary)
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
            .buttonStyle(.plain)
        }
        .navigationTitle(String(localized: "More Apps", bundle: .module))
    }
}
#endif 
