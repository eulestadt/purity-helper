//
//  IfThenPlan.swift
//  PurityHelp
//
//  Implementation intentions: "When [trigger], I will [action]".
//

import Foundation
import SwiftData

@Model
final class IfThenPlan {
    var trigger: String = ""
    var action: String = ""
    var reminderEnabled: Bool = false
    var createdAt: Date = Date.now
    var order: Int = 0

    init(trigger: String, action: String, reminderEnabled: Bool = false, createdAt: Date = .now, order: Int = 0) {
        self.trigger = trigger
        self.action = action
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
        self.order = order
    }
}
