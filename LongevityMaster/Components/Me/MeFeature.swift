//
// Created by Banghua Zhao on 21/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct MeView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    moreView
                }
            }
            .navigationTitle("Longevity Master")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var moreView: some View {
        
        VStack(alignment: .leading) {
            

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                NavigationLink(destination: MoreAppsView()) {
                    moreItem(icon: "storefront", title: "More Apps")
                }
                if let url = URL(string: "https://itunes.apple.com/app/id\(Constants.AppID.longevityMasterID)?action=write-review") {
                                Button {
                                    openURL(url)
                                } label: {
                                    moreItem(icon: "star.fill", title: "Rate Us")
                                }
                            }
                
                Button {
                    let email = SupportEmail()
                    email.send(openURL: openURL)
                } label: {
                    moreItem(icon: "envelope.fill", title: "Feedback")
                }
                if let appURL = URL(string: "https://itunes.apple.com/app/id\(Constants.AppID.longevityMasterID)") {
                    ShareLink(item: appURL) {
                        moreItem(icon: "square.and.arrow.up", title: "Share App")
                    }
                }

                }

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
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]), startPoint: .top, endPoint: .bottom))
        Text(title)
            .font(.caption)
            .foregroundColor(.black)
            .padding(.horizontal, 4)
            .background(Color.white.opacity(0.7)) // Optional: Adds a semi-transparent white background
            .cornerRadius(4) // Optional: Rounds the background edges
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

#Preview {
    MeView()
}

struct SupportEmail {
    let toAddress = "appsbayarea@gmail.com"
    let subject: String = String(localized: "\("LongevityMaster") - \("Feedback")")
    var body: String { """
      Application Name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
      iOS Version: \(UIDevice.current.systemVersion)
      Device Model: \(UIDevice.current.model)
      App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "no app version")
      App Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "no app build version")

      \(String(localized: "Please describe your issue below"))
      ------------------------------------

    """ }

    func send(openURL: OpenURLAction) {
        let replacedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let replacedBody = body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "mailto:\(toAddress)?subject=\(replacedSubject)&body=\(replacedBody)"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted { // e.g. Simulator
                print("Device doesn't support email.\n \(body)")
            }
        }
    }
}
