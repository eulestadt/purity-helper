//
//  NotificationManager.swift
//

import Foundation
import UserNotifications

enum NotificationManager {
    static func scheduleDailyReminders() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        guard granted == true else { return }
        center.removePendingNotificationRequests(withIdentifiers: ["morning-offering", "evening-examen"])
        await add(id: "morning-offering", title: "Begin the day", body: "Offer the day, then open the Word.", hour: 7, minute: 30)
        await add(id: "evening-examen", title: "Look back", body: "The examen takes a few quiet minutes.", hour: 21, minute: 15)
    }

    private static func add(id: String, title: String, body: String, hour: Int, minute: Int) async {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
