# SPTM – Student Productivity and Task Management

**CT124-3-2 Mobile App Engineering | Group 27 | APU**

A cross-platform Flutter mobile application for university student productivity, built on Firebase.

## Group Members
| Name | Student ID | Role |
|------|-----------|------|
| Nang Thet Htar San | TP084170 | Lead Flutter Developer / Firebase Architect |
| Nour Mohamed Mahmoud | TP081664 | UI/UX Developer / Testing & Documentation Lead |

## Features
- 🎯 **Smart task prioritisation** — weighted score (urgency 50% + priority 30% + grade weight 20%)
- 🔔 **Multi-layer notifications** — 24h / 2h / at-deadline push reminders
- 📋 **Subtask breakdown** — unlimited subtasks with swipe-to-delete and live progress tracking
- 📅 **Calendar view** — monthly calendar with task event markers
- ⏱️ **Pomodoro focus timer** — 25/5/15-min sessions with animated progress ring
- 📊 **Analytics profile** — completion rate bar, category pie chart, streak counter
- 🗺️ **Location pin** — OpenStreetMap with GPS + reverse geocoding (no API key required)
- 🔐 **Firebase Auth** — email/password registration, login, password reset

## Project Structure
```
lib/
├── main.dart
├── firebase_options.dart
├── models/        task_model.dart  user_model.dart
├── services/      auth_service.dart  task_service.dart  notification_service.dart
├── utils/         theme.dart
└── screens/       auth/ dashboard/ tasks/ calendar/ focus/ profile/ location/ onboarding/
test/
├── sptm_test.dart     # Flutter unit + widget tests (50 cases)
└── run_tests.py       # Python logic mirror (43 tests) — no Flutter required
```

## Running Tests
```bash
flutter test test/sptm_test.dart   # Flutter tests
python3 test/run_tests.py          # Python logic tests → 43/43 PASS
```

## Module
CT124-3-2 Mobile App Engineering | Asia Pacific University of Technology & Innovation
Lecturer: Mr. Amad Arshad | June 2026
