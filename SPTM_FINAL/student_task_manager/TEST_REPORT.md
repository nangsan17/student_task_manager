# Automated System Testing Report

**Application:** Student Productivity & Task Management (SPTM)
**Module:** CT124-3-2 Mobile App Engineering — Group Assignment (Part 2)
**Group:** G27

---

## 1. Objective

This report documents the automated testing performed on the SPTM application.
The goal is to verify that the core business logic and key user-interface flows
behave correctly and remain stable across changes, using an industry-standard
test framework rather than manual checking alone.

## 2. Testing framework and tools

| Tool | Purpose |
| --- | --- |
| `flutter_test` | First-party Flutter framework for unit and widget tests |
| `WidgetTester` | Pumps widgets and simulates user interaction for UI tests |
| `mockito` + `build_runner` | Available for mocking services in future integration tests |
| `flutter test --coverage` | Generates line-coverage data (`lcov.info`) |

All tests are deterministic and run on the Dart VM with no live Firebase
connection, so they execute the same way locally and in CI.

## 3. Test strategy

Testing is split into two layers:

1. **Unit tests** — exercise pure business logic in the model layer
   (prioritisation algorithm, deadline state, progress, serialisation).
   These are the highest-value tests because the prioritisation and reminder
   behaviour is the heart of the app's research-driven value proposition.
2. **Widget tests** — exercise the UI layer (rendering and navigation) for the
   onboarding flow, confirming screens build and respond to interaction without
   a backend.

Screens that depend directly on Firebase (auth, Firestore streams) are out of
scope for unit testing and would be covered by instrumented integration tests
using `mockito` doubles — noted as future work.

## 4. Test cases

### 4.1 `test/task_model_test.dart` — core logic

| # | Test case | What it verifies | Expected |
| --- | --- | --- | --- |
| 1 | SubTask `copyWith` toggles `isDone` | Immutability; only target field changes | original unchanged, copy toggled |
| 2 | SubTask `toMap`/`fromMap` round-trip | Serialisation preserves fields | all fields equal |
| 3 | SubTask `fromMap` defaults | Robustness to missing keys | safe empty defaults |
| 4 | `isOverdue` for past, incomplete task | Overdue detection | `true` |
| 5 | Completed task is never overdue | Completed tasks excluded | `false` |
| 6 | `isDueToday` for task due later today | Same-day detection | `true` |
| 7 | `isDueSoon` within 24h vs beyond | Soon-window logic | `true` / `false` |
| 8 | `smartScore` for overdue + high + 100% weight | Algorithm max case | ≈ 88.0 |
| 9 | Sooner deadline outranks later | Urgency weighting | sooner > later |
| 10 | Higher priority outranks lower | Priority weighting | high > low |
| 11 | Higher grade weight raises score | Weight weighting | heavy > light |
| 12 | `subtaskProgress` with no sub-tasks | Falls back to stored progress | stored value |
| 13 | `subtaskProgress` partial completion | Fraction computed | 0.5 |
| 14 | `subtaskProgress` all done | Full completion | 1.0 |
| 15 | `TaskModel.copyWith` selective override | Immutability of model | targets changed, rest kept |
| 16 | `toMap` enum/date encoding | Enums as index, dates as Timestamp | correct types |
| 17 | `TaskModel.fromMap` round-trip | Full reconstruction incl. sub-tasks | equivalent task |
| 18 | `fromMap` enum defaults | Missing enum keys | medium / assignment |
| 19 | `TaskPriority` labels | Display extension correctness | High/Medium/Low |
| 20 | `TaskCategory` labels | Display extension correctness | all six labels |

### 4.2 `test/user_model_test.dart` — user model

| # | Test case | What it verifies | Expected |
| --- | --- | --- | --- |
| 21 | `UserModel.copyWith` selective override | Immutability | targets changed, rest kept |
| 22 | `toMap`/`fromMap` round-trip | Full field preservation incl. location | equivalent user |
| 23 | `createdAt` stored as Timestamp | Date encoding | `Timestamp` |
| 24 | `fromMap` defaults for empty doc | Robustness | safe defaults, null lat/lng |

### 4.3 `test/widget_test.dart` — UI flow

| # | Test case | What it verifies | Expected |
| --- | --- | --- | --- |
| 25 | Onboarding renders first slide + controls | Screen builds, key widgets present | slide title, Skip, Next |
| 26 | Tapping "Next" advances slide | Navigation/state update | second slide title shown |

## 5. How to run

```bash
flutter pub get
flutter test                 # run all tests
flutter test --coverage      # with coverage (writes coverage/lcov.info)
```

## 6. Expected result

All 26 test cases pass. A passing run prints a summary similar to:

```
00:0x +26: All tests passed!
```

## 7. Conclusion

The suite provides automated regression coverage of the application's most
important logic — the smart-prioritisation algorithm, deadline handling,
progress tracking and data persistence mapping — plus a UI smoke test of the
onboarding flow. This satisfies the framework-utilisation requirement and gives
the team confidence to refactor without breaking core behaviour. The clear next
step is adding `mockito`-based integration tests for the Firebase-backed
auth and task-stream paths.
