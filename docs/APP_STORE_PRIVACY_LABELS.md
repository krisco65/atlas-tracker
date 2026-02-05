# Atlas Tracker - App Store Privacy Nutrition Labels

**Use this when submitting to App Store Connect**

---

## Overview

When you submit to the App Store, you'll be asked to declare what data your app collects. This document provides the exact answers for Atlas Tracker.

---

## App Store Connect Privacy Questions

### Question 1: Do you or your third-party partners collect data from this app?

**Answer: NO**

Explanation: Atlas Tracker stores data locally on the user's device only. No data is transmitted to any server, including ours. There are no third-party SDKs that collect data.

---

### Question 2: Data Types

Since we answered "NO" to collecting data, we don't need to declare data types. However, for transparency, here's what data EXISTS in the app (stored locally only):

| Data Type | Collected? | Reason |
|-----------|------------|--------|
| Health & Fitness | NO | Stored locally only, never transmitted |
| Contact Info | NO | Not requested or stored |
| Identifiers | NO | No device ID, user ID, or advertising ID |
| Usage Data | NO | No analytics |
| Diagnostics | NO | No crash reporting |
| Location | NO | Not requested |
| Financial Info | NO | No purchases tracked |
| Contacts | NO | Not requested |
| User Content | NO | Notes stored locally only |
| Browsing History | NO | No web browsing |
| Search History | NO | Not tracked |
| Sensitive Info | NO | Not applicable |
| Other Data | NO | Nothing else |

---

## HealthKit Special Considerations

### Important: HealthKit is NOT "Data Collection"

Apple's definition of "collected" means data that is:
- Transmitted off the device
- Sent to your servers
- Shared with third parties

Atlas Tracker's HealthKit usage:
- Reads weight data FROM Apple Health (stays on device)
- Writes weight data TO Apple Health (stays on device)
- Never transmits HealthKit data externally

**Therefore: HealthKit data is NOT "collected" for App Store privacy label purposes.**

### HealthKit Usage Description (already in Info.plist)

```
NSHealthShareUsageDescription: Atlas Tracker needs access to read your weight data from Apple Health to track your progress alongside your supplement and compound usage.

NSHealthUpdateUsageDescription: Atlas Tracker needs access to save weight entries to Apple Health so your data stays synced across all your health apps.
```

---

## Step-by-Step App Store Connect Submission

### Step 1: Privacy Policy URL

When asked for Privacy Policy URL:
- Host your privacy policy at a public URL
- Example: `https://yourdomain.com/atlasTracker/privacy`
- Or use GitHub Pages: `https://yourusername.github.io/atlas-tracker-privacy/`

### Step 2: Data Collection Declaration

1. Log into App Store Connect
2. Go to your app > App Privacy
3. Click "Get Started"
4. Question: "Do you or your third-party partners collect data from this app?"
5. Select: **No, we do not collect data from this app**
6. Save

### Step 3: If Apple Questions Your Declaration

If Apple's review team asks for clarification about HealthKit:

**Sample Response:**
```
Atlas Tracker reads and writes body weight data using HealthKit.
This data remains entirely on the user's device within the HealthKit
ecosystem. The app does not transmit any HealthKit data to external
servers. There are no analytics, no crash reporting, and no third-party
SDKs in the app. All data is stored locally using Core Data with
NSFileProtectionComplete encryption.

HealthKit data is used solely to:
1. Display the user's weight history alongside their supplement tracking
2. Allow users to log weight entries that sync with Apple Health

Per Apple's privacy label guidelines, this local-only usage does not
constitute "data collection" as the data never leaves the device.
```

---

## App Store Privacy Label Preview

Based on our declarations, Atlas Tracker's App Store privacy label will show:

```
┌─────────────────────────────────────────┐
│  Data Not Collected                     │
│                                         │
│  The developer does not collect any     │
│  data from this app.                    │
└─────────────────────────────────────────┘
```

This is the **best possible privacy label** an app can have.

---

## Verification Checklist

Before submitting, verify:

- [ ] No analytics SDKs (Firebase Analytics, Mixpanel, etc.)
- [ ] No crash reporting SDKs (Crashlytics, Sentry, etc.)
- [ ] No advertising SDKs (AdMob, Facebook Ads, etc.)
- [ ] No third-party authentication (Sign in with Google, Facebook, etc.)
- [ ] No server communication (REST APIs, GraphQL, WebSocket)
- [ ] No push notification server (only local notifications)
- [ ] HealthKit data stays on device
- [ ] Core Data is local-only (no CloudKit sync)
- [ ] No device identifiers collected
- [ ] No user accounts

**Atlas Tracker Status: ✅ All verified**

---

## If You Add Features Later

If you later add features that DO collect data, you must update your privacy labels:

| Feature Added | Privacy Impact |
|---------------|----------------|
| Cloud sync (CloudKit) | Must declare Health & Fitness data |
| Analytics | Must declare Usage Data |
| Crash reporting | Must declare Diagnostics |
| User accounts | Must declare Contact Info, Identifiers |
| Push notifications (server) | Must declare Identifiers |

**Current Atlas Tracker: None of these features exist.**

---

## References

- [Apple: App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple: HealthKit and Privacy](https://developer.apple.com/documentation/healthkit/protecting_user_privacy)
- [App Store Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)
