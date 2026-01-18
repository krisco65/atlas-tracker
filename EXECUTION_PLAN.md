# Atlas Tracker Autonomous Execution Plan

**Created:** 2026-01-18
**Status:** AWAITING APPROVAL
**Estimated Duration:** 8-12 hours

---

## Executive Summary

This plan addresses 23 tasks across 3 priority tiers based on comprehensive analysis of:
- Injection site rotation algorithm
- App architecture (7.5/10 score)
- Code quality review (CRITICAL/HIGH/MEDIUM/LOW issues)
- Security audit (2 HIGH, 5 MEDIUM issues)
- Test coverage (45-50%, target 80%)
- Core Data model relationships

---

## Pre-Execution Checklist

- [ ] Git status clean (confirmed: main branch, no uncommitted changes)
- [ ] Current build compiles successfully
- [ ] Backup strategy: All changes committed incrementally
- [ ] Rollback strategy: Git revert to last known good commit

---

## TIER 1: CRITICAL (Must Complete)

### Task 1.1: Replace fatalError in CoreDataManager
| Attribute | Value |
|-----------|-------|
| **File** | `Services/CoreDataManager.swift:29` |
| **Risk** | HIGH - App crashes permanently |
| **Dependencies** | None |
| **Agent** | None (direct fix) |
| **Commit** | `Fix: Replace fatalError with graceful Core Data error handling` |

**Implementation:**
```swift
// Replace fatalError with:
// 1. Log error with details
// 2. Set error state flag
// 3. Show user-friendly alert
// 4. Allow app to continue in degraded mode
```

**Test Plan:**
- [ ] Force Core Data failure (invalid store URL)
- [ ] Verify app doesn't crash
- [ ] Verify error message displays

---

### Task 1.2: Fix Force Unwraps in Date+Extensions
| Attribute | Value |
|-----------|-------|
| **File** | `Utilities/Extensions/Date+Extensions.swift` |
| **Lines** | 78, 85, 92, 100, 105, 110 |
| **Risk** | HIGH - Potential crashes on edge cases |
| **Dependencies** | None |
| **Agent** | None (direct fix) |
| **Commit** | `Fix: Remove force unwraps from Date+Extensions` |

**Implementation:**
```swift
// Replace:
return Calendar.current.date(byAdding: components, to: startOfDay)!

// With:
return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
```

**Test Plan:**
- [ ] Run DateExtensionsTests
- [ ] Test edge cases (year boundaries, DST transitions)

---

### Task 1.3: Wrap Debug Print Statements
| Attribute | Value |
|-----------|-------|
| **Files** | CoreDataManager, SeedDataService, HealthKitService, NotificationService |
| **Count** | 50+ print statements |
| **Risk** | MEDIUM - Information disclosure |
| **Dependencies** | None |
| **Agent** | None (direct fix) |
| **Commit** | `Fix: Wrap debug prints in #if DEBUG` |

**Implementation:**
1. Create `Utilities/Logger.swift` with debug-only logging
2. Find/replace all `print()` calls
3. Use `Logger.debug()` for development output

**Test Plan:**
- [ ] Build in Release mode
- [ ] Verify no console output

---

### Task 1.4: Add Core Data Validation
| Attribute | Value |
|-----------|-------|
| **Files** | DoseLog, Inventory, TrackedCompound entity classes |
| **Risk** | HIGH - Data integrity |
| **Dependencies** | None |
| **Agent** | database-agent |
| **Commit** | `Fix: Add Core Data validation and fix delete rules` |

**Implementation:**
1. Add `validateForInsert()` and `validateForUpdate()` overrides
2. Validate: dosageAmount > 0, vialCount >= 0, weight > 0
3. Change delete rules from NULLIFY to DENY for required relationships

**Test Plan:**
- [ ] Try to insert invalid DoseLog (negative dosage)
- [ ] Try to delete Compound with active TrackedCompound
- [ ] Verify validation errors are thrown

---

### Task 1.5: Add Input Validation to Views
| Attribute | Value |
|-----------|-------|
| **Files** | AddCustomCompoundView, LogDoseView |
| **Risk** | MEDIUM - Data quality |
| **Dependencies** | Task 1.4 |
| **Agent** | ui-designer-agent |
| **Commit** | `Feature: Add input validation with user feedback` |

**Implementation:**
- Compound name: max 100 characters
- Notes: max 1000 characters
- Dosage: 0 < amount < 10000
- Add visual feedback for validation errors

**Test Plan:**
- [ ] Enter 101+ character name - should truncate
- [ ] Enter 0 or negative dosage - should show error
- [ ] Enter valid data - should save successfully

---

## TIER 2: HIGH PRIORITY (Complete if Time Permits)

