# Atlas Tracker Comprehensive Improvement Plan

## Executive Summary

| Area | Score | Status |
|------|-------|--------|
| Architecture | 7.5/10 | Good foundation, needs DI |
| Code Quality | 6.5/10 | Force unwraps, print statements |
| Security | 8/10 | Strong, minor issues |
| Test Coverage | 45-50% | Below 80% target |

**Overall Health: MODERATE** - Solid app with clear improvement opportunities.

---

## Critical Issues (Fix Immediately)

### 1. Fatal Error Crashes App
**File:** `Services/CoreDataManager.swift:29`
```swift
fatalError("Unable to load persistent stores: \(error)")
```
**Risk:** App crashes permanently if Core Data corrupts.
**Fix:** Implement graceful error handling with recovery option.

### 2. Force Unwraps in Date Extensions
**File:** `Utilities/Extensions/Date+Extensions.swift:78, 85, 92, 100, 105, 110`
**Risk:** Potential crashes on calendar edge cases.
**Fix:** Use nil-coalescing with safe defaults.

### 3. ViewModels Use ObservableObject (Violates Project Rules)
**Files:** All 5 ViewModels
**Rule:** "Use @Observable for ViewModels (not ObservableObject)"
**Fix:** Migrate to `@Observable` macro.

---

## High Priority (Fix This Sprint)

### 4. No Dependency Injection
**Impact:** Cannot unit test ViewModels properly.
**Fix:** Create protocols for services, use constructor injection.
```swift
protocol DataManaging {
    func fetchAllCompounds() -> [Compound]
}

@Observable
final class LibraryViewModel {
    private let dataManager: DataManaging
    init(dataManager: DataManaging = CoreDataManager.shared) {
        self.dataManager = dataManager
    }
}
```

### 5. Debug Print Statements (50+ instances)
**Files:** CoreDataManager, SeedDataService, HealthKitService, NotificationService
**Risk:** Information disclosure in production.
**Fix:** Wrap in `#if DEBUG` or replace with proper logging.

### 6. Missing Input Validation
- Compound name: No length limit
- Notes field: Unbounded
- Dosage amount: No upper limit
**Fix:** Add validation (100 chars for name, 1000 for notes, 10000 max dosage).

### 7. Critical Test Gaps
| Missing Tests | Risk Level |
|--------------|------------|
| NotificationService | HIGH - missed doses |
| CompoundDetailViewModel | HIGH - core feature |
| InventoryViewModel | HIGH - tracking errors |
| SeedDataService | MEDIUM - empty database |

---

## Medium Priority (Next 2 Sprints)

### 8. Split CoreDataManager (God Object - 519 lines)
Create separate repositories:
- `CompoundRepository`
- `DoseLogRepository`
- `InventoryRepository`
- `WeightEntryRepository`

### 9. Extract Large View Files
| File | Lines | Action |
|------|-------|--------|
| CompoundDetailView | 816 | Extract AddInventorySheetForCompound |
| VisualBodySilhouette | 566 | Extract overlays to separate files |
| DashboardView | 534 | Extract 6 embedded views |

### 10. Add Core Data Migration Support
- No migration strategy currently exists
- Add versioned data model
- Implement lightweight migration

### 11. Biometric Re-authentication
Current: Simple `@State` variable stores auth state.
Fix: Re-authenticate on app resume, add timeout.

### 12. Notification Privacy
Notifications show compound names on lock screen.
Fix: Add setting to hide content until unlocked.

---

## Low Priority (Backlog)

### 13. Duplicated DateFormatter Methods
`Date+Extensions.swift` has both cached formatters AND creates new ones.
Fix: Remove duplicates, use cached `format(_:)` consistently.

### 14. Magic Numbers in VisualBodySilhouette
`buttonSize: CGFloat = 40` vs `buttonSize: CGFloat = 36`
Fix: Define in AppConstants with documentation.

### 15. Unnecessary DispatchQueue.main.async
Multiple ViewModels dispatch to main when already on main.
Fix: Remove or use proper background context.

### 16. Potential Retain Cycle
`DoseLogViewModel.swift:193-195` - strong self capture in delayed closure.
Fix: Add `[weak self]`.

---

## Implementation Roadmap

### Phase 1: Stability (Week 1)
- [ ] Fix fatalError in CoreDataManager
- [ ] Fix force unwraps in Date extensions
- [ ] Wrap print statements in #if DEBUG
- [ ] Add input validation

### Phase 2: Architecture (Weeks 2-3)
- [ ] Create service protocols
- [ ] Implement dependency injection in ViewModels
- [ ] Migrate ViewModels to @Observable
- [ ] Split CoreDataManager into repositories

### Phase 3: Testing (Weeks 3-4)
- [ ] Add NotificationServiceTests
- [ ] Add CompoundDetailViewModelTests
- [ ] Add InventoryViewModelTests
- [ ] Create in-memory Core Data test stack
- [ ] Target 80% coverage

### Phase 4: Polish (Week 5)
- [ ] Extract large View files
- [ ] Add Core Data migration support
- [ ] Implement biometric re-auth on resume
- [ ] Add notification privacy settings

---

## Files Requiring Changes

### Immediate Changes
| File | Issue | Priority |
|------|-------|----------|
| `Services/CoreDataManager.swift` | fatalError, prints | CRITICAL |
| `Utilities/Extensions/Date+Extensions.swift` | Force unwraps | CRITICAL |
| `ViewModels/*.swift` (all 5) | ObservableObject | HIGH |
| `Views/Library/AddCustomCompoundView.swift` | Input validation | HIGH |
| `Views/DoseLog/LogDoseView.swift` | Notes validation | HIGH |

### Architectural Changes
| File | Change | Priority |
|------|--------|----------|
| NEW `Protocols/DataManaging.swift` | Service protocols | HIGH |
| NEW `Repositories/*.swift` | Split CoreDataManager | MEDIUM |
| `Views/Dashboard/Components/*.swift` | Extract from DashboardView | MEDIUM |
| `Views/CompoundDetail/Components/*.swift` | Extract AddInventorySheet | MEDIUM |

### New Test Files
| File | Coverage Target |
|------|-----------------|
| `NotificationServiceTests.swift` | 70% |
| `CompoundDetailViewModelTests.swift` | 80% |
| `InventoryViewModelTests.swift` | 80% |
| `SeedDataServiceTests.swift` | 70% |
| `HealthKitServiceTests.swift` | 60% |

---

## Security Checklist

- [x] Core Data encryption enabled
- [x] Data Protection entitlement set
- [x] Biometric authentication available
- [x] No hardcoded secrets
- [x] No network communication (local only)
- [x] Parameterized Core Data queries
- [ ] Input length validation
- [ ] Debug logging disabled in production
- [ ] Dosage range validation
- [ ] Crash-safe error handling

---

## Metrics to Track

| Metric | Current | Target |
|--------|---------|--------|
| Test Coverage | 45-50% | 80%+ |
| Architecture Score | 7.5/10 | 9/10 |
| Files > 500 lines | 3 | 0 |
| Force Unwraps (risky) | 6 | 0 |
| Print Statements | 50+ | 0 (prod) |
| Services with Protocols | 0/5 | 5/5 |

---

*Generated: 2026-01-18*
