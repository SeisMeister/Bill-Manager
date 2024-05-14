//
//  Bill+Extras.swift
//  BillManager
//

import Foundation
import UserNotifications

extension Bill {
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = dueDate.formatted(date: .numeric, time: .omitted)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    mutating func scheduleReminder(on date: Date, completion: @escaping (Bill)->Void) {
        var updatedBill = self
        
        updatedBill.removeReminder()
        
        authorizeIfNeeded { granted in
            guard granted else {
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
                return
            }
            
            let content  = UNMutableNotificationContent()
            content.title = "Bill Reminder"
            content.body = String(
                format: "%@ due to %@ on %@",
                arguments:  [
                    (updatedBill.amount ?? 0).formatted(.currency(code: "usd")),
                    (updatedBill.payee ?? ""),
                    updatedBill.formattedDueDate
                ]
            )
            
            content.categoryIdentifier = Bill.notificationCategoryID
            content.sound = UNNotificationSound.default
            
            let triggerDateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let notificationID = UUID().uuidString
            
            let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error {
                        print(error.localizedDescription)
                    } else {
                        updatedBill.notificationID = notificationID
                        updatedBill.remindDate = date
                    }
                    DispatchQueue.main.async {
                        completion(updatedBill)
                    }
                }
            }
        }
    }
    
    mutating func removeReminder() {
        guard let id = notificationID else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        notificationID = id
        remindDate = nil
    }
    
    private func authorizeIfNeeded(completion: @escaping (Bool) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted)
                }
            case .authorized, .provisional:
                completion(true)
            case .ephemeral, .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
}
