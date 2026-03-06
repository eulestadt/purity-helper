import re

with open('PurityHelp/Models/ExamenEntry.swift', 'r') as f:
    text = f.read()

text = text.replace('    var step1Thanks: String?\n    var step2Light: String?\n    var step1Thanks: String\n    var step2Light: String\n    var step3Examine: String\n    var step4Forgiveness: String\n    var step5Resolve: String', '    var step1Thanks: String?\n    var step2Light: String?\n    var step3Examine: String?\n    var step4Forgiveness: String?\n    var step5Resolve: String?')

text = text.replace('    init(\n        id: String = UUID().uuidString,\n        updatedAt: Date = .now,\n        date: Date = .now,\n        step1Thanks: String = "",\n        step2Light: String = "",\n        step3Examine: String = "",\n        step4Forgiveness: String = "",\n        step5Resolve: String = "",', '    init(\n        id: String = UUID().uuidString,\n        updatedAt: Date = .now,\n        date: Date = .now,\n        step1Thanks: String? = nil,\n        step2Light: String? = nil,\n        step3Examine: String? = nil,\n        step4Forgiveness: String? = nil,\n        step5Resolve: String? = nil,')

with open('PurityHelp/Models/ExamenEntry.swift', 'w') as f:
    f.write(text)
print("done")
