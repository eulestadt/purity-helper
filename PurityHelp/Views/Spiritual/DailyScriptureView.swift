//
//  DailyScriptureView.swift
//  PurityHelp
//
//  Short passage from Scripture (RSV); for meditation or daily reading.
//

import SwiftUI

struct DailyScriptureView: View {
    private let verse = ScriptureService.verseForToday()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(verse.reference)
                .font(.caption)
                
            Text(verse.text)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationTitle("Daily Scripture")
    }
}

#Preview {
    NavigationStack {
        DailyScriptureView()
    }
}
