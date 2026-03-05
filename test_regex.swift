import Foundation
let html = "<p class=\"p\"><span data-number=\"16\" data-sid=\"JHN 3:16\" class=\"v\">16</span>For God so loved the world... </p>"
let noNumbers = html.replacingOccurrences(of: "<span[^>]*class=\"v\"[^>]*>.*?</span>", with: "", options: .regularExpression)
let cleanText = noNumbers.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
print(cleanText)
