import re

with open('PurityHelp/Services/FullSyncEngine.swift', 'r') as f:
    text = f.read()

text = text.replace('struct TransferResetRecord: Codable {\n    var type: String\n    var date: Date\n    var optionalNote: String?\n    var triggerTag: String?\n}', 'struct TransferResetRecord: Codable {\n    var id: String\n    var updatedAt: Date\n    var type: String\n    var date: Date\n    var optionalNote: String?\n    var triggerTag: String?\n}')

text = text.replace('struct TransferUrgeLog: Codable {\n    var date: Date\n    var outcome: String\n    var optionalNote: String?\n    var durationMinutes: Int?\n    var quickActionUsed: String?\n    var replaceActivityUsed: String?\n}', 'struct TransferUrgeLog: Codable {\n    var id: String\n    var updatedAt: Date\n    var date: Date\n    var outcome: String\n    var optionalNote: String?\n    var durationMinutes: Int?\n    var quickActionUsed: String?\n    var replaceActivityUsed: String?\n}')

text = text.replace('struct TransferExamenEntry: Codable {\n    var date: Date\n    var step1Thanks: String?\n    var step2Light: String?\n    var step3Examine: String?\n    var step4Forgiveness: String?\n    var step5Resolve: String?\n    var howWasToday: String?\n}', 'struct TransferExamenEntry: Codable {\n    var id: String\n    var updatedAt: Date\n    var date: Date\n    var step1Thanks: String?\n    var step2Light: String?\n    var step3Examine: String?\n    var step4Forgiveness: String?\n    var step5Resolve: String?\n    var howWasToday: String?\n}')

text = text.replace('struct TransferIfThenPlan: Codable {\n    var trigger: String\n    var action: String\n    var reminderEnabled: Bool\n    var createdAt: Date\n    var order: Int\n}', 'struct TransferIfThenPlan: Codable {\n    var id: String\n    var updatedAt: Date\n    var trigger: String\n    var action: String\n    var reminderEnabled: Bool\n    var createdAt: Date\n    var order: Int\n}')

text = text.replace('struct TransferJournalEntry: Codable {\n    var date: Date\n    var type: String\n    var optionalText: String?\n    var tags: String?\n    var moodOutcome: String?\n    var durationCompleted: TimeInterval?\n    var outcome: String?\n}', 'struct TransferJournalEntry: Codable {\n    var id: String\n    var updatedAt: Date\n    var date: Date\n    var type: String\n    var optionalText: String?\n    var tags: String?\n    var moodOutcome: String?\n    var durationCompleted: TimeInterval?\n    var outcome: String?\n}')

text = text.replace('struct TransferUserMission: Codable {\n    var text: String\n    var updatedAt: Date\n}', 'struct TransferUserMission: Codable {\n    var id: String\n    var text: String\n    var updatedAt: Date\n}')

text = text.replace('struct TransferMemorizedVerse: Codable {\n    var verseId: String\n    var status: String\n    var lastReviewedDate: Date?\n    var customReference: String?\n    var customText: String?\n    var customTranslation: String?\n}', 'struct TransferMemorizedVerse: Codable {\n    var verseId: String\n    var updatedAt: Date\n    var status: String\n    var lastReviewedDate: Date?\n    var customReference: String?\n    var customText: String?\n    var customTranslation: String?\n}')


with open('PurityHelp/Services/FullSyncEngine.swift', 'w') as f:
    f.write(text)
print("done struct replacement")
