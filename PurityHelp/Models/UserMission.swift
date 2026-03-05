//
//  UserMission.swift
//  PurityHelp
//
//  Personal "Why" / mission (e.g. "For my marriage," "To be the man God made me to be").
//

import Foundation
import SwiftData

@Model
final class UserMission {
    var text: String = ""
    var updatedAt: Date = Date.now

    init(text: String = "", updatedAt: Date = .now) {
        self.text = text
        self.updatedAt = updatedAt
    }
}
