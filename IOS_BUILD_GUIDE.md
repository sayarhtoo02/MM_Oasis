# iOS Build & Distribution Guide (Windows)

This document explains how to use the automated tools set up to build the Munajat App for iOS from a Windows environment.

## 🚀 How to Access iOS Builds

Since you are on Windows, the iOS build happens on **GitHub Actions**. Here is how to get the build:

1. **Push your code to GitHub**: Any push to the `main` or `develop` branch will trigger the build automatically.
2. **Go to the "Actions" Tab**: On your GitHub repository page, click the **Actions** tab.
3. **Select the Build**: Click on the latest run named **"iOS Build"**.
4. **Download Artifact**: Scroll down to the **Artifacts** section at the bottom of the page and download `ios-build-unsigned`.

## ⚠️ Important Limitations

- **Unsigned Build**: The exported `Runner.app.zip` is **unsigned**. This means it can be inspected and used for debugging in a Mac simulator, but it **cannot be installed on a physical iPhone yet**.
- **Installation requirement**: To install on a real iPhone, you will eventually need an **Apple Developer Account** and a Mac to sign the app using Xcode or a tool like `fastlane`.

## 📱 Tablet Support

The app is configured to support iPad orientations. When you view the app on a tablet:
- The `MainAppShell` will center content and use `SafeArea` to handle the larger display.
- Ensure that images and icons (maintained cross-platform) have high enough resolution for Retina iPad displays.

## 🛠️ Next Steps for App Store

When you are ready to publish:
1. **Get a Developer Account**: Sign up at [developer.apple.com](https://developer.apple.com).
2. **Signing Certificates**: Once you have an account, the GitHub Actions workflow can be updated to include **Code Signing** using GitHub Secrets.
3. **App Store Connect**: Create your app entry and use the **Transporter** app (on a Mac) to upload the build.

---
*Created by Antigravity AI*
