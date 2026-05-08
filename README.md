<div align="center">

# 📚 StudyMate — Study Tracker

**A beautifully crafted Flutter app that transforms the chaos of student life into a calm, data-driven study practice.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Backend-FFCA28?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

</div>

---

## ✨ What is StudyMate?

StudyMate is a **cross-platform mobile study tracker** built with Flutter and Firebase. It gives students a personal command center to plan study sessions, log productivity, track streaks, visualize analytics, and manage academic goals — all in real-time, synced to the cloud.

Whether you're prepping for finals or building a daily study habit, StudyMate keeps you honest, motivated, and on track.

---

## 🎬 Screenshots

> _Add your screenshots here by placing images in an `/Assets/screenshots/` folder and updating paths below._

| Login | Dashboard | Study Session | Analytics | Profile |
|-------|-----------|---------------|-----------|---------|
| ![Login](Assets/screenshots/login.png) | ![Dashboard](Assets/screenshots/dashboard.png) | ![Session](Assets/screenshots/session.png) | ![Analytics](Assets/screenshots/analytics.png) | ![Profile](Assets/screenshots/profile.png) |

---

## 🚀 Feature List

### 🔐 Authentication
- **Email & Password Sign Up / Login** via Firebase Auth
- Secure session persistence — users stay logged in across app restarts
- Animated red-border error feedback on login failure
- Client-side validation with descriptive, Firebase-mapped error messages

### 🏠 Dashboard (Home)
- **Personalized greeting** with the user's name pulled live from Firestore
- **🔥 Streak Counter** — tracks consecutive days of study with an auto-resetting weekly bubble view (Mon–Sun)
- **Upcoming Goals** — real-time list of active goals sorted by nearest deadline, with dynamic urgency colours (green → orange → red → overdue)
- **Today's Overview** stats: Total Study Time, Total Sessions, Average Productivity score
- One-tap goal completion with live UI update (no reload required)

### ⏱️ Study Session
A **3-stage session workflow**: Setup → Running → Rating

- **Subject selection** from a real-time Firebase-powered dropdown
- **Add new subjects** inline with a difficulty (1–5) and importance (1–5) rating dialog
- **Adjustable duration slider** (5–120 minutes)
- **Live countdown timer** that auto-ends when time is up
- **Productivity self-rating** (1–10 slider) at session end
- **Actual elapsed time** is recorded (not just planned duration) for honest analytics

### 📊 Analytics
- **Summary cards**: Total Study Time & Average Productivity at a glance
- **Weekly Activity Bar Chart** — powered by `fl_chart`, shows active study days
- **Subject Pie Chart** — visualises time distribution across all subjects based on completed sessions

### 🎯 Goals
- Create goals with a **title, description, and deadline** (date picker)
- Goals are auto-sorted by deadline proximity
- **Urgency colour coding**: green (> 3 days), orange (≤ 3 days), red (overdue)
- Mark complete with a single tap — goal disappears from the list immediately

### 👤 Profile
- Avatar with first-letter initial
- Account details: name, email, age
- Live stats row: Streak, Total Sessions, Total Study Time
- **One-tap logout** via Firebase Auth sign-out

### ☁️ Offline Support
- Firestore offline persistence is enabled with **unlimited cache size** — the app works without an internet connection and syncs when back online

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **State Management** | Provider (`ChangeNotifier`) |
| **Authentication** | Firebase Auth |
| **Database** | Cloud Firestore (real-time streams + offline cache) |
| **Charts** | `fl_chart` |
| **App Icon** | `flutter_launcher_icons` |
| **Splash Screen** | `flutter_native_splash` |

---

## ⚙️ Setup Instructions

### Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.x |
| Dart SDK | 3.11.3+ |
| Android Studio / Xcode | Latest stable |
| Firebase CLI | Latest |
| A Firebase Project | (free Spark plan works) |

---

### Step 1 — Clone the Repository

```bash
git clone https://github.com/sarthak-sahni183/StudyMate-StudyPortal.git
cd StudyMate-StudyPortal
git checkout mohit
```

### Step 2 — Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3 — Set Up Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Enable **Authentication** → Sign-in method → **Email/Password**.
3. Enable **Cloud Firestore** in test mode.
4. Install the Firebase CLI and FlutterFire CLI:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

5. Log in and configure:

```bash
firebase login
flutterfire configure
```

This auto-generates `lib/firebase_options.dart`. **Do not commit this file to a public repo** (it contains API keys).

### Step 4 — Run the App

```bash
# Android
flutter run

# iOS (requires macOS + Xcode)
flutter run -d ios

# Release build for Android
flutter build apk --release
```

---

### Firestore Data Structure

The app uses the following Firestore schema (auto-created on first sign-up):

```
users (collection)
  └── {uid} (document)
        ├── name, email, age
        ├── streak, totalStudyTime, totalSessions, avgProductivity
        ├── weekActivity: [bool x7], lastSessionDate
        │
        ├── goals (subcollection)
        │     └── {goalId}: title, description, deadline, isCompleted
        │
        ├── subjects (subcollection)
        │     └── {subjectId}: name, difficulty, importance
        │
        └── sessions (subcollection)
              └── {sessionId}: subjectName, plannedDuration, actualDuration,
                              startTime, endTime, productivity, isCompleted
```

---

## 📦 Project Structure

```
lib/
├── main.dart                  # App entry, Firebase init, Provider setup
├── firebase_options.dart      # Auto-generated Firebase config
│
├── models/
│   ├── user.dart              # UserModel with Firestore serialisation
│   ├── study_session.dart     # StudySession model
│   ├── subject.dart           # Subject model
│   └── goal.dart              # GoalModel
│
├── providers/
│   ├── auth_provider.dart     # Login/Signup state + loading flag
│   ├── database_provider.dart # All Firestore reads/writes + stream sources
│   └── session_provider.dart  # Legacy session provider (retained for reference)
│
├── services/
│   ├── auth_service.dart      # Raw Firebase Auth calls
│   └── firestore_service.dart # Legacy Firestore helper (retained for reference)
│
└── screens/
    ├── auth_wrapper.dart      # Listens to auth state, routes to Login or MainLayout
    ├── main_layout.dart       # Bottom nav shell with IndexedStack
    ├── dashboard_screen.dart  # Home tab
    ├── study_session_screen.dart # Session tab
    ├── analytics_screen.dart  # Analytics tab
    ├── profile_screen.dart    # Profile tab
    ├── add_goal_screen.dart   # Goal creation form
    └── auth/
        ├── login_screen.dart
        └── signup_screen.dart
```

---

## 🤝 Contributing

1. Fork the repo
2. Create your branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">
  Made with 💚 and Flutter · <a href="https://github.com/sarthak-sahni183/StudyMate-StudyPortal">GitHub Repo</a>
</div>
