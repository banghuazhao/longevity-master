import AdSupport
import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

class AdManager {
    static var isAuthorized = false

    struct GoogleAdsID {
        static let bannerViewAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String ?? ""
        static let appOpenAdID = Bundle.main.object(forInfoDictionaryKey: "appOpenAdID") as? String ?? ""
    }

    static func requestATTPermission(with time: TimeInterval = 0) {
        guard !isAuthorized else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("Authorized")
                    isAuthorized = true
    
                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknown")
                }
            }
        }
    }
}

final class OpenAd: NSObject, ObservableObject, FullScreenContentDelegate {
    var appOpenAd: AppOpenAd?
    var loadTime = Date()
    var appHasEnterBackgroundBefore = false
    var bypassAdThisTime = false

    func requestAppOpenAd() {
        print("[DEBUG] requestAppOpenAd called")
        let request = Request()
        request.scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        AppOpenAd.load(
            with: AdManager.GoogleAdsID.appOpenAdID,
            request: request,
            completionHandler: { appOpenAdIn, error in
                if let error = error {
                    print("[OPEN AD] Failed to load: \(error)")
                } else {
                    print("[OPEN AD] Ad is ready")
                }
                self.appOpenAd = appOpenAdIn
                self.appOpenAd?.fullScreenContentDelegate = self
                self.loadTime = Date()
            }
        )
    }

    func tryToPresentAd() {
        print("[DEBUG] tryToPresentAd called")
        if let gOpenAd = appOpenAd, wasLoadTimeLessThanNHoursAgo(thresholdN: 4) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            if bypassAdThisTime {
                bypassAdThisTime = false
                return
            }
            if appHasEnterBackgroundBefore {
                print("[DEBUG] Presenting App Open Ad")
                gOpenAd.present(from: (window?.rootViewController)!)
            } else {
                print("[DEBUG] appHasEnterBackgroundBefore is false, not presenting ad")
            }
        } else {
            print("[DEBUG] No ad loaded or ad expired, requesting new ad")
            requestAppOpenAd()
        }
    }

    func wasLoadTimeLessThanNHoursAgo(thresholdN: Int) -> Bool {
        let now = Date()
        let timeIntervalBetweenNowAndLoadTime = now.timeIntervalSince(loadTime)
        let secondsPerHour = 3600.0
        let intervalInHours = timeIntervalBetweenNowAndLoadTime / secondsPerHour
        return intervalInHours < Double(thresholdN)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[OPEN AD] Failed to present: \(error)")
        requestAppOpenAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[OPEN AD] Ad dismissed")
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
        guard viewWidth != .zero else { return }

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
            print("DID RECEIVE Banner AD")
        }

        private func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("DID NOT RECEIVE Banner AD: \(error.localizedDescription)")
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
