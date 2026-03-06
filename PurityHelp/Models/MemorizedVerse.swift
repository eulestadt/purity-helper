//
//  MemorizedVerse.swift
//  PurityHelp
//
//  User's progress on a verse for "Hide in your heart": learning or learned, last reviewed.
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
}
