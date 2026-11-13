# APK Folder

This folder is designated for your compiled Android application package (`app-release.apk`) required for project submission.

### How to place your APK here:

1. **Option A (Via GitHub Actions - No Flutter install required)**:
   - Push your code to GitHub.
   - Go to the **Actions** tab on your GitHub repository.
   - Download the built `product-store-release-apk.zip`.
   - Extract `app-release.apk` and place it in this `apk/` folder.

2. **Option B (Local Build)**:
   - Run in terminal:
     ```bash
     flutter build apk --release
     ```
   - Copy the output file from `build/app/outputs/flutter-apk/app-release.apk` into this `apk/` folder.
