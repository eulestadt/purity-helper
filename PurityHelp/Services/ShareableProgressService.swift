//
//  ShareableProgressService.swift
//  PurityHelp
//
//  Generate read-only summary and export for accountability partner.
//

import Foundation
import SwiftData

struct ShareableProgressService {
    static func generateSummary(
        streakRecord: StreakRecord?,
        urgeLogs: [UrgeLog],
        hoursReclaimed: Int?
    ) -> String {
        guard let r = streakRecord else { return "No streak data yet." }
        var lines: [String] = [
            "Purity Help – Progress summary",
            "Generated \(Date().formatted())",
            "",
            "Days of purity (pornography): \(r.pornographyStreakDays)",
            "Days of purity (masturbation): \(r.masturbationStreakDays)"
        ]
        if r.pureThoughtsEnabled {
            lines.append("Days guarding thoughts: \(r.pureThoughtsStreakDays)")
        }
        lines.append("Urge moments logged: \(urgeLogs.count)")
        if let h = hoursReclaimed, h > 0 {
            lines.append("Hours reclaimed: \(h)")
        }
        return lines.joined(separator: "\n")
    }
}
