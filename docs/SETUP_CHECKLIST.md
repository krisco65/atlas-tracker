# AtlasTracker CI/CD Setup Checklist

**Use this checklist after Apple Developer Program is approved.**

---

## Pre-Setup (Do These First)

- [ ] Verify Apple Developer Program is active at https://developer.apple.com/account
- [ ] Note your **Team ID** (Membership → Team ID)
- [ ] Verify bundle ID matches: `com.atlasmedtracker.AtlasTracker`

---

## Step 1: App Store Connect API Key (5 min)

- [ ] Go to https://appstoreconnect.apple.com/access/api
- [ ] Click Keys tab → + button
- [ ] Name: `AtlasTracker-CI`
- [ ] Role: **Admin**
- [ ] Click Generate
- [ ] **DOWNLOAD THE .p8 FILE** (only available once!)
- [ ] Note the **Key ID**: ________________
- [ ] Note the **Issuer ID**: ________________
- [ ] Convert to base64: `base64 -i AuthKey_XXX.p8 | tr -d '\n'`

---

## Step 2: Create Certificates Repository (2 min)

- [ ] Go to GitHub → New Repository
- [ ] Name: `atlas-tracker-certificates`
- [ ] Visibility: **PRIVATE**
- [ ] Create (no README)
- [ ] Update `fastlane/Matchfile` with your GitHub username

---

## Step 3: Initialize Match (10 min)

Run on your Mac:

```bash
cd AtlasTracker

# Install fastlane if not already installed
brew install fastlane

# Generate certificates (you'll be prompted for a passphrase)
fastlane match appstore
fastlane match development
```

- [ ] Save your **MATCH_PASSWORD**: ________________

---

## Step 4: Generate SSH Deploy Key (3 min)

```bash
# Generate dedicated deploy key
ssh-keygen -t ed25519 -C "atlas-ci" -f ~/.ssh/atlas_deploy -N ""

# Copy public key
cat ~/.ssh/atlas_deploy.pub
```

- [ ] Add public key to atlas-tracker-certificates repo (Settings → Deploy Keys)
- [ ] Enable "Allow write access"
- [ ] Base64 encode private key: `base64 -i ~/.ssh/atlas_deploy | tr -d '\n'`

---

## Step 5: Add GitHub Secrets (5 min)

Go to: AtlasTracker repo → Settings → Secrets and variables → Actions

Add these secrets:

| Secret | Value |
|--------|-------|
| `ASC_KEY_ID` | Your 8-char key ID |
| `ASC_ISSUER_ID` | Your UUID issuer ID |
| `ASC_PRIVATE_KEY` | Base64 of .p8 file |
| `MATCH_PASSWORD` | Your match passphrase |
| `MATCH_GIT_PRIVATE_KEY` | Base64 of SSH private key |
| `APPLE_TEAM_ID` | Your 10-char team ID |

- [ ] ASC_KEY_ID added
- [ ] ASC_ISSUER_ID added
- [ ] ASC_PRIVATE_KEY added
- [ ] MATCH_PASSWORD added
- [ ] MATCH_GIT_PRIVATE_KEY added
- [ ] APPLE_TEAM_ID added

---

## Step 6: Update Configuration Files

- [ ] Update `fastlane/Appfile` with your Team ID
- [ ] Update `fastlane/Matchfile` with your GitHub username

---

## Step 7: Test Locally (5 min)

```bash
# Verify certificates sync
fastlane match appstore --readonly

# Verify build works
fastlane build
```

- [ ] `match appstore --readonly` succeeds
- [ ] `fastlane build` succeeds

---

## Step 8: Test GitHub Actions (5 min)

Push a test tag:

```bash
git add .
git commit -m "Add Fastlane CI/CD configuration"
git push
git tag v0.0.1-test
git push origin v0.0.1-test
```

- [ ] GitHub Actions workflow starts
- [ ] Tests pass
- [ ] Build succeeds
- [ ] TestFlight upload succeeds
- [ ] Build appears in App Store Connect

---

## You're Done!

Future releases:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Manual trigger:
1. GitHub → Actions → iOS Build & TestFlight
2. Click "Run workflow"
3. Check "Upload to TestFlight"
4. Run

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No signing certificate" | `fastlane match appstore --force` |
| "API key auth failed" | Re-check ASC_KEY_ID and ASC_ISSUER_ID |
| "SSH auth failed" | Verify deploy key is added to certs repo |
| "Bundle ID mismatch" | Check Xcode project bundle ID |

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `fastlane test` | Run all tests |
| `fastlane build` | Build signed IPA |
| `fastlane beta` | Build + upload to TestFlight |
| `fastlane match appstore` | Sync App Store certificates |
| `fastlane match development` | Sync dev certificates |
