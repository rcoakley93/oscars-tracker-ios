import UIKit
import UserNotifications

/// The UIKit hooks push needs (P4-09): APNs' device token, and opening the
/// right screen when a notification is tapped.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by the app at launch.
    var model: AppModel?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let model else { return }
        Task { await model.push.didRegister(deviceToken: deviceToken, userID: model.session.userID) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The Simulator without a push-capable account, or no network: the
        // next launch tries again.
    }

    /// Shows banners while the app is open too.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    /// On the main actor: a nonisolated version returns to UIKit off the
    /// main thread, which crashes the app on every tap.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let path = response.notification.request.content.userInfo["path"] as? String {
            model?.navigation.open(path: path)
        }
    }
}
