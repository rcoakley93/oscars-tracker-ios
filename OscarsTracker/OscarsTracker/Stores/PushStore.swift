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
///
/// The reminders' switches, voice and time zone (P6-04) live on the server,
/// which sends the reminders. The voice is picked on this device (Profile →
/// Voice), so it and the time zone are sent up whenever they differ.
@Observable
final class PushStore {
    private(set) var status: UNAuthorizationStatus = .notDetermined
    private(set) var token: String?
    private(set) var preferences = NotificationPreferences.defaults
    /// What the server last confirmed, which a failed save goes back to.
    private var confirmed = NotificationPreferences.defaults
    /// Preferences being saved.
    private(set) var isSaving = false
    var actionError: AppError?

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
        preferences = .defaults
        confirmed = .defaults
        guard let token else { return }
        try? await data.removeDevice(token: token)
    }

    // MARK: - Reminders (P6-04)

    /// The voice picked on this device.
    private var deviceVoice: Voice {
        UserDefaults.standard.string(forKey: Voice.storageKey).flatMap(Voice.init) ?? .host
    }

    /// Loads your preferences, then saves this device's voice and time zone
    /// if the server has others, or no row yet. Offline, what's shown stays.
    func loadPreferences(userID: String, timeZone: TimeZone = .current) async {
        let stored: NotificationPreferences?
        do {
            stored = try await data.notificationPreferences(userID: userID)
        } catch {
            return
        }
        guard !isSaving else { return }
        preferences = stored ?? .defaults
        confirmed = preferences
        var wanted = preferences
        wanted.voice = deviceVoice.rawValue
        wanted.timeZone = timeZone.identifier
        guard stored == nil || wanted != stored else { return }
        if let saved = try? await data.saveNotificationPreferences(wanted), !isSaving {
            preferences = saved
            confirmed = saved
        }
    }

    /// Turns one reminder on or off. Saving puts everything back to what the
    /// server last confirmed if it fails.
    func set(_ reminder: NotificationPreferences.Reminder, _ on: Bool) async {
        preferences[reminder] = on
        await save()
    }

    /// Profile → Voice changed: reminders follow it.
    func setVoice(_ voice: Voice) async {
        guard preferences.voice != voice.rawValue else { return }
        preferences.voice = voice.rawValue
        await save()
    }

    /// One save at a time: each sends the whole row, so a change made while
    /// one is in flight is sent after it, in order, and a late answer never
    /// overwrites a newer switch.
    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        while preferences != confirmed {
            let sending = preferences
            do {
                let saved = try await data.saveNotificationPreferences(sending)
                confirmed = saved
                if preferences == sending { preferences = saved }
            } catch {
                preferences = confirmed
                actionError = AppError(error)
                return
            }
        }
    }
}
