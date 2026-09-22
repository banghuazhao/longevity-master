//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// A share button that shows the card first. Seeing the image before sending it is what makes
/// people send it; a bare share sheet of text was easy to dismiss.
struct ShareCardLink<Label: View>: View {
    let content: ShareCardContent
    @ViewBuilder let label: () -> Label

    @State private var isPresented = false

    var body: some View {
        Button {
            Haptics.shared.vibrateIfEnabled()
            isPresented = true
        } label: {
            label()
        }
        .sheet(isPresented: $isPresented) {
            ShareCardSheet(content: content)
        }
    }
}

/// Previews the card and hands the rendered image to the system share sheet.
struct ShareCardSheet: View {
    let content: ShareCardContent

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Dependency(\.themeManager) private var themeManager

    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.large) {
                GeometryReader { proxy in
                    let scale = min(
                        proxy.size.width / ShareCardView.size.width,
                        proxy.size.height / ShareCardView.size.height
                    )
                    // Rounded here only: the shared image keeps square corners, which is
                    // what stories and chats expect to crop and round themselves.
                    cardView
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .scaleEffect(scale)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                }
                .padding(.horizontal, AppSpacing.large)

                if let image {
                    let preview = Image(uiImage: image)
                    ShareLink(
                        item: preview,
                        subject: Text(content.headline),
                        message: Text(content.message),
                        preview: SharePreview(content.headline, image: preview)
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.current.primaryColor, in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
                    }
                    .padding(.horizontal, AppSpacing.large)
                } else {
                    ProgressView()
                        .frame(height: 54)
                }
            }
            .padding(.vertical, AppSpacing.medium)
            .appBackground()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .appToolbarCircularButtonStyle()
                    }
                }
            }
            .task(id: content) {
                image = render()
            }
        }
        .presentationDetents([.large])
    }

    private var cardView: ShareCardView {
        ShareCardView(content: content, tint: themeManager.current.primaryColor)
    }

    /// At least 3× so the image stays sharp once a story or chat scales it up.
    private func render() -> UIImage? {
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = max(displayScale, 3)
        return renderer.uiImage
    }
}

#Preview {
    ShareCardSheet(
        content: .program(
            ProgramsDataStore.sleepReset,
            progress: ProgramProgress(dayNumber: 9, durationDays: 21, isFinished: false, adherence: 0.78, checkInCount: 31)
        )
    )
}
