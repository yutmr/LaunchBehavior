//
//  LaunchBehavior.swift
//  LaunchBehavior
//
//  Created by Yu Tamura on 2018/05/13.
//  Copyright © 2018年 Yu Tamura. All rights reserved.
//

import Foundation
import UserNotifications

public enum LaunchSource {
    case direct

    case notification([AnyHashable: Any])

    case urlScheme(URL)

    case universalLinks(URL)
}

public protocol LaunchBehaviorDelegate: class {
    func launchBehavior(_ launchBehavior: LaunchBehavior, didLaunchApplication launchSouce: LaunchSource)
}

public final class LaunchBehavior {
    private(set) var currentLaunch: LaunchSource?

    public weak var delegate: LaunchBehaviorDelegate?

    public init() {
    }

    private func setCurrentLaunch(_ launchSource: LaunchSource) {
        guard currentLaunch == nil else {
            return
        }
        currentLaunch = launchSource
        delegate?.launchBehavior(self, didLaunchApplication: launchSource)
    }

    private func clear() {
        currentLaunch = nil
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        setCurrentLaunch(.direct)
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        clear()
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) {
        setCurrentLaunch(.urlScheme(url))
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]?) -> Void
    ) {
        guard let url = userActivity.webpageURL else {
            return
        }
        switch userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
            setCurrentLaunch(.universalLinks(url))
        default:
            break
        }
    }

    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        switch application.applicationState {
        case .inactive:
            if #available(iOS 10.0, *) {
            } else {
                setCurrentLaunch(.notification(userInfo))
            }
        default:
            break
        }
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        switch UIApplication.shared.applicationState {
        case .inactive:
            setCurrentLaunch(.notification(userInfo))
        default:
            break
        }
    }
}
