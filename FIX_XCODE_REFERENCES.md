# Fix Xcode Build Errors - File References

## Problem
Xcode is still referencing deleted files in the project, causing build errors.

## Solution - Manual Fix (Recommended)

### Step 1: Open Xcode
1. Open `CallyFS.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), you'll see red files (missing files)

### Step 2: Remove Missing File References
Look for these files shown in **red** and delete their references:

**Files to Remove:**
- `OpenRouterService.swift`
- `MainViews/HomeVM.swift`
- `MainViews/HomeModel.swift`
- `MainViews/Home.swift` (if present)
- `Onboarding/OnboardingViewsOld.swift`
- `Item.swift`
- `Authentcation/UserModel.swift`
- `Authentcation/AuthenticationVM.swift`
- `Authentcation/AuthenticationView.swift`
- The entire `Authentcation` folder (if present)

**How to Remove:**
1. Right-click on each red file
2. Select "Delete"
3. Choose "Remove Reference" (NOT "Move to Trash")

### Step 3: Add New Files to Project
The new files may not be in the project yet. Add them:

1. Right-click on `CallyFS` folder in Project Navigator
2. Select "Add Files to CallyFS..."
3. Navigate to and add these folders:
   - `Core/` (entire folder with subfolders)
   - `Features/` (entire folder with subfolders)

**Make sure to:**
- ✅ Check "Copy items if needed" 
- ✅ Select "Create groups"
- ✅ Add to target: CallyFS

### Step 4: Clean Build Folder
1. In Xcode menu: Product → Clean Build Folder (Shift + Cmd + K)
2. Close Xcode
3. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/CallyFS-*
   ```
4. Reopen Xcode
5. Build (Cmd + B)

---

## Alternative - Command Line Fix

If you prefer command line, I can help you edit the `project.pbxproj` file directly, but it's risky and error-prone. The manual method above is safer.

---

## After Fix

Once you've removed the references and added the new files, the project should build successfully. You'll have:

✅ All new features working
✅ No build errors
✅ Clean project structure

---

## Need Help?

If you encounter any issues:
1. Make sure all new files are added to the project
2. Check that file paths are correct
3. Verify the target membership (files should be part of CallyFS target)
4. Clean build folder and rebuild

The app is ready - just need to update Xcode's project references!
