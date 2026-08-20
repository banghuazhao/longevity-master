//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AppTrackingTransparency
import Dependencies
import GoogleMobileAds
import Observation
import SwiftUI
import UserMessagingPlatform

/// The single place that decides whether we may serve ads at all, and whether those ads may be
/// personalised. Nothing else in the app is allowed to read ATT or UMP and reach its own
/// conclusion — every ad load and every SDK start goes through `canRequestAds` /
/// `canUsePersonalizedAds` here, so a denial in either prompt is impossible to route around.
@Observable
final class ConsentManager {
    static let shared = ConsentManager()

    /// True once the ad SDK has been started. Started lazily, only after consent resolves.
    private(set) var isMobileAdsStarted = false

    /// True once `resolve()` has finished a pass, so callers can tell "not asked yet" apart from
    /// "asked, and the answer is no". Ads must never load while this is false.
    private(set) var hasResolved = false

    /// Whether the user can be shown the privacy options form (EEA/UK and other regulated
    /// regions). Drives the visibility of the Settings entry.
    private(set) var isPrivacyOptionsRequired = false

    private init() {}

    // MARK: - The resolver

    /// UMP's own view of whether any ad request is lawful. Outside regulated regions UMP reports
    /// `notRequired` and this is true without a form ever being shown.
    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    /// Personalised ads need *both* signals to be positive, whichever prompt the user saw first:
    /// TCF consent for the purposes that personalisation depends on, and ATT authorised. A denial
    /// in either one drops us to non-personalised ads. This is the "most restrictive wins" rule,
    /// and it is order-independent by construction because it re-reads both every time.
    var canUsePersonalizedAds: Bool {
        canRequestAds
            && hasTCFConsentForPersonalization
            && ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    /// Whether the user's TCF answers permit the things personalisation needs.
    ///
    /// `consentStatus == .obtained` is *not* this signal: UMP reports `.obtained` once any answer
    /// exists, including a rejection. Likewise `canRequestAds` stays true after a rejection,
    /// because serving non-personalised ads is still lawful. The real answers live in the TCF
    /// string that UMP writes into UserDefaults under the IAB keys.
    private var hasTCFConsentForPersonalization: Bool {
        let defaults = UserDefaults.standard
        // Absent or 0 means GDPR does not apply to this user, so there is nothing to gate on.
        guard defaults.object(forKey: "IABTCF_gdprApplies") != nil,
              defaults.integer(forKey: "IABTCF_gdprApplies") == 1
        else { return true }

        guard let purposes = defaults.string(forKey: "IABTCF_PurposeConsents") else { return false }
        func consented(toPurpose purpose: Int) -> Bool {
            let index = purpose - 1
            guard index >= 0, index < purposes.count else { return false }
            return purposes[purposes.index(purposes.startIndex, offsetBy: index)] == "1"
        }
        // Purpose 1 covers storing/accessing information on the device, which is what reading the
        // IDFA depends on; purposes 3 and 4 cover building ad profiles and selecting
        // personalised ads.
        return consented(toPurpose: 1) && consented(toPurpose: 3) && consented(toPurpose: 4)
    }

    // MARK: - First-launch flow

    /// Gathers UMP consent first and only then asks for ATT — the order Google documents, and the
    /// one that keeps us from asking to track someone who has already said no.
    ///
    /// Must be called once the UI is on screen: `requestTrackingAuthorization` silently resolves
    /// to `.denied` if the app is not foreground-active.
    @MainActor
    func resolve() async {
        await requestConsentInfoUpdate()

        if ConsentInformation.shared.formStatus == .available {
            await loadAndPresentConsentFormIfRequired()
        }

        isPrivacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required

        // ATT comes after UMP, and only if the user's TCF answers actually permit device storage
        // and ad personalisation. Gating on `canRequestAds` here would be wrong: it stays true
        // after a rejection, and we would end up asking to track someone who just said no.
        if hasTCFConsentForPersonalization {
            await requestTrackingAuthorizationIfNeeded()
        }

        hasResolved = true
        startMobileAdsIfAllowed()

        #if DEBUG
            print("[CONSENT] status=\(ConsentInformation.shared.consentStatus.rawValue) "
                + "canRequestAds=\(canRequestAds) form=\(ConsentInformation.shared.formStatus.rawValue) "
                + "privacyOptions=\(ConsentInformation.shared.privacyOptionsRequirementStatus.rawValue) "
                + "att=\(ATTrackingManager.trackingAuthorizationStatus.rawValue) "
                + "tcf=\(hasTCFConsentForPersonalization) personalized=\(canUsePersonalizedAds)")
        #endif
    }

    @MainActor
    private func requestConsentInfoUpdate() async {
        let parameters = RequestParameters()
        // The app is rated 4+ but is not directed to children; we do not knowingly collect from
        // under-age users, and we do not tag the request as under-age-of-consent.
        parameters.isTaggedForUnderAgeOfConsent = false

        #if DEBUG
            // Lets us exercise the EEA consent form away from Europe. Simulators are registered
            // as UMP test devices automatically. Compiled out of Release, so a shipped build can
            // never fake its geography or reset a real user's consent.
            let debugSettings = DebugSettings()
            debugSettings.geography = .EEA
            parameters.debugSettings = debugSettings

            // Opt-in, not automatic: clearing consent on every launch would make it impossible to
            // check that a stored choice actually survives a restart.
            if ProcessInfo.processInfo.arguments.contains("-resetConsent") {
                ConsentInformation.shared.reset()
            }
        #endif

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    debugLog("[CONSENT] Info update failed: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    @MainActor
    private func loadAndPresentConsentFormIfRequired() async {
        guard let root = Self.topViewController else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.loadAndPresentIfRequired(from: root) { error in
                if let error {
                    debugLog("[CONSENT] Form presentation failed: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    /// ATT is asked at most once. After a denial the system will not show the sheet again, and we
    /// do not draw a replacement prompt of our own to work around that.
    @MainActor
    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // iOS silently resolves the request to `.denied` without ever showing the sheet if the
        // app is not foreground-active — which it is not while another system alert (the
        // notification permission prompt) is still up. Wait for the app to come back to active
        // first, otherwise we would burn the one chance the user gets to see this.
        guard await waitUntilActive() else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// Waits for the app to become foreground-active, up to `timeout`. Returns false if it never
    /// gets there, in which case we simply try again on the next launch rather than asking into
    /// the void.
    @MainActor
    private func waitUntilActive(timeout: Duration = .seconds(10)) async -> Bool {
        if UIApplication.shared.applicationState == .active { return true }
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(250))
            if UIApplication.shared.applicationState == .active { return true }
        }
        return false
    }

    // MARK: - Ad SDK start

    /// The ad SDK is not started until consent says we may request ads, so no ad request can
    /// precede the user's answer.
    func startMobileAdsIfAllowed() {
        guard !isMobileAdsStarted, canRequestAds else { return }
        isMobileAdsStarted = true

        let configuration = MobileAds.shared.requestConfiguration
        // The app ships as 4+ in Health & Fitness, so cap creatives at general audiences.
        configuration.maxAdContentRating = .general
        configuration.tagForChildDirectedTreatment = false
        configuration.tagForUnderAgeOfConsent = false

        MobileAds.shared.start(completionHandler: nil)
    }

    // MARK: - Withdrawal

    /// Reopens the UMP privacy options form so a user can change or withdraw a choice they have
    /// already made. Withdrawing has to be as easy as giving.
    @MainActor
    func presentPrivacyOptionsForm() async {
        guard let root = Self.topViewController else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.presentPrivacyOptionsForm(from: root) { error in
                if let error {
                    debugLog("[CONSENT] Privacy options form failed: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Helpers

    /// The view controller actually on screen. Presenting from the window's root fails outright
    /// while onboarding's `fullScreenCover` is up ("already presenting another view controller"),
    /// which would leave an EEA user unable to consent at all — and so with no ads ever.
    @MainActor
    private static var topViewController: UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - DependencyKey for ConsentManager

private enum ConsentManagerKey: DependencyKey {
    static let liveValue = ConsentManager.shared
}

extension DependencyValues {
    var consentManager: ConsentManager {
        get { self[ConsentManagerKey.self] }
        set { self[ConsentManagerKey.self] = newValue }
    }
}
