import Foundation
import Observation
import UIKit
import UserNotifications

/// Which APNs host a device token belongs to: development builds get sandbox
/// tokens; TestFlight and the App Store get production ones.
nonisolated enum PushEnvironment: String, Sendable {
    case sandbox, production

    static var current: PushEnvironment {
        #if DEBUG
        .sandbox
        #else
        .production
        #endif
    }
}

/// Push notifications (P4-09). Permission is asked after your first saved
/// pick or watched film, never at launch. Once allowed, the device registers
/// with APNs and its token is saved to `devices`; signing out forgets it.
@Observable
final class PushStore {
    private(set) var status: UNAuthorizationStatus = .notDetermined
    private(set) var token: String?

    private let data: any AppDataSource
    /// Set once the question has been asked, so it's asked once.
    private var asked: Bool {
        get { UserDefaults.standard.bool(forKey: "push.asked") }
        set { UserDefaults.standard.set(newValue, forKey: "push.asked") }
    }

    init(data: any AppDataSource) {
        self.data = data
    }

    /// At launch and on return to the foreground: re-registers if allowed, as
    /// tokens can change.
    func refresh() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        if status == .authorized || status == .provisional || status == .ephemeral {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// After a first pick or watched film: asks, once.
    func askAfterFirstSave() async {
        guard !asked else { return }
        await ask()
    }

    /// Asks now (the Profile's "Turn on" button, or the first save).
    func ask() async {
        asked = true
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refresh()
        if !granted { status = .denied }
    }

    /// From the app delegate, with APNs' token.
    func didRegister(deviceToken: Data, userID: String?) async {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        token = hex
        guard userID != nil else { return }
        try? await data.registerDevice(token: hex, environment: .current)
    }

    /// After sign-in, saves a token that arrived while signed out.
    func signedIn() async {
        guard let token else { return }
        try? await data.registerDevice(token: token, environment: .current)
    }

    /// Before sign-out, so the next person on this phone doesn't get your pushes.
    func signingOut() async {
        guard let token else { return }
        try? await data.removeDevice(token: token)
    }
}
