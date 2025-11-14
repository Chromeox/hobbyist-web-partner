#!/usr/bin/env python3
"""
Add EnhancedOnboardingFlow.swift to Xcode project.pbxproj
"""
import re
import sys

# Read the project file
with open('/Users/chromefang.exe/HobbyApp/HobbyApp.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# UUIDs for the file
FILE_REF_UUID = '56267081FE794541ACE186D9'
BUILD_FILE_UUID = '3A7722DAA4A8467A950582E8'

# 1. Add PBXBuildFile entry (after line 11, in the PBXBuildFile section)
build_file_entry = f'\t\t{BUILD_FILE_UUID} /* EnhancedOnboardingFlow.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {FILE_REF_UUID} /* EnhancedOnboardingFlow.swift */; }};\n'

# Find the end of PBXBuildFile section (line 72)
content = content.replace(
    '/* End PBXBuildFile section */',
    f'{build_file_entry}/* End PBXBuildFile section */'
)

# 2. Add PBXFileReference entry (after line 75, in the PBXFileReference section)
file_ref_entry = f'\t\t{FILE_REF_UUID} /* EnhancedOnboardingFlow.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EnhancedOnboardingFlow.swift; sourceTree = "<group>"; }};\n'

# Find after OutOfCreditsView entry
content = content.replace(
    '2982779DE89F44D3ACD16E2F /* OutOfCreditsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OutOfCreditsView.swift; sourceTree = "<group>"; };',
    f'2982779DE89F44D3ACD16E2F /* OutOfCreditsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OutOfCreditsView.swift; sourceTree = "<group>"; }};\n{file_ref_entry.strip()}'
)

# 3. Add to PBXSourcesBuildPhase (before the closing of files section)
sources_entry = f'\t\t\t\t{BUILD_FILE_UUID} /* EnhancedOnboardingFlow.swift in Sources */,\n'

# Add before the last entry (OutOfCreditsView)
content = content.replace(
    '13AD27098CB54870890BFC98 /* OutOfCreditsView.swift in Sources */,',
    f'{sources_entry.strip()}\n\t\t\t\t13AD27098CB54870890BFC98 /* OutOfCreditsView.swift in Sources */,'
)

# Write back
with open('/Users/chromefang.exe/HobbyApp/HobbyApp.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Successfully added EnhancedOnboardingFlow.swift to Xcode project")
print(f"   - File Reference UUID: {FILE_REF_UUID}")
print(f"   - Build File UUID: {BUILD_FILE_UUID}")
