# AtlasTracker CI/CD Automation Setup Plan

**Status**: Ready to implement when Apple Developer Program is approved
**Account**: krisco65@gmail.com (Individual)
**Estimated Setup Time**: 2-3 hours after approval

---

## Table of Contents
1. [Prerequisites Checklist](#prerequisites-checklist)
2. [Phase 1: App Store Connect API Key](#phase-1-app-store-connect-api-key)
3. [Phase 2: Fastlane Match Setup](#phase-2-fastlane-match-setup)
4. [Phase 3: GitHub Secrets Configuration](#phase-3-github-secrets-configuration)
5. [Phase 4: Fastlane Configuration](#phase-4-fastlane-configuration)
6. [Phase 5: GitHub Actions Workflow](#phase-5-github-actions-workflow)
7. [Phase 6: Snapshot Testing](#phase-6-snapshot-testing)
8. [Testing & Verification](#testing--verification)
9. [Troubleshooting Guide](#troubleshooting-guide)

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Apple Developer Program approved (check https://developer.apple.com/account)
- [ ] Xcode installed with command line tools
- [ ] Ruby installed (comes with macOS)
- [ ] Git configured with SSH key
- [ ] GitHub repository access with admin rights

---

## Phase 1: App Store Connect API Key

### Step 1.1: Create API Key in App Store Connect

1. Go to https://appstoreconnect.apple.com/access/api
2. Click **"Keys"** tab → **"+"** button
3. Enter name: `AtlasTracker-CI`
4. Select role: **Admin** (required for TestFlight uploads)
5. Click **Generate**
6. **IMPORTANT**: Download the .p8 file immediately (only downloadable ONCE)
7. Note down:
   - **Key ID**: (8-character alphanumeric, e.g., `ABC123XYZ`)
   - **Issuer ID**: (UUID format, found at top of Keys page)

### Step 1.2: Store Key Securely

Save the .p8 file in a secure location (NOT in git repo):
```
~/AtlasTracker-Secrets/AuthKey_ABC123XYZ.p8
```

### Step 1.3: Convert Key to Base64

Run this command to convert the key for GitHub Secrets:
```bash
base64 -i ~/AtlasTracker-Secrets/AuthKey_ABC123XYZ.p8 | tr -d '\n'
```

Save this output - you'll need it for `ASC_PRIVATE_KEY` secret.

---

## Phase 2: Fastlane Match Setup

### Step 2.1: Create Private Git Repository for Certificates

1. Create a new **PRIVATE** repository on GitHub:
   - Name: `atlas-tracker-certificates`
   - Visibility: **Private**
   - No README or .gitignore needed

### Step 2.2: Install Fastlane

```bash
# Install via Homebrew (recommended)
brew install fastlane

# OR via RubyGems
sudo gem install fastlane
```

### Step 2.3: Initialize Fastlane in Project

```bash
cd /path/to/AtlasTracker
fastlane init
```

Select option **4** (Manual setup) when prompted.

### Step 2.4: Initialize Match

```bash
fastlane match init
```

When prompted:
- Storage mode: **git**
- URL: `git@github.com:YOUR_USERNAME/atlas-tracker-certificates.git`

This creates `fastlane/Matchfile`.

### Step 2.5: Generate Certificates

```bash
# Generate Development certificates
fastlane match development

# Generate App Store (Distribution) certificates
fastlane match appstore
```

You'll be prompted for:
- **Passphrase**: Create a strong password (save this as `MATCH_PASSWORD`)
- **Apple ID**: krisco65@gmail.com
- **App Bundle ID**: com.yourname.AtlasTracker (or your actual bundle ID)

---

## Phase 3: GitHub Secrets Configuration

### Required Secrets

Navigate to: GitHub Repo → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `ASC_KEY_ID` | Your 8-char key ID | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | Your UUID | App Store Connect Issuer ID |
| `ASC_PRIVATE_KEY` | Base64 of .p8 file | App Store Connect private key |
| `MATCH_PASSWORD` | Your passphrase | Password for decrypting certificates |
| `MATCH_GIT_PRIVATE_KEY` | SSH private key | For accessing certificates repo |
| `APPLE_TEAM_ID` | Your team ID | Found in Apple Developer portal |

### Getting Your Team ID

1. Go to https://developer.apple.com/account
2. Click "Membership" in sidebar
3. Copy the **Team ID** (10-character alphanumeric)

### Setting Up MATCH_GIT_PRIVATE_KEY

Option A - Use existing SSH key:
```bash
cat ~/.ssh/id_ed25519 | base64 | tr -d '\n'
```

Option B - Create dedicated deploy key:
```bash
# Generate new key
ssh-keygen -t ed25519 -C "atlasci@github" -f ~/.ssh/atlas_deploy

# Add public key to certificates repo as Deploy Key
# Settings → Deploy keys → Add → Paste contents of ~/.ssh/atlas_deploy.pub

# Base64 encode private key for GitHub Secret
cat ~/.ssh/atlas_deploy | base64 | tr -d '\n'
```

---

## Phase 4: Fastlane Configuration

### 4.1: Appfile

Create `fastlane/Appfile`:
```ruby
app_identifier("com.yourname.AtlasTracker")  # Your bundle ID
apple_id("krisco65@gmail.com")
team_id(ENV["APPLE_TEAM_ID"] || "YOUR_TEAM_ID")

# App Store Connect API
for_lane :release do
  app_store_connect_api_key(
    key_id: ENV["ASC_KEY_ID"],
    issuer_id: ENV["ASC_ISSUER_ID"],
    key_content: ENV["ASC_PRIVATE_KEY"],
    is_key_content_base64: true
  )
end
```

### 4.2: Matchfile

Create/update `fastlane/Matchfile`:
```ruby
git_url("git@github.com:YOUR_USERNAME/atlas-tracker-certificates.git")
storage_mode("git")
type("appstore")  # Default to appstore for releases
app_identifier(["com.yourname.AtlasTracker"])
username("krisco65@gmail.com")
```

### 4.3: Fastfile

Create `fastlane/Fastfile`:
```ruby
default_platform(:ios)

platform :ios do

  # MARK: - Code Signing

  desc "Sync certificates for CI"
  lane :sync_certificates do
    setup_ci if ENV['CI']

    match(
      type: "appstore",
      readonly: is_ci,
      git_private_key: ENV["MATCH_GIT_PRIVATE_KEY"]
    )
  end

  # MARK: - Build

  desc "Build the app"
  lane :build do
    sync_certificates

    build_app(
      project: "AtlasTracker.xcodeproj",
      scheme: "AtlasTracker",
      configuration: "Release",
      export_method: "app-store",
      output_directory: "./build",
      output_name: "AtlasTracker.ipa"
    )
  end

  # MARK: - Testing

  desc "Run all tests"
  lane :test do
    run_tests(
      project: "AtlasTracker.xcodeproj",
      scheme: "AtlasTracker",
      devices: ["iPhone 15"],
      result_bundle: true,
      output_directory: "./test_results"
    )
  end

  desc "Run UI tests only"
  lane :ui_test do
    run_tests(
      project: "AtlasTracker.xcodeproj",
      scheme: "AtlasTracker",
      devices: ["iPhone 15"],
      only_testing: ["AtlasTrackerUITests"],
      result_bundle: true,
      output_directory: "./test_results"
    )
  end

  # MARK: - TestFlight

  desc "Upload to TestFlight"
  lane :beta do
    build

    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      changelog: last_git_commit[:message]
    )
  end

  # MARK: - Full Release Pipeline

  desc "Full CI pipeline: test, build, upload"
  lane :release do
    test
    beta
  end

end

# Helper to detect CI environment
def is_ci
  ENV['CI'] == 'true'
end
```

---

## Phase 5: GitHub Actions Workflow

### 5.1: Complete CI/CD Workflow

Create `.github/workflows/ios-release.yml`:

```yaml
name: iOS Build & TestFlight

on:
  push:
    branches: [main]
    tags:
      - 'v*'
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      upload_to_testflight:
        description: 'Upload to TestFlight'
        required: false
        default: 'false'
        type: boolean

env:
  DEVELOPER_DIR: /Applications/Xcode_15.2.app/Contents/Developer

jobs:
  # Job 1: Build and Test
  test:
    name: Build & Test
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s $DEVELOPER_DIR

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install Fastlane
        run: gem install fastlane

      - name: Run Tests
        run: fastlane test

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test_results/
          retention-days: 14

  # Job 2: Build and Upload to TestFlight
  deploy:
    name: Deploy to TestFlight
    runs-on: macos-14
    needs: test
    if: |
      (github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v')) ||
      (github.event_name == 'workflow_dispatch' && github.event.inputs.upload_to_testflight == 'true')

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s $DEVELOPER_DIR

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install Fastlane
        run: gem install fastlane

      - name: Setup SSH for Match
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.MATCH_GIT_PRIVATE_KEY }}

      - name: Build and Upload to TestFlight
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: fastlane beta

      - name: Upload IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: AtlasTracker-${{ github.sha }}
          path: build/AtlasTracker.ipa
          retention-days: 30
```

### 5.2: Update Existing build.yml

Update `.github/workflows/build.yml` to use Fastlane:

```yaml
name: iOS Build and Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-14

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install Fastlane
        run: gem install fastlane

      - name: Build (Simulator)
        run: |
          xcodebuild clean build \
            -project AtlasTracker.xcodeproj \
            -scheme AtlasTracker \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
            -configuration Debug \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty --color

  ui-tests:
    runs-on: macos-14
    needs: build

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project AtlasTracker.xcodeproj \
            -scheme AtlasTracker \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
            -resultBundlePath UITestResults.xcresult \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty --color --report junit --output test-results.xml
        timeout-minutes: 30

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ui-test-results
          path: |
            UITestResults.xcresult
            test-results.xml
          retention-days: 14
```

---

## Phase 6: Snapshot Testing

### 6.1: Add swift-snapshot-testing Package

In Xcode:
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/pointfreeco/swift-snapshot-testing`
3. Version: Up to Next Major (1.0.0)
4. Add to: AtlasTrackerTests target

### 6.2: Create Snapshot Tests

Create `AtlasTrackerTests/SnapshotTests/InjectionSiteSnapshotTests.swift`:

```swift
import XCTest
import SnapshotTesting
@testable import AtlasTracker

final class InjectionSiteSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set to true to record new snapshots
        // isRecording = true
    }

    func testBodySilhouetteView() {
        let view = VisualBodySilhouette(
            selectedSite: .constant(nil),
            injectionType: .subcutaneous
        )

        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13Pro))
        )
    }

    func testBellySheetView() {
        let view = SubOptionSheet(
            region: .belly,
            selectedSite: .constant(nil),
            lastUsedSite: nil,
            recommendedSite: "left_belly_upper",
            isPresented: .constant(true)
        )

        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: 393, height: 300))
        )
    }
}
```

### 6.3: Recording Baseline Snapshots

First run with recording enabled:
```swift
isRecording = true
```

Then commit the `__Snapshots__` folder and set `isRecording = false`.

---

## Testing & Verification

### Verification Checklist

After setup, verify each component:

- [ ] **Match works locally**: `fastlane match appstore --readonly`
- [ ] **Build works locally**: `fastlane build`
- [ ] **Tests pass locally**: `fastlane test`
- [ ] **GitHub Actions build passes**: Check Actions tab
- [ ] **TestFlight upload works**: Create tag `git tag v1.0.0-beta.1 && git push --tags`
- [ ] **App appears in TestFlight**: Check App Store Connect

### Manual TestFlight Upload

To manually trigger a TestFlight upload:

1. Go to GitHub → Actions → iOS Build & TestFlight
2. Click "Run workflow"
3. Check "Upload to TestFlight"
4. Click "Run workflow"

### Automatic TestFlight Upload

Push a version tag to trigger automatic upload:

```bash
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

---

## Troubleshooting Guide

### Common Issues

**"No signing certificate found"**
```bash
# Re-sync certificates
fastlane match appstore --force
```

**"Profile doesn't match bundle identifier"**
- Verify `app_identifier` in Appfile matches Xcode project
- Check bundle ID in Xcode → Project → Targets → Signing & Capabilities

**"API key authentication failed"**
- Verify ASC_KEY_ID and ASC_ISSUER_ID are correct
- Re-generate and re-encode the .p8 key
- Ensure key has Admin role in App Store Connect

**"SSH authentication failed" (Match)**
- Verify MATCH_GIT_PRIVATE_KEY is base64 encoded correctly
- Check deploy key is added to certificates repo
- Try: `ssh -T git@github.com` to test SSH

**"Build failed with signing error"**
- Run `fastlane match nuke appstore` (WARNING: revokes all certs)
- Re-run `fastlane match appstore`

### Getting Help

- Fastlane Docs: https://docs.fastlane.tools/
- Match Docs: https://docs.fastlane.tools/actions/match/
- GitHub Actions iOS: https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md

---

## Quick Reference Commands

```bash
# Sync certificates (readonly)
fastlane match appstore --readonly

# Force regenerate certificates
fastlane match appstore --force

# Run tests
fastlane test

# Build app
fastlane build

# Upload to TestFlight
fastlane beta

# Full release pipeline
fastlane release

# Create version tag
git tag v1.0.0-beta.1 && git push origin v1.0.0-beta.1
```

---

## Required Files Summary

After setup, your project should have:

```
AtlasTracker/
├── fastlane/
│   ├── Appfile
│   ├── Fastfile
│   └── Matchfile
├── .github/
│   └── workflows/
│       ├── build.yml (updated)
│       └── ios-release.yml (new)
├── Gemfile (optional, for bundler)
└── AtlasTrackerTests/
    └── SnapshotTests/
        └── InjectionSiteSnapshotTests.swift
```

---

**Document Created**: January 2026
**Last Updated**: Ready for implementation upon Apple Developer Program approval
