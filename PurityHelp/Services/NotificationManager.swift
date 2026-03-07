//
//  NotificationManager.swift
//  PurityHelp
//
//  Central manager for handling local notifications like the "Daily Pause".
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let dailyPauseID = "purityHelp.dailyPause"

    private init() {}

    /// Requests permission from the user to show alerts and play sounds.
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    /// Schedules or cancels the daily pause reminder.
    func updateDailyPauseReminder(isEnabled: Bool, hour: Int, minute: Int) {
        // Always clear existing notifications for this ID first to avoid duplicates
        center.removePendingNotificationRequests(withIdentifiers: [dailyPauseID])

        guard isEnabled else {
            print("Daily pause reminder disabled.")
            return
        }

        // Create the content
        let content = UNMutableNotificationContent()
        content.title = "A Moment for Your Journey"
        content.body = "You are worthy of a pure heart. Pause for a moment to guard your heart and refocus."
        content.sound = .default

        // Create the trigger (recurrent daily at specific hour/minute)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create the request
        let request = UNNotificationRequest(
            identifier: dailyPauseID,
            content: content,
            trigger: trigger
        )

        // Schedule
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Daily pause scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}