### Task 2.1: Time-Weighted Injection Site Scoring
| Attribute | Value |
|-----------|-------|
| **File** | `Services/InjectionSiteRecommendationService.swift` |
| **Risk** | LOW - Algorithm improvement |
| **Dependencies** | None |
| **Agent** | None |
| **Commit** | `Feature: Add time-weighted injection site scoring` |

**Implementation:**
```swift
func calculateSiteScore(_ site: PEDInjectionSite, history: [DoseLog]) -> Double {
    var score = 0.0
    let now = Date()
    for log in history where log.injectionSite == site {
        let daysSince = now.daysBetween(log.timestamp ?? now)
        score += 1.0 / Double(daysSince + 1)  // Recent = higher penalty
    }
    return score  // Lower is better
}
```

**Test Plan:**
- [ ] Create test with recent vs old injections
- [ ] Verify recent sites have higher scores (deprioritized)
- [ ] Run InjectionSiteRecommendationServiceTests

---

### Task 2.2: Secondary Sort by Recency
| Attribute | Value |
|-----------|-------|
| **File** | `Services/InjectionSiteRecommendationService.swift` |
| **Risk** | LOW |
| **Dependencies** | Task 2.1 |
| **Agent** | None |
| **Commit** | `Feature: Add recency-based tie-breaking for injection sites` |

**Implementation:**
```swift
// When sites have equal frequency, sort by last used date
let candidates = leastUsed.sorted {
    lastUsedDate($0) < lastUsedDate($1)  // Oldest first
}
```

**Test Plan:**
- [ ] Create 2 sites with equal usage count
- [ ] Verify older site is selected

---

### Task 2.3: Extended History Window
| Attribute | Value |
|-----------|-------|
| **File** | `Utilities/Constants.swift` |
| **Risk** | LOW |
| **Dependencies** | None |
| **Agent** | None |
| **Commit** | `Feature: Extend injection site history to 20 injections` |

**Implementation:**
```swift
enum InjectionRotation {
    static let historyLookback = 20   // Was 10
    static let statsLookback = 50     // For analytics
}
```

**Test Plan:**
- [ ] Verify algorithm uses 20-injection window
- [ ] Check performance with larger history

---

### Task 2.4: Body Part Balancing
| Attribute | Value |
|-----------|-------|
| **File** | `Services/InjectionSiteRecommendationService.swift` |
| **Risk** | MEDIUM - Algorithm change |
| **Dependencies** | Tasks 2.1-2.3 |
| **Agent** | None |
| **Commit** | `Feature: Add body part balancing to injection rotation` |

**Implementation:**
```swift
// Two-tier selection:
// 1. Find least-used body part
// 2. Pick least-used site within that body part
let bodyPartUsage = groupSitesByBodyPart(history)
let leastUsedPart = bodyPartUsage.min(by: { $0.count < $1.count })
let sitesInPart = allSites.filter { $0.bodyPart == leastUsedPart?.key }
```

**Test Plan:**
- [ ] Use only glute sites repeatedly
- [ ] Verify algorithm recommends different body part
- [ ] Test full rotation cycle

---

### Task 2.5: Migrate ViewModels to @Observable
| Attribute | Value |
|-----------|-------|
| **Files** | All 5 ViewModel files |
| **Risk** | MEDIUM - Breaking change |
| **Dependencies** | None |
| **Agent** | code-reviewer |
| **Commit** | `Refactor: Migrate ViewModels from ObservableObject to @Observable` |

**Implementation:**
```swift
// From:
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
}

// To:
@Observable
final class DashboardViewModel {
    var isLoading = false
}
```

**Files to Modify:**
1. DashboardViewModel.swift
2. LibraryViewModel.swift
3. DoseLogViewModel.swift
4. CompoundDetailViewModel.swift
5. ReconstitutionViewModel.swift

**Test Plan:**
- [ ] Build successfully
- [ ] Run all ViewModel tests
- [ ] Verify UI updates work correctly

---

### Task 2.6: Add Tests for NotificationService
| Attribute | Value |
|-----------|-------|
| **File** | NEW: `AtlasTrackerTests/ServiceTests/NotificationServiceTests.swift` |
| **Risk** | LOW |
| **Dependencies** | None |
| **Agent** | tdd-guide |
| **Commit** | `Test: Add NotificationService tests` |

**Test Cases:**
- [ ] testScheduleDoseReminder_SchedulesCorrectly
- [ ] testSnoozeNotification_AddsCorrectDelay
- [ ] testCancelNotification_RemovesFromQueue
- [ ] testRecurringNotification_CreatesMultiple

**Target Coverage:** 70%

---

### Task 2.7: Add Tests for CompoundDetailViewModel
| Attribute | Value |
|-----------|-------|
| **File** | NEW: `AtlasTrackerTests/ViewModelTests/CompoundDetailViewModelTests.swift` |
| **Risk** | LOW |
| **Dependencies** | None |
| **Agent** | tdd-guide |
| **Commit** | `Test: Add CompoundDetailViewModel tests` |

