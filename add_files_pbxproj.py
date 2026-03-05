import sys
import uuid
import re

# We will just patch the pbxproj file by adding the missing files to the "PurityHelp" group and build phases

PBXPROJ_PATH = "PurityHelp.xcodeproj/project.pbxproj"

NEW_FILES = [
  'PurityHelp/Models/JournalEntry.swift',
  'PurityHelp/Models/IfThenPlan.swift',
  'PurityHelp/Services/VigilService.swift',
  'PurityHelp/Services/BibleAPIService.swift',
  'PurityHelp/Views/Vigil/ThresholdView.swift',
  'PurityHelp/Views/Vigil/LogismoiSelectorView.swift',
  'PurityHelp/Views/Vigil/AntirrhetikosView.swift',
  'PurityHelp/Views/Vigil/ReleaseView.swift',
  'PurityHelp/Views/Vigil/VigilContainerView.swift',
  'PurityHelp/Views/Vigil/LitanyView.swift',
  'PurityHelp/Views/Vigil/AudioSanctuaryView.swift',
  'PurityHelp/Views/Vigil/VigilExtendedTabView.swift',
  'PurityHelp/Views/Memorization/AddVerseSearchSheet.swift'
]

with open(PBXPROJ_PATH, 'r') as f:
    pbx_content = f.read()

# Let's see if we can find a good place to insert the files.
print("Script started...")

# This is too complex to write a reliable python regex parser for on the fly.
# Let's try xcodegen if it has a way to just add files, or just use the simplest approach: PlistBuddy
