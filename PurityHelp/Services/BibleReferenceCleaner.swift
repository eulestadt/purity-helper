//
//  BibleReferenceCleaner.swift
//  PurityHelp
//
//  Utility to clean and normalize Bible references (e.g. "Jn" -> "John")
//  to improve search success rates in API.bible.
//

import Foundation

struct BibleReferenceCleaner {
    private static let bookMappings: [String: String] = [
        "Gen": "Genesis", "Exo": "Exodus", "Lev": "Leviticus", "Num": "Numbers", "Deu": "Deuteronomy",
        "Jos": "Joshua", "Judg": "Judges", "Rut": "Ruth", "1 Sam": "1 Samuel", "2 Sam": "2 Samuel",
        "1 Kin": "1 Kings", "2 Kin": "2 Kings", "1 Chr": "1 Chronicles", "2 Chr": "2 Chronicles",
        "Ezr": "Ezra", "Neh": "Nehemiah", "Est": "Esther", "Job": "Job", "Psa": "Psalms",
        "Pro": "Proverbs", "Ecc": "Ecclesiastes", "Sol": "Song of Solomon", "Isa": "Isaiah",
        "Jer": "Jeremiah", "Lam": "Lamentations", "Eze": "Ezekiel", "Dan": "Daniel", "Hos": "Hosea",
        "Joe": "Joel", "Amo": "Amos", "Oba": "Obadiah", "Jon": "Jonah", "Mic": "Micah",
        "Nah": "Nahum", "Hab": "Habakkuk", "Zep": "Zephaniah", "Hag": "Haggai", "Zec": "Zechariah",
        "Mal": "Malachi",
        "Mat": "Matthew", "Mar": "Mark", "Luk": "Luke", "Joh": "John", "Jn": "John", "Act": "Acts",
        "Rom": "Romans", "1 Cor": "1 Corinthians", "2 Cor": "2 Corinthians", "Gal": "Galatians",
        "Eph": "Ephesians", "Phi": "Philippians", "Col": "Colossians", "1 Thes": "1 Thessalonians",
        "2 Thes": "2 Thessalonians", "1 Tim": "1 Timothy", "2 Tim": "2 Timothy", "Tit": "Titus",
        "Phm": "Philemon", "Heb": "Hebrews", "Jam": "James", "1 Pet": "1 Peter", "2 Pet": "2 Peter",
        "1 Joh": "1 John", "2 Joh": "2 John", "3 Joh": "3 John", "Jud": "Jude", "Rev": "Revelation"
    ]

    private static let typoFixes: [String: String] = [
        "Gensis": "Genesis",
        "Gens": "Genesis",
        "Revelations": "Revelation",
        "Psalms": "Psalm", // API often prefers singular "Psalm" for refs
        "Phillipians": "Philippians",
        "Phillippians": "Philippians"
    ]

    /// Normalizes a query string into a format more likely to be recognized by the Bible API.
    static func clean(_ query: String) -> String {
        var cleaned = query.trimmingCharacters(in: .whitespaces)
        
        // 1. Basic Typo Fixes (Dictionary swap)
        for (typo, fix) in typoFixes {
            if cleaned.localizedCaseInsensitiveContains(typo) {
                let pattern = "(?i)\\b\(typo)\\b"
                cleaned = cleaned.replacingOccurrences(of: pattern, with: fix, options: .regularExpression)
            }
        }

        // 2. Abbreviation expansion
        // We look for patterns like "Jn 3:16" or "1 Sam 2"
        for (abbr, full) in bookMappings {
            // Match the abbreviation at the start of the word, followed by a space or number
            // e.g. "Jn 3:16", "Jn. 3", "1 Sam"
            let pattern = "(?i)\\b\(abbr)\\.?(?=\\b|\\s|\\d)"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: range, withTemplate: full)
            }
        }
        
        return cleaned
    }
}
