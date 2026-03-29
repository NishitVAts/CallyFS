#!/usr/bin/env python3
"""
Complete Xcode Project Fixer
Removes ALL references to deleted files from CallyFS.xcodeproj
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
    ' Home.swift',
    'OnboardingViewsOld.swift',
    'Item.swift',
    'UserModel.swift',
    'AuthenticationVM.swift',
    'AuthenticationView.swift',
]

def fix_xcode_project(project_path):
    """Remove ALL references to deleted files from Xcode project file"""
    
    pbxproj_path = project_path / 'project.pbxproj'
    
    if not pbxproj_path.exists():
        print(f"❌ Error: {pbxproj_path} not found")
        return False
    
    print(f"📝 Reading {pbxproj_path}")
    
    # Read the project file
    with open(pbxproj_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Backup the original file
    backup_path = pbxproj_path.with_suffix('.pbxproj.backup2')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"💾 Backup created: {backup_path}")
    
    original_count = len(lines)
    
    # Remove lines containing any of the deleted files
    new_lines = []
    removed_count = 0
    
    for line in lines:
        should_remove = False
        
        # Check if line contains any of the deleted files
        for filename in DELETED_FILES:
            if filename in line:
                should_remove = True
                removed_count += 1
                print(f"  ❌ Removing: {line.strip()[:100]}...")
                break
        
        if not should_remove:
            new_lines.append(line)
    
    # Also remove the Authentcation group reference
    final_lines = []
    skip_next = 0
    
    for i, line in enumerate(new_lines):
        if skip_next > 0:
            skip_next -= 1
            removed_count += 1
            print(f"  ❌ Removing group: {line.strip()[:100]}...")
            continue
            
        # Check for Authentcation folder group
        if 'Authentcation' in line and 'PBXGroup' in line:
            # Skip this line and the next few lines until we find the closing brace
            skip_next = 0
            removed_count += 1
            print(f"  ❌ Removing Authentcation group: {line.strip()[:100]}...")
            
            # Count lines to skip (until we find }; at the same indentation level)
            indent_level = len(line) - len(line.lstrip())
            for j in range(i + 1, len(new_lines)):
                skip_next += 1
                if new_lines[j].strip() == '};' and (len(new_lines[j]) - len(new_lines[j].lstrip())) == indent_level:
                    break
            continue
        
        final_lines.append(line)
    
    # Write the fixed project file
    with open(pbxproj_path, 'w', encoding='utf-8') as f:
        f.writelines(final_lines)
    
    new_count = len(final_lines)
    
    print(f"\n✅ Fixed project file!")
    print(f"   Original lines: {original_count}")
    print(f"   New lines: {new_count}")
    print(f"   Removed: {removed_count} lines")
    print(f"\n💡 Next steps:")
    print(f"   1. Close Xcode completely")
    print(f"   2. Delete DerivedData:")
    print(f"      rm -rf ~/Library/Developer/Xcode/DerivedData/CallyFS-*")
    print(f"   3. Reopen Xcode")
    print(f"   4. Add Core/ and Features/ folders to project")
    print(f"   5. Build (Cmd + B)")
    
    return True

def main():
    # Find the Xcode project
    current_dir = Path.cwd()
    project_path = current_dir / 'CallyFS.xcodeproj'
    
    if not project_path.exists():
        project_path = current_dir.parent / 'CallyFS.xcodeproj'
    
    if not project_path.exists():
        print("❌ Error: CallyFS.xcodeproj not found")
        print(f"   Current directory: {current_dir}")
        return 1
    
    print("🔧 CallyFS Complete Xcode Project Fixer")
    print("=" * 50)
    print(f"Project: {project_path}\n")
    
    success = fix_xcode_project(project_path)
    
    if success:
        print("\n🎉 Done! Your Xcode project has been fixed.")
        return 0
    else:
        print("\n❌ Failed to fix project.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
