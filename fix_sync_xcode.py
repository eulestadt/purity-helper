import sys
import re

proj_path = 'PurityHelp.xcodeproj/project.pbxproj'
with open(proj_path, 'r') as f:
    content = f.read()

if 'AutoSyncManager.swift' in content:
    print('AutoSyncManager.swift already in project.')
    sys.exit(0)

file_ref_id = 'C1D2E3F4A5B67890CAFEBABE'
build_file_id = 'D1E2F3A4B5C67890CAFEBABE'

build_file_str = f"{build_file_id} /* AutoSyncManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* AutoSyncManager.swift */; }};\n"
content = re.sub(r'(/\* End PBXBuildFile section \*/)', r'\g<1>', content)
content = content.replace('/* End PBXBuildFile section */', f"{build_file_str}/* End PBXBuildFile section */")

file_ref_str = f"{file_ref_id} /* AutoSyncManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PurityHelp/Services/AutoSyncManager.swift; sourceTree = \"<group>\"; }};\n"
content = content.replace('/* End PBXFileReference section */', f"{file_ref_str}/* End PBXFileReference section */")

group_match = re.search(r'([0-9A-F]+) /\* Services \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n', content)
if group_match:
    group_str = f"{file_ref_id} /* AutoSyncManager.swift */,\n"
    start_idx = group_match.end()
    content = content[:start_idx] + group_str + content[start_idx:]
else:
    main_group_match = re.search(r'([0-9A-F]+) /\* PurityHelp \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n', content)
    if main_group_match:
        group_str = f"{file_ref_id} /* AutoSyncManager.swift */,\n"
        start_idx = main_group_match.end()
        content = content[:start_idx] + group_str + content[start_idx:]

sources_match = re.search(r'([0-9A-F]+) /\* Sources \*/ = \{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = [^\n]+\n\t\t\tfiles = \(\n', content)
if sources_match:
    source_str = f"{build_file_id} /* AutoSyncManager.swift in Sources */,\n"
    start_idx = sources_match.end()
    content = content[:start_idx] + source_str + content[start_idx:]

with open(proj_path, 'w') as f:
    f.write(content)

print('Done adding AutoSyncManager.swift.')
