//
//  NotificationService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 29/10/2026.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    // Request permissions.
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    // Check if notifications are authorized.
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized ||
                                   settings.authorizationStatus == .provisional ||
                                   settings.authorizationStatus == .ephemeral
                completion(isAuthorized)
            }
        }
    }
    
    // Sync notifications.
    func syncNotifications(tasks: [TaskModel], plants: [Plant], gardens: [Garden]) {
        let isEnabled = UserDefaults.standard.bool(forKey: "isTaskRemindersEnabled")
        guard isEnabled else {
            clearAllNotifications()
            return
        }
        
        checkAuthorizationStatus { isAuthorized in
            guard isAuthorized else { return }
            
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            
            for task in tasks {
                guard let plant = plants.first(where: { $0.id == task.plantId }),
                      let garden = gardens.first(where: { $0.id == plant.gardenId }) else { continue }
                
                let latitude = garden.geoLocation.first
                guard let notifDate = task.notificationDate(latitude: latitude),
                      notifDate > Date() else { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "Task Due: \(task.name)"
                content.body = "Your plant \(plant.name) needs attention."
                content.sound = .default
                content.userInfo = ["taskId": task.id, "cycle": task.currentCycle]
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(identifier: "task_\(task.id)_cycle_\(task.currentCycle)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
    
    // Clear all pending.
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
