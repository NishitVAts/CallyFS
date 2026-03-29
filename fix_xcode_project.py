#!/usr/bin/env python3
"""
Xcode Project Fixer
Removes references to deleted files from CallyFS.xcodeproj
"""

import re
import sys
from pathlib import Path

# Files that were deleted and need to be removed from project
DELETED_FILES = [
    'OpenRouterService.swift',
    'HomeVM.swift',
    'HomeModel.swift',
    'Home.swift',
    ' Home.swift',  # Note the leading space
    'OnboardingViewsOld.swift',
    'Item.swift',
    'UserModel.swift',
    'AuthenticationVM.swift',
    'AuthenticationView.swift',
]

def fix_xcode_project(project_path):
    """Remove references to deleted files from Xcode project file"""
    
    pbxproj_path = project_path / 'project.pbxproj'
    
    if not pbxproj_path.exists():
        print(f"❌ Error: {pbxproj_path} not found")
        return False
    
    print(f"📝 Reading {pbxproj_path}")
    
    # Read the project file
    with open(pbxproj_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Backup the original file
    backup_path = pbxproj_path.with_suffix('.pbxproj.backup')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"💾 Backup created: {backup_path}")
    
    original_lines = len(content.split('\n'))
    
    # Find and collect UUIDs of files to remove
    uuids_to_remove = set()
    
    for filename in DELETED_FILES:
        # Find file references with UUIDs
        pattern = rf'([A-F0-9]+) /\* {re.escape(filename)}'
        matches = re.findall(pattern, content)
        uuids_to_remove.update(matches)
        
        # Also find in PBXFileReference section
        pattern = rf'([A-F0-9]+) = \{{[^}}]*{re.escape(filename)}'
        matches = re.findall(pattern, content)
        uuids_to_remove.update(matches)
    
    print(f"\n🔍 Found {len(uuids_to_remove)} file references to remove")
    
    if not uuids_to_remove:
        print("⚠️  No references found. Files may already be removed.")
        return True
    
    # Remove lines containing these UUIDs
    lines = content.split('\n')
    new_lines = []
    removed_count = 0
    
    for line in lines:
        should_remove = False
        
        # Check if line contains any of the UUIDs to remove
        for uuid in uuids_to_remove:
            if uuid in line:
                should_remove = True
                removed_count += 1
                print(f"  ❌ Removing: {line.strip()[:80]}...")
                break
        
        if not should_remove:
            new_lines.append(line)
    
    # Join lines back together
    new_content = '\n'.join(new_lines)
    
    # Write the fixed project file
    with open(pbxproj_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    new_line_count = len(new_lines)
    
    print(f"\n✅ Fixed project file!")
    print(f"   Original lines: {original_lines}")
    print(f"   New lines: {new_line_count}")
    print(f"   Removed: {removed_count} lines")
    print(f"\n💡 Next steps:")
    print(f"   1. Open Xcode")
    print(f"   2. Clean Build Folder (Shift + Cmd + K)")
    print(f"   3. Add new Core/ and Features/ folders to project")
    print(f"   4. Build (Cmd + B)")
    
    return True

def main():
    # Find the Xcode project
    current_dir = Path.cwd()
    project_path = current_dir / 'CallyFS.xcodeproj'
    
    if not project_path.exists():
        # Try parent directory
        project_path = current_dir.parent / 'CallyFS.xcodeproj'
    
    if not project_path.exists():
        print("❌ Error: CallyFS.xcodeproj not found")
        print(f"   Current directory: {current_dir}")
        print("\n💡 Run this script from the CallyFS project root directory")
        return 1
    
    print("🔧 CallyFS Xcode Project Fixer")
    print("=" * 50)
    print(f"Project: {project_path}\n")
    
    success = fix_xcode_project(project_path)
    
    if success:
        print("\n🎉 Done! Your Xcode project has been fixed.")
        return 0
    else:
        print("\n❌ Failed to fix project. Check the error messages above.")
        print(f"   Backup available at: project.pbxproj.backup")
        return 1

if __name__ == '__main__':
    sys.exit(main())
