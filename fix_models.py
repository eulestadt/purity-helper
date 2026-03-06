import re

with open('PurityHelp/Models/SyncTransferModels.swift', 'r') as f:
    text = f.read()

text = text.replace('struct TransferStreakRecord: Codable {\n    var pornographyStreakDays: Int', 'struct TransferStreakRecord: Codable {\n    var id: String\n    var pornographyStreakDays: Int')
text = text.replace('struct TransferResetRecord: Codable {\n    var type: String', 'struct TransferResetRecord: Codable {\n    var id: String\n    var updatedAt: Date\n    var type: String')
text = text.replace('struct TransferUrgeLog: Codable {\n    var date: Date', 'struct TransferUrgeLog: Codable {\n    var id: String\n    var updatedAt: Date\n    var date: Date')
text = text.replace('struct TransferExamenEntry: Codable {\n    var date: Date', 'struct TransferExamenEntry: Codable {\n    var id: String\n    var updatedAt: Date\n    var date: Date')
text = text.replace('struct TransferIfThenPlan: Codable {\n    var trigger: String', 'struct TransferIfThenPlan: Codable {\n    var id: String\n    var updatedAt: Date\n    var trigger: String')
text = text.replace('struct TransferJournalEntry: Codable {\n    var date: Date', 'struct TransferJournalEntry: Codable {\n    var id: String\n    var updatedAt: Date\n    var date: Date')
text = text.replace('struct TransferUserMission: Codable {\n    var text: String', 'struct TransferUserMission: Codable {\n    var id: String\n    var text: String')
text = text.replace('struct TransferMemorizedVerse: Codable {\n    var verseId: String\n    var status: String', 'struct TransferMemorizedVerse: Codable {\n    var verseId: String\n    var updatedAt: Date\n    var status: String')

with open('PurityHelp/Models/SyncTransferModels.swift', 'w') as f:
    f.write(text)
print("done struct replacement in Models")