**Test Cases:**
- [ ] testStartTracking_CreatesTrackedCompound
- [ ] testStopTracking_DeletesTrackedCompound
- [ ] testUpdateTracking_ModifiesSchedule
- [ ] testCanSaveTracking_ValidatesInput

**Target Coverage:** 80%

---

## TIER 3: MEDIUM PRIORITY (Nice to Have)

### Task 3.1: Add Core Data Indexes
| Attribute | Value |
|-----------|-------|
| **File** | `Models/CoreData/CoreDataModel.swift` |
| **Risk** | LOW |
| **Dependencies** | None |
| **Agent** | database-agent |
| **Commit** | `Perf: Add Core Data fetch indexes` |

**Indexes to Add:**
- Compound: name, categoryRaw
- DoseLog: timestamp, compound
- Inventory: compound

---

### Task 3.2: Add Unique Constraint on Compound Name
| Attribute | Value |
|-----------|-------|
| **File** | `Models/CoreData/CoreDataModel.swift` |
| **Risk** | MEDIUM - Requires migration |
| **Dependencies** | None |
| **Agent** | database-agent |
| **Commit** | `Fix: Add unique constraint on compound names` |

---

### Task 3.3: Change Inventory to 1:1 Relationship
| Attribute | Value |
|-----------|-------|
| **File** | `Models/CoreData/CoreDataModel.swift` |
| **Risk** | HIGH - Requires data migration |
| **Dependencies** | Task 3.2 |
| **Agent** | database-agent |
| **Commit** | `Refactor: Change Inventory to 1:1 relationship` |

**Migration Required:** Yes - need to handle existing data

---

### Task 3.4: Extract DashboardView Subviews
| Attribute | Value |
|-----------|-------|
| **Files** | `Views/Dashboard/DashboardView.swift` → multiple files |
| **Risk** | LOW |
| **Dependencies** | None |
| **Agent** | ui-designer-agent |
| **Commit** | `Refactor: Extract DashboardView subviews` |

**Extract:**
- TodayDoseCard.swift
- StatCard.swift
- RecentLogRow.swift
- QuickLogSheet.swift
- ActiveCompoundsSheet.swift
- ActiveCompoundRow.swift

---

### Task 3.5: Rotation Quality Score
| Attribute | Value |
|-----------|-------|
| **File** | `Services/InjectionSiteRecommendationService.swift` |
| **Risk** | LOW |
| **Dependencies** | Tasks 2.1-2.4 |
| **Agent** | None |
| **Commit** | `Feature: Add injection rotation quality scoring` |

---

### Task 3.6: Minimum Interval Enforcement
| Attribute | Value |
|-----------|-------|
| **File** | `Services/InjectionSiteRecommendationService.swift` |
| **Risk** | LOW |
| **Dependencies** | Task 3.5 |
| **Agent** | None |
| **Commit** | `Feature: Add minimum interval enforcement` |

---

## Dependency Graph

```
TIER 1 (Critical) - No dependencies, can run in parallel
├── Task 1.1: fatalError fix
├── Task 1.2: Force unwraps
├── Task 1.3: Print statements
├── Task 1.4: Core Data validation
└── Task 1.5: Input validation (depends on 1.4)

TIER 2 (High) - Some dependencies
├── Task 2.1: Time-weighted scoring
├── Task 2.2: Recency sort (depends on 2.1)
├── Task 2.3: Extended history
├── Task 2.4: Body part balancing (depends on 2.1-2.3)
├── Task 2.5: @Observable migration
├── Task 2.6: NotificationService tests
└── Task 2.7: CompoundDetailViewModel tests

TIER 3 (Medium) - Some dependencies
├── Task 3.1: Core Data indexes
├── Task 3.2: Unique constraint
├── Task 3.3: Inventory 1:1 (depends on 3.2)
├── Task 3.4: Extract DashboardView
├── Task 3.5: Rotation quality (depends on 2.1-2.4)
└── Task 3.6: Minimum interval (depends on 3.5)
```

---

## Execution Order

### Phase 1: Critical Fixes (2-3 hours)
```
1.1 → 1.2 → 1.3 → 1.4 → 1.5
     ↓
   COMMIT & PUSH
     ↓
   BUILD TEST
```

### Phase 2: Injection Algorithm (2-3 hours)
```
2.3 → 2.1 → 2.2 → 2.4
     ↓
   COMMIT & PUSH
     ↓
   ALGORITHM TESTS
```

### Phase 3: Architecture & Testing (3-4 hours)
```
2.5 → 2.6 → 2.7
     ↓
   COMMIT & PUSH
     ↓
   COVERAGE CHECK
```

