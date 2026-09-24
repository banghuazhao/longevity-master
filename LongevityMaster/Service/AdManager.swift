import GoogleMobileAds
import SwiftUI

class AdManager {
    struct GoogleAdsID {
        static let bannerViewAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String ?? ""
        static let appOpenAdID = Bundle.main.object(forInfoDictionaryKey: "appOpenAdID") as? String ?? ""
    }

    /// Every ad request in the app funnels through this. Consent is gathered by `ConsentManager`,
    /// which owns the ATT + UMP decision; nothing here reads either signal on its own.
    static var canRequestAds: Bool {
        ConsentManager.shared.hasResolved && ConsentManager.shared.canRequestAds
    }
}

final class OpenAd: NSObject, ObservableObject, FullScreenContentDelegate {
    var appOpenAd: AppOpenAd?
    var loadTime = Date()
    var appHasEnterBackgroundBefore = false

    func requestAppOpenAd() {
        guard AdManager.canRequestAds else { return }
        let request = Request()
        request.scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        AppOpenAd.load(
            with: AdManager.GoogleAdsID.appOpenAdID,
            request: request,
            completionHandler: { appOpenAdIn, error in
                if let error = error {
                    debugLog("[OPEN AD] Failed to load: \(error)")
                } else {
                    debugLog("[OPEN AD] Ad is ready")
                }
                self.appOpenAd = appOpenAdIn
                self.appOpenAd?.fullScreenContentDelegate = self
                self.loadTime = Date()
            }
        )
    }

    /// Called as the app comes back to the foreground. Whether the ad actually shows is up to
    /// `AppOpenAdPolicy`, and it never shows over a sheet the user has open.
    func tryToPresentAd() {
        guard AdManager.canRequestAds else { return }
        guard let ad = appOpenAd, wasLoadTimeLessThanNHoursAgo(thresholdN: 4) else {
            debugLog("[DEBUG] No ad loaded or ad expired, requesting new ad")
            requestAppOpenAd()
            return
        }
        guard appHasEnterBackgroundBefore else {
            debugLog("[DEBUG] appHasEnterBackgroundBefore is false, not presenting ad")
            return
        }
        // A tapped reminder reports itself just after the app becomes active, so give it a
        // moment to register before deciding.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard AppOpenAdPolicy.shouldPresent(), let presenter = Self.idlePresenter() else {
                debugLog("[DEBUG] App open ad held back")
                return
            }
            debugLog("[DEBUG] Presenting App Open Ad")
            ad.present(from: presenter)
        }
    }

    /// The root screen, if nothing is presented over it. Presenting from under an open sheet
    /// only fails, and interrupting one — a form half filled in, a share in progress — is
    /// worse than skipping the ad.
    private static func idlePresenter() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        guard let root = scene?.keyWindow?.rootViewController,
              root.presentedViewController == nil
        else { return nil }
        return root
    }

    func wasLoadTimeLessThanNHoursAgo(thresholdN: Int) -> Bool {
        let now = Date()
        let timeIntervalBetweenNowAndLoadTime = now.timeIntervalSince(loadTime)
        let secondsPerHour = 3600.0
        let intervalInHours = timeIntervalBetweenNowAndLoadTime / secondsPerHour
        return intervalInHours < Double(thresholdN)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        debugLog("[OPEN AD] Failed to present: \(error)")
        requestAppOpenAd()
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        AppOpenAdPolicy.recordShown()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        debugLog("[OPEN AD] Ad dismissed")
        requestAppOpenAd()
    }
}

struct BannerView: UIViewControllerRepresentable {
    @State var viewWidth: CGFloat = .zero
    private let bannerView = GoogleMobileAds.BannerView()
    private let adUnitID = AdManager.GoogleAdsID.bannerViewAdUnitID

    func makeUIViewController(context: Context) -> some UIViewController {
        let bannerViewController = BannerViewController()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerViewController.view.addSubview(bannerView)
        // Constrain GADBannerView to the bottom of the view.
        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(
                equalTo: bannerViewController.view.safeAreaLayoutGuide.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: bannerViewController.view.centerXAnchor),
        ])
        bannerViewController.delegate = context.coordinator

        return bannerViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard viewWidth != .zero, AdManager.canRequestAds else { return }

        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        let request = Request()
        request.scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        bannerView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewControllerWidthDelegate, BannerViewDelegate {
        let parent: BannerView

        init(_ parent: BannerView) {
            self.parent = parent
        }

        // MARK: - BannerViewControllerWidthDelegate methods

        func bannerViewController(
            _ bannerViewController: BannerViewController, didUpdate width: CGFloat
        ) {
            parent.viewWidth = width
        }

        // MARK: - BannerViewDelegate methods

        private func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            debugLog("DID RECEIVE Banner AD")
        }

        private func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            debugLog("DID NOT RECEIVE Banner AD: \(error.localizedDescription)")
        }
    }
}

protocol BannerViewControllerWidthDelegate: AnyObject {
    func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat)
}

class BannerViewController: UIViewController {
    weak var delegate: BannerViewControllerWidthDelegate?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        delegate?.bannerViewController(
            self, didUpdate: view.frame.inset(by: view.safeAreaInsets).size.width)
    }

    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            self.delegate?.bannerViewController(
                self, didUpdate: self.view.frame.inset(by: self.view.safeAreaInsets).size.width)
        }
    }
} 
