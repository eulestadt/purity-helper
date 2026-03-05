//
//  UrgeInsightsView.swift
//  PurityHelp
//
//  Display patterns and statistics from UrgeLog data.
//

import SwiftUI
import SwiftData
import Charts

struct UrgeInsightsView: View {
    @Query(sort: \UrgeLog.date, order: .reverse) private var logs: [UrgeLog]
    
    @State private var timeRange: TimeRange = .days
    @State private var selectedDate: Date? = nil
    @State private var selectedHour: Int? = nil
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case days = "Days"
        case hours = "Hours"
        var id: String { self.rawValue }
    }
    
    // MARK: - Data Aggregation

    private struct AggregatedData: Identifiable {
        let id = UUID()
        let date: Date?
        let hour: Int?
        let action: String
        let count: Int
    }
    
    private var chartData: [AggregatedData] {
        var data: [AggregatedData] = []
        let calendar = Calendar.current
        
        switch timeRange {
        case .days:
            // Last 14 days
            let today = calendar.startOfDay(for: Date())
            guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -13, to: today) else { return [] }
            
            let filteredLogs = logs.filter { $0.date >= twoWeeksAgo }
            let groupedByDayAndAction = Dictionary(grouping: filteredLogs) { log -> (Date, String) in
                let day = calendar.startOfDay(for: log.date)
                let action = log.quickActionUsed ?? log.replaceActivityUsed ?? "Held Firm"
                return (day, action)
            }
            
            for ((day, action), logs) in groupedByDayAndAction {
                data.append(AggregatedData(date: day, hour: nil, action: action, count: logs.count))
            }
            
        case .hours:
            // Aggregate over 24 hours
            let groupedByHourAndAction = Dictionary(grouping: logs) { log -> (Int, String) in
                let hour = calendar.component(.hour, from: log.date)
                let action = log.quickActionUsed ?? log.replaceActivityUsed ?? "Held Firm"
                return (hour, action)
            }
            
            for ((hour, action), logs) in groupedByHourAndAction {
                data.append(AggregatedData(date: nil, hour: hour, action: action, count: logs.count))
            }
        }
        
        return data
    }
    
    // MARK: - Insights Summaries
    
    private var peakStruggleTime: String {
        guard !logs.isEmpty else { return "No data yet" }
        var counts: [Int: Int] = [:]
        for log in logs {
            let hour = Calendar.current.component(.hour, from: log.date)
            counts[hour, default: 0] += 1
        }
        if let topHour = counts.max(by: { $0.value < $1.value })?.key {
            let nextHour = (topHour + 1) % 24
            return "\(formatHour(topHour)) - \(formatHour(nextHour))"
        }
        return "Not enough data"
    }
    
    private var topAction: String {
        var actions: [String: Int] = [:]
        for log in logs {
            let action = log.quickActionUsed ?? log.replaceActivityUsed ?? "Held Firm"
            actions[action, default: 0] += 1
        }
        if let top = actions.max(by: { $0.value < $1.value }) {
            return top.key
        }
        return "None yet"
    }
    
    private func formatHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h) \(ampm)"
    }
    
    // MARK: - Selected Data Filtering
    
    private var selectedLogs: [UrgeLog] {
        let calendar = Calendar.current
        if timeRange == .days, let selectedDate = selectedDate {
            return logs.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        } else if timeRange == .hours, let selectedHour = selectedHour {
            return logs.filter { calendar.component(.hour, from: $0.date) == selectedHour }
        }
        return []
    }
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            PurityBackground()
            List {
                Section {
                    HStack {
                        Text("Peak Struggle Time")
                        Spacer()
                        Text(peakStruggleTime).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Most Used Tool")
                        Spacer()
                        Text(topAction).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total Victories")
                        Spacer()
                        Text("\(logs.count)").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Your Patterns")
                } footer: {
                    Text("Identifying these patterns helps you be more watchful and prepared during high-risk moments.")
                }
                
                Section {
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                    .onChange(of: timeRange) {
                        selectedDate = nil
                        selectedHour = nil
                    }
                    
                    if logs.isEmpty {
                        Text("No logs yet. Use the 'Urge' button when struggling to build your insights.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        chartView
                            .frame(height: 250)
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                    }
                } header: {
                    Text("Recent Victories")
                }
                
                if (timeRange == .days && selectedDate != nil) || (timeRange == .hours && selectedHour != nil) {
                    Section {
                        if selectedLogs.isEmpty {
                            Text("No victories recorded during this time.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(selectedLogs) { log in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        let action = log.quickActionUsed ?? log.replaceActivityUsed ?? "Held Firm"
                                        Text(action)
                                            .font(.subheadline.bold())
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        if timeRange == .days, let d = selectedDate {
                            Text("Victories on \(d.formatted(date: .abbreviated, time: .omitted))")
                        } else if timeRange == .hours, let h = selectedHour {
                            Text("Victories at \(formatHour(h))")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Urge Insights")
        }
    }
    
    // MARK: - Chart View Component
    
    @ViewBuilder
    private var chartView: some View {
        let rawData = chartData
        Chart {
            ForEach(rawData) { item in
                if timeRange == .days, let date = item.date {
                    BarMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Victories", item.count)
                    )
                    .foregroundStyle(by: .value("Action", item.action))
                } else if timeRange == .hours, let hour = item.hour {
                    BarMark(
                        x: .value("Hour", hour),
                        y: .value("Victories", item.count)
                    )
                    .foregroundStyle(by: .value("Action", item.action))
                }
            }
            
            // Highlight selected selection
            if timeRange == .days, let selDate = selectedDate {
                RuleMark(x: .value("Selected Date", selDate, unit: .day))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 30))
                    .annotation(position: .top) {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.gray)
                    }
            } else if timeRange == .hours, let selHour = selectedHour {
                RuleMark(x: .value("Selected Hour", selHour))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 15))
                    .annotation(position: .top) {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.gray)
                    }
            }
        }
        // X-Axis formatting
        .chartXAxis {
            if timeRange == .days {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(format: .dateTime.month().day())
                        AxisGridLine()
                        AxisTick()
                    }
                }
            } else {
                AxisMarks(values: .stride(by: 4)) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text(formatHour(hour))
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
            }
        }
        // Selection Interaction
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onTapGesture { location in
                        if timeRange == .days {
                            guard let date: Date = proxy.value(atX: location.x) else { return }
                            let startOfDay = Calendar.current.startOfDay(for: date)
                            if selectedDate == startOfDay {
                                selectedDate = nil // Toggle off
                            } else {
                                selectedDate = startOfDay
                            }
                        } else {
                            guard let hour: Int = proxy.value(atX: location.x) else { return }
                            // Snap to nearest hour
                            let snappedHour = min(max(hour, 0), 23)
                            if selectedHour == snappedHour {
                                selectedHour = nil // Toggle off
                            } else {
                                selectedHour = snappedHour
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UrgeInsightsView()
            .modelContainer(for: UrgeLog.self, inMemory: true)
    }
}
