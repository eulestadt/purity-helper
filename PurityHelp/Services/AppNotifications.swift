//
//  AppNotifications.swift
//  PurityHelp
//
//  Shared Notification.Name constants to avoid string literals.
//

import Foundation

extension Notification.Name {
    /// Posted immediately after a user successfully logs in via CloudAuthView.
    static let userDidLogin = Notification.Name("purityHelp.userDidLogin")
}
