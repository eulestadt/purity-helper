//
//  DayDomain.swift
//  Purity Help day rules, version 1.
//  Port of backend/src/domain.js. Samples are the source of truth.
//

import Foundation

struct DocRecord: Equatable {
    var key: String
    var value: [String: Any]
    var deleted: Bool

    static func == (lhs: DocRecord, rhs: DocRecord) -> Bool {
        lhs.key == rhs.key && lhs.deleted == rhs.deleted && NSDictionary(dictionary: lhs.value).isEqual(to: rhs.value)
    }
}

struct DayRings: Equatable {
    var clear: Double
    var watch: Double
    var prayer: Double
    var word: Double
}

struct DayStreaks: Equatable {
    var clear: Int
    var pornography: Int
    var masturbation: Int
    var watch: Int
}

struct TodayPractice: Equatable {
    var intention: Bool
    var scripture: Bool
    var examen: Bool
    var surfed: Bool
    var vigil: Bool
    var relapse: Bool
}

struct DangerPattern: Equatable {
    var hours: [Int]
    var weekdays: [Int]
    var busiestHour: Int?
}

struct PlanItem: Identifiable, Equatable {
    var id: String
    var trigger: String
    var action: String
}

struct DerivedDay: Equatable {
    var today: String
    var mission: String
    var hoursPerDay: Double
    var streaks: DayStreaks
    var rings: DayRings
    var fullDay: Bool
    var treeName: String
    var treeId: String
    var hoursReclaimed: Double
    var nextMilestone: Int?
    var danger: DangerPattern
    var plans: [PlanItem]
    var practice: TodayPractice
    var shareRings: Bool
    var shareStreaks: Bool
    var shareMission: Bool
    var shareRelapses: Bool
    var shareUrges: Bool
    var shareExamens: Bool
}

enum DayDomain {
    private static let milestones = [1, 3, 7, 14, 30, 60, 90]

