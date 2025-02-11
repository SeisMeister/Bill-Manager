//
//  AppDelegate.swift
//  BillManager
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private let remindActionID = "RemindAction"
    private let markAsPaidActionID = "MarkAsPaidAction"
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.identifier
        guard var bill = Database.shared.getBill(notificationID: id) else { return }
        
        switch response.actionIdentifier {
        case remindActionID:
            let newRemindDate = Date().addingTimeInterval(60 * 60)
            bill.scheduleReminder(on: newRemindDate) { updateBill in
                Database.shared.updateAndSave(updateBill)
            }
        case markAsPaidActionID:
            bill.paidDate = Date()
            Database.shared.updateAndSave(bill)
        default:
            break
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.list, .banner, .sound]
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let remindAction = UNNotificationAction(identifier: remindActionID, title: "Remind me later")
        let markAsPaidAction = UNNotificationAction(identifier: markAsPaidActionID, title: "Mark as paid", options: [.authenticationRequired])
        
        let category = UNNotificationCategory(
            identifier: Bill.notificationCategoryID,
            actions: [remindAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

