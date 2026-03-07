//
//  BibleAPIService.swift
//  PurityHelp
//
//  Service to interact with API.bible to search for custom verses.
//

import Foundation
import os.log

@Observable
final class BibleAPIService {
    // API Configuration
    private let apiKey = "rtro44vU8CQe3bZq3b1mI"
    private let baseURL = "https://rest.api.bible/v1"
    
    // Default Bible version (ASV: American Standard Version)
    private let defaultBibleId = "685d1470fe4d5c3b-01"

    enum ServiceError: Error {
        case invalidURL
        case decodingError
        case networkError(Error)
        case invalidResponse
    }

    /// Search for verses within a specific Bible version.
    func searchVerses(query: String, bibleId: String = "06125adad2d5898a-01", translationName: String? = nil) async throws -> [ScriptureVerse] {
        let cleanedQuery = BibleReferenceCleaner.clean(query)
        guard let encodedQuery = cleanedQuery.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
              let url = URL(string: "\(baseURL)/bibles/\(bibleId)/search?query=\(encodedQuery)") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "api-key")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ServiceError.invalidResponse
            }

            let searchResult = try JSONDecoder().decode(BibleAPIResponse.self, from: data)
            
            var results: [ScriptureVerse] = []
            
            // Handle exact reference results (passages) FIRST
            if let passages = searchResult.data.passages, !passages.isEmpty {
                let passageResults = passages.map { passageResponse -> ScriptureVerse in
                    let noHeaders = passageResponse.content
                        .replacingOccurrences(of: "<p class=\"s.+?>.*?</p>", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "<div class=\"s.+?>.*?</div>", with: "", options: .regularExpression)
                    
                    let noNumbers = noHeaders.replacingOccurrences(of: "<span[^>]*class=\"v\"[^>]*>.*?</span>", with: " ", options: .regularExpression)
                    
                    let cleanText = noNumbers
                        .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        .replacingOccurrences(of: "&#182;", with: "")
                        .replacingOccurrences(of: "¶", with: "")
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return ScriptureVerse(id: passageResponse.id, reference: passageResponse.reference, text: cleanText, translation: translationName)
                }
                
                // Deduplicate passages by text to prevent the API returning 4 of the same verse
                for passage in passageResults {
                    if !results.contains(where: { $0.text == passage.text }) {
                        results.append(passage)
                    }
                }
                
                // If we found an exact passage, return immediately to ignore fuzzy keyword matches
                return results
            }
            
            // Handle keyword search results (verses) if no exact passage was found
            if let verses = searchResult.data.verses {
                let verseResults = verses.map { verseResponse -> ScriptureVerse in
                    let noHeaders = verseResponse.text
                        .replacingOccurrences(of: "<p class=\"s.+?>.*?</p>", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "<div class=\"s.+?>.*?</div>", with: "", options: .regularExpression)
                        
                    let noNumbers = noHeaders.replacingOccurrences(of: "<span[^>]*class=\"v\"[^>]*>.*?</span>", with: " ", options: .regularExpression)
                    
                    let cleanText = noNumbers
                        .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        .replacingOccurrences(of: "&#182;", with: "")
                        .replacingOccurrences(of: "¶", with: "")
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return ScriptureVerse(id: verseResponse.id, reference: verseResponse.reference, text: cleanText, translation: translationName)
                }
                
                // Deduplicate verses by text
                for verse in verseResults {
                    if !results.contains(where: { $0.text == verse.text }) {
                        results.append(verse)
                    }
                }
            }
            
            return results
        } catch let error as DecodingError {
            os_log("Decoding error in searchVerses: %{public}@", log: .default, type: .error, String(describing: error))
            throw ServiceError.decodingError
        } catch {
            os_log("Network error in searchVerses: %{public}@", log: .default, type: .error, error.localizedDescription)
            throw ServiceError.networkError(error)
        }
    }
}

// MARK: - API Response Models
private struct BibleAPIResponse: Codable {
    let data: BibleAPIData
}

private struct BibleAPIData: Codable {
    let query: String?
    let limit: Int?
    let offset: Int?
    let total: Int?
    let verseCount: Int?
    let verses: [BibleAPIVerse]?
    let passages: [BibleAPIPassage]?
}

private struct BibleAPIVerse: Codable {
    let id: String
    let reference: String
    let text: String
}

private struct BibleAPIPassage: Codable {
    let id: String
    let reference: String
    let content: String
}