    static func todayString(_ date: Date = Date(), calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 1970, parts.month ?? 1, parts.day ?? 1)
    }

    static func derive(documents: [DocRecord], today: String) -> DerivedDay {
        let profile = documents.first { $0.key == "profile" && !$0.deleted }?.value ?? [:]
        let events = documents.compactMap { doc -> [String: Any]? in
            guard !doc.deleted, doc.key.hasPrefix("event/"), parseDay(string(doc.value["day"])) != nil else { return nil }
            guard string(doc.value["kind"]) != nil else { return nil }
            return doc.value
        }
        let todayEvents = events.filter { string($0["day"]) == today }
        let journey = string(profile["journeyStart"])

        func days(_ type: String?) -> [String] {
            events.compactMap { event in
                guard string(event["kind"]) == "relapse" else { return nil }
                if let type, string(event["type"]) != type { return nil }
                if type == nil {
                    let kind = string(event["type"])
                    guard kind == "pornography" || kind == "masturbation" else { return nil }
                }
                return string(event["day"])
            }
        }

        let streaks = DayStreaks(
            clear: streakAsOf(days(nil), today: today, journeyStart: journey),
            pornography: streakAsOf(days("pornography"), today: today, journeyStart: journey),
            masturbation: streakAsOf(days("masturbation"), today: today, journeyStart: journey),
            watch: streakAsOf(days("thought"), today: today, journeyStart: journey)
        )
        let rings = ringsFor(todayEvents)
        let perDay = double(profile["hoursPerDay"]) ?? 1
        var hours = Array(repeating: 0, count: 24)
        var weekdays = Array(repeating: 0, count: 7)
        for event in events {
            let kind = string(event["kind"])
            guard kind == "relapse" || kind == "urge" else { continue }
            if let hour = integer(event["hour"]), (0...23).contains(hour) { hours[hour] += 1 }
            if let weekday = integer(event["weekday"]), (0...6).contains(weekday) { weekdays[weekday] += 1 }
        }
        var busiest: Int?
        var busiestCount = 0
        for (hour, count) in hours.enumerated() where count > busiestCount {
            busiestCount = count
            busiest = hour
        }
        let plans = documents.compactMap { doc -> PlanItem? in
            guard !doc.deleted, doc.key.hasPrefix("plan/") else { return nil }
            return PlanItem(
                id: String(doc.key.dropFirst("plan/".count)),
                trigger: string(doc.value["trigger"]) ?? "",
                action: string(doc.value["action"]) ?? ""
            )
        }.sorted { $0.trigger < $1.trigger }
        let tree = treeStage(streaks.clear)
        return DerivedDay(
            today: today,
            mission: string(profile["mission"]) ?? "",
            hoursPerDay: perDay,
            streaks: streaks,
            rings: rings,
            fullDay: rings.clear == 1 && rings.watch == 1 && rings.prayer == 1 && rings.word == 1,
            treeName: tree.name,
            treeId: tree.id,
            hoursReclaimed: (Double(streaks.clear) * perDay * 10).rounded() / 10,
            nextMilestone: milestones.first { $0 > streaks.clear },
            danger: DangerPattern(hours: hours, weekdays: weekdays, busiestHour: busiest),
            plans: plans,
            practice: TodayPractice(
                intention: todayEvents.contains { string($0["kind"]) == "prayer" && string($0["form"]) == "intention" },
                scripture: todayEvents.contains { string($0["kind"]) == "scripture" },
                examen: todayEvents.contains { string($0["kind"]) == "examen" },
                surfed: todayEvents.contains { string($0["kind"]) == "urge" && string($0["outcome"]) == "surfed" },
                vigil: todayEvents.contains { string($0["kind"]) == "prayer" && string($0["form"]) == "vigil" },
                relapse: todayEvents.contains {
                    string($0["kind"]) == "relapse" && (string($0["type"]) == "pornography" || string($0["type"]) == "masturbation")
                }
            ),
            shareRings: bool(profile["shareRings"], default: true),
            shareStreaks: bool(profile["shareStreaks"], default: true),
            shareMission: bool(profile["shareMission"], default: false),
            shareRelapses: bool(profile["shareRelapses"], default: false),
            shareUrges: bool(profile["shareUrges"], default: false),
            shareExamens: bool(profile["shareExamens"], default: false)
        )
    }

    static func streakAsOf(_ relapseDays: [String], today: String, journeyStart: String?) -> Int {
        guard parseDay(today) != nil else { return 0 }
        let relapses = Array(Set(relapseDays.filter { parseDay($0) != nil && $0 <= today })).sorted()
        let last = relapses.last
        if last == today { return 0 }
        let start: String?
        if let last { start = addDays(last, 1) }
        else if let journeyStart, parseDay(journeyStart) != nil, journeyStart <= today { start = journeyStart }
        else { start = nil }
        guard let start, start <= today, let span = daysBetween(start, today) else { return 0 }
        return span + 1
    }

    static func ringsFor(_ eventsToday: [[String: Any]]) -> DayRings {
        let body = eventsToday.contains {
            string($0["kind"]) == "relapse" && (string($0["type"]) == "pornography" || string($0["type"]) == "masturbation")
        }
        let thought = eventsToday.contains { string($0["kind"]) == "relapse" && string($0["type"]) == "thought" }
        let surfed = eventsToday.contains { string($0["kind"]) == "urge" && string($0["outcome"]) == "surfed" }
        let watchMark = eventsToday.contains {
            string($0["kind"]) == "prayer" && (string($0["form"]) == "vigil" || string($0["form"]) == "watch")
        }
        let intention = eventsToday.contains { string($0["kind"]) == "prayer" && string($0["form"]) == "intention" }
        let otherPrayer = eventsToday.contains { string($0["kind"]) == "prayer" && string($0["form"]) != "intention" }
        let examen = eventsToday.contains { string($0["kind"]) == "examen" }
        let scripture = eventsToday.contains { string($0["kind"]) == "scripture" }
        let verse = eventsToday.contains { string($0["kind"]) == "verse" }
        var prayer = 0.0
        if examen { prayer = 1 }
        else {
            if intention { prayer += 0.4 }
            if otherPrayer { prayer += 0.6 }
            prayer = min(1, prayer)
        }
        return DayRings(
            clear: body ? 0 : 1,
            watch: (!thought && (surfed || watchMark)) ? 1 : 0,
            prayer: prayer,
            word: min(1, (scripture ? 0.7 : 0) + (verse ? 0.3 : 0))
        )
    }

    private static func treeStage(_ days: Int) -> (id: String, name: String) {
        switch days {
        case 90...: return ("mature", "Mature tree")
        case 30...: return ("young", "Young tree")
        case 14...: return ("sapling", "Sapling")
        case 7...: return ("sprout", "Sprout")
        case 1...: return ("seedling", "Seedling")
        default: return ("seed", "Seed")
        }
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    static func parseDay(_ day: String?) -> Date? {
        guard let day, day.count == 10 else { return nil }
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        guard let date = utc.date(from: comps) else { return nil }
        let back = utc.dateComponents([.year, .month, .day], from: date)
        guard back.year == parts[0], back.month == parts[1], back.day == parts[2] else { return nil }
        return date
    }

    static func addDays(_ day: String, _ count: Int) -> String? {
        guard let date = parseDay(day), let next = utc.date(byAdding: .day, value: count, to: date) else { return nil }
        return todayString(next, calendar: utc)
    }

    static func daysBetween(_ start: String, _ end: String) -> Int? {
        guard let left = parseDay(start), let right = parseDay(end) else { return nil }
        return utc.dateComponents([.day], from: left, to: right).day
    }

    static func string(_ value: Any?) -> String? {
        if let text = value as? String { return text }
        return nil
    }

    static func integer(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let number = value as? Int { return number }
        return nil
    }

    static func double(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let number = value as? Double { return number }
        if let number = value as? Int { return Double(number) }
        return nil
    }

    static func bool(_ value: Any?, default fallback: Bool) -> Bool {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return fallback
    }
}
