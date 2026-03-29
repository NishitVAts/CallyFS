#!/usr/bin/env python3
"""
Final Xcode Project Fixer
Removes folder references that should be groups
"""

import sys
from pathlib import Path

def fix_xcode_project(project_path):
    """Remove incorrect folder references from Xcode project file"""
    
    pbxproj_path = project_path / 'project.pbxproj'
    
    if not pbxproj_path.exists():
        print(f"❌ Error: {pbxproj_path} not found")
        return False
    
    print(f"📝 Reading {pbxproj_path}")
    
    # Read the project file
    with open(pbxproj_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Backup
    backup_path = pbxproj_path.with_suffix('.pbxproj.backup3')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"💾 Backup created: {backup_path}")
    
    # Folders to remove (these should be added as groups, not folder references)
    folders_to_remove = [
        '75E609F7',  # Core
        '75E609F9',  # Settings  
        '75E609FA',  # Features
        '75E60A00',  # Models
        '75E60A01',  # MainViews
        '75E60A02',  # Utils
        '75E60A03',  # Preview Content (duplicate)
        '75E609FB',  # KeychainManager.swift (duplicate)
        '75E609FD',  # CallyFSApp.swift (duplicate)
        '75E609FE',  # Shared.swift (duplicate)
        '75E609FF',  # PersonalizedPlan.swift (duplicate)
    ]
    
    new_lines = []
    removed_count = 0
    
    for line in lines:
        should_remove = False
        
        # Check if line contains any of the UUIDs to remove
        for uuid in folders_to_remove:
            if uuid in line:
                should_remove = True
                removed_count += 1
                print(f"  ❌ Removing: {line.strip()[:100]}...")
                break
        
        if not should_remove:
            new_lines.append(line)
    
    # Write the fixed project file
    with open(pbxproj_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f"\n✅ Fixed project file!")
    print(f"   Removed: {removed_count} lines")
    print(f"\n💡 CRITICAL NEXT STEPS:")
    print(f"   1. Close Xcode COMPLETELY (Cmd + Q)")
    print(f"   2. Delete DerivedData:")
    print(f"      rm -rf ~/Library/Developer/Xcode/DerivedData/CallyFS-*")
    print(f"   3. Reopen Xcode")
    print(f"   4. In Project Navigator, RIGHT-CLICK on 'CallyFS' folder")
    print(f"   5. Select 'Add Files to CallyFS...'")
    print(f"   6. Select BOTH 'Core' and 'Features' folders")
    print(f"   7. IMPORTANT: Check 'Create groups' (NOT 'Create folder references')")
    print(f"   8. IMPORTANT: Uncheck 'Copy items if needed'")
    print(f"   9. Click Add")
    print(f"   10. Clean Build Folder (Shift + Cmd + K)")
    print(f"   11. Build (Cmd + B)")
    
    return True

def main():
    current_dir = Path.cwd()
    project_path = current_dir / 'CallyFS.xcodeproj'
    
    if not project_path.exists():
        project_path = current_dir.parent / 'CallyFS.xcodeproj'
    
    if not project_path.exists():
        print("❌ Error: CallyFS.xcodeproj not found")
        return 1
    
    print("🔧 Final Xcode Project Fixer")
    print("=" * 50)
    
    success = fix_xcode_project(project_path)
    
    if success:
        print("\n🎉 Project file cleaned! Follow the steps above carefully.")
        return 0
    else:
        print("\n❌ Failed to fix project.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