### Phase 4: Polish (1-2 hours, if time)
```
3.1 → 3.2 → 3.4
     ↓
   COMMIT & PUSH
     ↓
   FINAL BUILD
```

---

## Commit Strategy

| After Tasks | Commit Message | Push? |
|-------------|----------------|-------|
| 1.1 | Fix: Replace fatalError with graceful error handling | No |
| 1.2 | Fix: Remove force unwraps from Date+Extensions | No |
| 1.3 | Fix: Wrap debug prints in #if DEBUG | Yes |
| 1.4 | Fix: Add Core Data validation | No |
| 1.5 | Feature: Add input validation with user feedback | Yes |
| 2.1-2.2 | Feature: Improve injection site algorithm scoring | No |
| 2.3-2.4 | Feature: Add body part balancing to rotation | Yes |
| 2.5 | Refactor: Migrate ViewModels to @Observable | Yes |
| 2.6-2.7 | Test: Add tests for critical services | Yes |
| 3.1-3.4 | Refactor: Code quality improvements | Yes |

**Total Commits:** ~10-12
**Total Pushes:** ~6

---

## Risk Assessment

| Task | Risk Level | Mitigation |
|------|------------|------------|
| 1.1 fatalError | LOW | Simple replacement, well-defined |
| 1.2 Force unwraps | LOW | Safe optional handling |
| 1.3 Print statements | LOW | Find/replace operation |
| 1.4 Core Data validation | MEDIUM | Test thoroughly, can revert |
| 1.5 Input validation | LOW | UI-only changes |
| 2.1-2.4 Algorithm | MEDIUM | Extensive testing, preserve old logic |
| 2.5 @Observable | MEDIUM | May require View updates |
| 2.6-2.7 Tests | LOW | Additive only |
| 3.2 Unique constraint | HIGH | Requires migration strategy |
| 3.3 Inventory 1:1 | HIGH | Requires data migration |

---

## Testing Checkpoints

### Checkpoint 1: After TIER 1
- [ ] App builds successfully
- [ ] App launches without crash
- [ ] Can log a dose
- [ ] Can add compound to tracking
- [ ] Core Data operations work

### Checkpoint 2: After Algorithm Changes
- [ ] InjectionSiteRecommendationServiceTests pass
- [ ] Recommendation changes based on history
- [ ] Body part rotation works correctly

### Checkpoint 3: After @Observable Migration
- [ ] All ViewModel tests pass
- [ ] Dashboard loads data correctly
- [ ] Library search/filter works
- [ ] Dose logging works

### Checkpoint 4: Final
- [ ] Full test suite passes
- [ ] Coverage ≥ 60% (stretch: 80%)
- [ ] No compiler warnings
- [ ] Clean build in Release mode

---

## Rollback Plan

If any phase fails critically:

1. **Identify failing commit:** `git log --oneline`
2. **Revert to last good state:** `git revert HEAD~N..HEAD`
3. **Push revert:** `git push`
4. **Document failure:** Add to ISSUES.md
5. **Continue with next independent task**

---

## Success Criteria

### Minimum (Must Achieve)
- [ ] All TIER 1 tasks completed
- [ ] No app crashes
- [ ] Clean build

### Target (Should Achieve)
- [ ] TIER 1 + TIER 2 tasks completed
- [ ] Test coverage ≥ 60%
- [ ] All existing tests pass

### Stretch (Nice to Achieve)
- [ ] All tasks completed
- [ ] Test coverage ≥ 80%
- [ ] Documentation updated

---

## Agent Utilization Plan

| Agent | Tasks | When to Use |
|-------|-------|-------------|
| database-agent | 1.4, 3.1, 3.2, 3.3 | Core Data changes |
| tdd-guide | 2.6, 2.7 | Writing new tests |
| code-reviewer | After 2.5 | Review @Observable migration |
| security-reviewer | After 1.4 | Verify data validation |
| build-error-resolver | As needed | Any build failures |
| ui-designer-agent | 1.5, 3.4 | UI/validation changes |

---

## Estimated Timeline

| Phase | Tasks | Duration |
|-------|-------|----------|
| Phase 1 | 1.1-1.5 | 2-3 hours |
| Phase 2 | 2.1-2.4 | 2-3 hours |
| Phase 3 | 2.5-2.7 | 2-3 hours |
| Phase 4 | 3.1-3.4 | 1-2 hours |
| **Total** | | **8-12 hours** |

---

## Approval Request

**This plan covers:**
- 5 CRITICAL fixes (crash prevention, data integrity)
- 7 HIGH priority improvements (algorithm, testing)
- 6 MEDIUM priority enhancements (code quality)

**Risks are mitigated by:**
- Incremental commits after each task
- Testing checkpoints between phases
- Rollback plan for failures
- Agent specialization for complex tasks

**Ready to execute upon approval.**

---

*Plan Version: 1.0*
*Awaiting: User Approval*
