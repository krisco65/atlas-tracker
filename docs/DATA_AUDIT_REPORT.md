# Atlas Tracker Data Audit Report

**Audit Date:** January 2026
**Auditor:** Automated Code Analysis
**App Version:** 1.0.0

---

## Executive Summary

Atlas Tracker is a **privacy-first** health tracking application. All user data remains on-device with no external transmission. The app achieves the highest privacy standard possible for a health app.

| Category | Status |
|----------|--------|
| External Data Transmission | ✅ None |
| Third-Party SDKs | ✅ None |
| Analytics/Tracking | ✅ None |
| User Identifiers | ✅ None collected |
| Data Encryption | ✅ NSFileProtectionComplete |
| HealthKit Compliance | ✅ Compliant |

---

## 1. Core Data Entities (Local Database)

### 1.1 Compound Entity
Stores information about medications, supplements, and compounds.

| Attribute | Type | Purpose | Sensitive? |
|-----------|------|---------|------------|
| id | UUID | Unique identifier | No |
| name | String | Compound name | Low |
| categoryRaw | String | Category (supplement/ped/peptide/medicine) | Low |
| supportedUnitsRaw | [String] | Available dosage units | No |
| defaultUnitRaw | String | Default unit | No |
| requiresInjection | Boolean | Whether injectable | No |
| recommendedSitesRaw | [String] | Injection site options | No |
| notes | String? | User notes | Medium |
| isFavorited | Boolean | User preference | No |
| useCount | Int64 | Usage frequency | Low |
| isCustom | Boolean | User-created vs seed data | No |
| createdAt | Date | Creation timestamp | No |

### 1.2 TrackedCompound Entity
Stores user's active tracking configurations.

| Attribute | Type | Purpose | Sensitive? |
|-----------|------|---------|------------|
| id | UUID | Unique identifier | No |
| dosageAmount | Double | Dose amount | Medium |
| dosageUnitRaw | String | Dose unit | No |
| scheduleTypeRaw | String | Schedule type | Low |
| scheduleInterval | Int16 | Days between doses | Low |
| scheduleDaysRaw | [Int16]? | Specific weekdays | Low |
| notificationEnabled | Boolean | Reminder setting | No |
| notificationTime | Date? | Reminder time | No |
| isActive | Boolean | Currently tracking | No |
| startDate | Date | When tracking started | Low |
| lastDoseDate | Date? | Most recent dose | Medium |
| reconstitutionBAC | Double | Reconstitution data | Low |
| reconstitutionConcentration | Double | Concentration | Low |

### 1.3 DoseLog Entity
Stores dose history records.

| Attribute | Type | Purpose | Sensitive? |
|-----------|------|---------|------------|
| id | UUID | Unique identifier | No |
| dosageAmount | Double | Amount taken | Medium |
| dosageUnitRaw | String | Unit | No |
| timestamp | Date | When taken | Medium |
| injectionSiteRaw | String? | Body location | Medium |
| sideEffectsRaw | [String]? | Reported effects | **High** |
| notes | String? | User notes | Medium |

### 1.4 Inventory Entity
Stores supply/stock information.

| Attribute | Type | Purpose | Sensitive? |
|-----------|------|---------|------------|
| id | UUID | Unique identifier | No |
| vialCount | Int16 | Number of vials | Low |
| vialSizeMg | Double | Vial size | No |
| remainingInCurrentVial | Double | Current supply | Low |
| lowStockThreshold | Int16 | Alert threshold | No |
| autoDecrement | Boolean | Auto-update setting | No |
| lastUpdated | Date | Last change | No |

### 1.5 WeightEntry Entity
Stores weight tracking records.

| Attribute | Type | Purpose | Sensitive? |
|-----------|------|---------|------------|
| id | UUID | Unique identifier | No |
| weight | Double | Weight value | Medium |
| unitRaw | String | lbs or kg | No |
| date | Date | Entry date | Low |
| notes | String? | User notes | Low |

---

## 2. UserDefaults (Preferences)

| Key | Type | Purpose | Sensitive? |
|-----|------|---------|------------|
| hasCompletedOnboarding | Boolean | Skip intro screens | No |
| preferredWeightUnit | String | lbs/kg preference | No |
| biometricEnabled | Boolean | Face ID lock setting | No |
| notificationsEnabled | Boolean | Push notification setting | No |
| discreetNotifications | Boolean | Hide content in notifications | No |
| lastSeedDataVersion | Int | Track data migrations | No |

**Location:** `AtlasTracker/Utilities/Constants.swift:12-19`

---

## 3. Apple Health (HealthKit) Integration

**Location:** `AtlasTracker/Services/HealthKitService.swift`

### Data Types Accessed

| HealthKit Type | Access | Purpose |
|----------------|--------|---------|
| HKQuantityType.bodyMass | Read | Import weight from Health app |
| HKQuantityType.bodyMass | Write | Export weight to Health app |

### No Other Health Data

