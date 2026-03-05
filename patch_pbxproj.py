import os
import re
import uuid

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
  'PurityHelp/Views/Memorization/AddVerseSearchSheet.swift',
  'PurityHelp/Resources/Prayers/liturgies.json'
]

def generate_id():
    return uuid.uuid4().hex[:24].upper()

with open(PBXPROJ_PATH, 'r') as f:
    content = f.read()

# 1. Add to PBXBuildFile section
# 2. Add to PBXFileReference section
# 3. Add to the main PBXGroup "PurityHelp"
# 4. Add to PBXSourcesBuildPhase (for .swift)
# 5. Add to PBXResourcesBuildPhase (for .json)

build_files = []
file_refs = []
group_children = []
sources = []
resources = []

for file_path in NEW_FILES:
    if file_path in content:
        print(f"Skipping {file_path}, already in project")
        continue

    filename = os.path.basename(file_path)
    file_ref_id = generate_id()
    build_file_id = generate_id()
    
    # PBXFileReference
    if filename.endswith('.swift'):
        file_refs.append(f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};")
        sources.append(f"\t\t\t\t{build_file_id} /* {filename} in Sources */,")
    elif filename.endswith('.json'):
        file_refs.append(f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = {filename}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{build_file_id} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};")
        resources.append(f"\t\t\t\t{build_file_id} /* {filename} in Resources */,")
    
    group_children.append(f"\t\t\t\t{file_ref_id} /* {filename} */,")

if not build_files:
    print("No new files to add.")
    sys.exit(0)

# Inject into PBXBuildFile
content = re.sub(r'(/\* End PBXBuildFile section \*/)', "\n".join(build_files) + "\n/* End PBXBuildFile section */", content)

# Inject into PBXFileReference
content = re.sub(r'(/\* End PBXFileReference section \*/)', "\n".join(file_refs) + "\n/* End PBXFileReference section */", content)

# Inject into PBXSourcesBuildPhase
content = re.sub(r'(isa = PBXSourcesBuildPhase;[\s\S]*?files = \(\n)', r'\1' + "\n".join(sources) + "\n", content)

# Inject into PBXResourcesBuildPhase
content = re.sub(r'(isa = PBXResourcesBuildPhase;[\s\S]*?files = \(\n)', r'\1' + "\n".join(resources) + "\n", content)

# For PBXGroup, we'll just dump them all in the root PurityHelp group for simplicity.
# Find the main PurityHelp group (usually has path = PurityHelp)
# It's safer to just find the first `children = (` that has `path = PurityHelp` but regex is tricky.
# Let's find the group that contains ContentView.swift as a child.
content_view_match = re.search(r'([A-Z0-9]{24}) /\* ContentView.swift \*/,', content)
if content_view_match:
    root_group_id_match = re.search(r'([A-Z0-9]{24}) /\* PurityHelp \*/ = \{\s*isa = PBXGroup;\s*children = \(\s*[\s\S]*?ContentView.swift', content)
    if root_group_id_match:
        # We replace the children start
        content = content.replace(root_group_id_match.group(0), root_group_id_match.group(0) + "\n" + "\n".join(group_children))
    else:
        # Just inject anywhere in a group
        pass

with open(PBXPROJ_PATH, 'w') as f:
    f.write(content)

print(f"Patched {len(NEW_FILES)} files into Xcode project successfully.")
