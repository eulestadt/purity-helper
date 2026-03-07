//
//  MemorizedVerse.swift
//  PurityHelp
//
//  User's progress on a verse for "Hide in your heart", including Spaced Repetition scheduling.
//

import Foundation
import SwiftData

@Model
final class MemorizedVerse {
    /// Verse id matching ScriptureService (e.g. "prov4_23", "ps119_11").
    var verseId: String = ""
    var updatedAt: Date = Date.now
    /// "learning" or "learned"
    var status: String = "learning"
    var lastReviewedDate: Date? = nil
    var customReference: String? = nil
    var customText: String? = nil
    var customTranslation: String? = nil
    
    // MARK: - Spaced Repetition System (SRS) Properties
    /// When this verse should be reviewed next
    var nextReviewDate: Date = Date.now
    /// Current interval in days between reviews
    var interval: Int = 0
    /// Multiplier for the next interval (Base: 2.5)
    var easeFactor: Double = 2.5
    /// Number of consecutive successful reviews
    var repetition: Int = 0

    init(verseId: String = "", updatedAt: Date = .now, status: String = "learning", lastReviewedDate: Date? = nil, customReference: String? = nil, customText: String? = nil, customTranslation: String? = nil) {
        self.verseId = verseId
        self.updatedAt = updatedAt
        self.status = status
        self.lastReviewedDate = lastReviewedDate
        self.customReference = customReference
        self.customText = customText
        self.customTranslation = customTranslation
    }
    
    func toScriptureVerse() -> ScriptureVerse? {
        if let customReference, let customText {
            return ScriptureVerse(id: verseId, reference: customReference, text: customText, translation: customTranslation)
        }
        return nil
    }
    
    // MARK: - SRS Logic
    
    /// Processes a review using a simplified SM-2 algorithm.
    /// - Parameter success: `true` if the user remembered it ("Learned!"), `false` if they struggled ("Still Learning").
    func processReview(success: Bool) {
        self.lastReviewedDate = Date.now
        self.updatedAt = Date.now
        
        if success {
            // Passed
            if repetition == 0 {
                interval = 1
            } else if repetition == 1 {
                interval = 3
            } else {
                interval = Int(round(Double(interval) * easeFactor))
            }
            repetition += 1
            // Maintain or slightly increase ease
            easeFactor = min(3.0, easeFactor + 0.1)
            // Ensure status is marked as learned if they're successfully reviewing it
            status = "learned"
        } else {
            // Failed / Still Learning
            repetition = 0
            interval = 1
            // Decrease ease factor, but floor it at 1.3
            easeFactor = max(1.3, easeFactor - 0.2)
            status = "learning"
        }
        
        // Calculate the next review date by adding 'interval' days to today
        if let nextDate = Calendar.current.date(byAdding: .day, value: interval, to: Date.now) {
            self.nextReviewDate = Calendar.current.startOfDay(for: nextDate) // Reviews unlock at midnight
        }
    }
}