The following are **NOT** accessed:
- Heart rate
- Blood pressure
- Sleep data
- Activity/steps
- Nutrition
- Medications (Apple's Medications feature)
- Any other HealthKit data types

### HealthKit Code Locations

| File | Line | Function |
|------|------|----------|
| HealthKitService.swift | 32 | requestAuthorization() |
| HealthKitService.swift | 66 | fetchWeightEntries() |
| HealthKitService.swift | 115 | fetchLatestWeight() |
| HealthKitService.swift | 159 | saveWeight() |

---

## 4. Face ID / Biometric Authentication

**Location:** `AtlasTracker/App/AtlasTrackerApp.swift`

### Implementation

- Uses Apple's `LocalAuthentication` framework (LAContext)
- App only receives authentication result (success/failure)
- **No biometric data is ever accessible to the app**
- Biometric templates stored in Secure Enclave (Apple hardware)

### What Happens

1. User enables biometric lock in Settings
2. `biometricEnabled` UserDefaults flag set to true
3. On app launch, LAContext.evaluatePolicy() is called
4. iOS shows Face ID/Touch ID prompt
5. App receives boolean result only

---

## 5. Network Activity

### Analysis Result: **NONE**

Searched for:
- URLSession
- URLRequest
- Alamofire
- HTTP/HTTPS URLs
- WebSocket
- Network framework

**Finding:** No network requests in codebase. App is fully offline.

---

## 6. Third-Party Dependencies

### Analysis Result: **NONE**

No third-party SDKs detected:
- ❌ No Firebase
- ❌ No Google Analytics
- ❌ No Facebook SDK
- ❌ No Crashlytics/Sentry
- ❌ No advertising SDKs
- ❌ No social login SDKs

**Only Apple frameworks used:**
- SwiftUI
- CoreData
- HealthKit
- LocalAuthentication
- UserNotifications

---

## 7. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER'S DEVICE                           │
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │   Atlas Tracker │────▶│   Core Data     │                   │
│  │       App       │◀────│   (Local DB)    │                   │
│  └────────┬────────┘     └─────────────────┘                   │
│           │                                                     │
│           │ Read/Write                                          │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │   Apple Health  │ (Weight data only)                        │
│  │   (HealthKit)   │                                           │
│  └─────────────────┘                                           │
│                                                                 │
│  ┌─────────────────┐                                           │
│  │   UserDefaults  │ (Preferences only)                        │
│  └─────────────────┘                                           │
│                                                                 │
│  ┌─────────────────┐                                           │
│  │  Secure Enclave │ (Face ID - Apple managed)                 │
│  └─────────────────┘                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ NO DATA LEAVES DEVICE
                              ▼
                    ┌─────────────────┐
                    │   NO SERVERS    │
                    │   NO CLOUD      │
                    │   NO ANALYTICS  │
                    └─────────────────┘
```

---

## 8. Data Retention

| Data Type | Retention | Deletion Method |
|-----------|-----------|-----------------|
| Core Data entities | Until user deletes | In-app deletion or app uninstall |
| UserDefaults | Until app uninstall | App uninstall |
| HealthKit data | Managed by Apple Health | Health app settings |

**No automatic data deletion** - user has full control.

---

## 9. Data Export Capability

**Location:** `AtlasTracker/Services/DataExportService.swift`

Users can export their data in standard formats. This supports GDPR's "right to data portability."

---

## 10. Encryption Status

### At Rest
- **NSFileProtectionComplete** enabled in entitlements
- Data encrypted when device is locked
- Uses iOS hardware encryption

### In Transit
- **N/A** - No data transmission occurs

---

## 11. Sensitive Data Identification

### High Sensitivity
- Side effects (health symptoms)
- Dose logs (medication usage patterns)

### Medium Sensitivity
- Weight entries
- Dosage amounts
- Injection sites
- User notes

### Low Sensitivity
- Compound names (from public seed data)
- Schedule preferences
- UI preferences

---

## 12. Compliance Summary

| Regulation | Status | Notes |
|------------|--------|-------|
| Apple App Store | ✅ Compliant | No data collection declared |
| HealthKit Guidelines | ✅ Compliant | Weight only, local storage |
| GDPR (EU) | ✅ Compliant | No PII collected, data export available |
| CCPA (California) | ✅ Compliant | No sale of data |
| HIPAA | ⚠️ N/A | Not a covered entity |

---

## 13. Recommendations

### Current Security Measures (Good)
1. ✅ NSFileProtectionComplete encryption
2. ✅ No network transmission
3. ✅ No third-party SDKs
4. ✅ Biometric authentication available
5. ✅ Data export functionality

### Potential Improvements (Optional)
1. Consider adding in-app data deletion feature (beyond app uninstall)
2. Add confirmation prompts before exporting sensitive data
3. Consider keychain storage for any future sensitive preferences

---

## Appendix: Files Audited

| File | Contains User Data |
|------|-------------------|
| AtlasTracker/Services/CoreDataManager.swift | Yes - manages all Core Data |
| AtlasTracker/Services/HealthKitService.swift | Yes - HealthKit integration |
| AtlasTracker/Utilities/Constants.swift | Yes - UserDefaults keys |
| AtlasTracker/App/AtlasTrackerApp.swift | Yes - biometric auth |
| AtlasTracker/Models/CoreData/*.swift | Yes - data model definitions |
| AtlasTracker.entitlements | No - config only |
| Info.plist | No - config only |

---

**Audit Complete**
