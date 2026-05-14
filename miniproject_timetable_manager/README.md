# SchedIQ (Smart Timetable Manager)

A comprehensive academic scheduling and attendance tracking application built with Flutter. This repository contains the complete evolution of the project, featuring both the original prototype (Version 1) and the production-ready architecture (Version 2).

---

## 📱 Project Versions Overview

This project was developed in two distinct phases to demonstrate progressive feature enhancement and architectural improvements. Both versions can be compiled and installed independently on the same device.

### 🌟 Version 1: Timetable Manager (The Prototype)
**Package ID:** `com.example.miniproject_timetable_manager_v1`

Version 1 served as the foundational prototype, focusing on core functionality and basic state management.

**Key Features:**
*   **Basic Timetable Layout:** Hardcoded Monday–Saturday weekly schedule tabs.
*   **Class Management:** Ability to add basic class entries (Subject, Location, Faculty) and delete them via an explicit trash icon.
*   **Time Tracking:** A visual indicator showing which classes are currently "Ongoing" based on the system clock.
*   **State Management:** Utilized a single `TimetableProvider` connected to a basic SQLite implementation (`DatabaseHelper`).
*   **Design:** Utilized default Material 3 styling with generic theming.

**To Build Version 1:**
Use the provided PowerShell script which safely isolates the package ID and strips V2 branding to prevent overwriting:
```powershell
.\build_v1_separate.ps1
```

---

### 🚀 Version 2: SchedIQ (Production-Ready Architecture)
**Package ID:** `com.example.miniproject_timetable_manager`

Version 2 represents the finalized, production-ready application. It introduces a modernized, dynamic UI, advanced data relationships, customizable user settings, and robust academic features.

**Key Features & Upgrades:**
*   **Complete Rebranding:** Newly generated application launcher icons and rebranded across the UI as "SchedIQ".
*   **Dynamic Working Days:** Users can customize their active working days. The main timetable tabs and class addition dropdowns dynamically regenerate to match user preferences.
*   **Smart Overlap Validation:** The class scheduling engine analyzes existing entries and explicitly blocks users from booking overlapping classes.
*   **Attendance Tracking Engine:** Users can mark themselves present/absent for completed classes. Includes customizable Danger/Warning threshold alerts.
*   **45-Day Lifecycle Management:** Background lifecycle checking that prompts the user to wipe the database and start fresh after 45 days (for new semesters/cycles).
*   **PDF Export & Sharing Engine:** Generates a structured 9-slot academic grid PDF mirroring standard university formats, complete with dual-export features (Save locally or Share via native OS sheets).
*   **Dark Mode & Theming:** A dynamic theme engine allowing users to toggle between Light and Dark mode on the fly.
*   **Data Integrity:** Upgraded SQLite schema (`DatabaseHelperV2`) with relational architecture, fallback RegEx time-parsing to prevent legacy data crashes, and an explicit "Clear All Data" wipe function.

**To Build Version 2:**
Run the standard Flutter build pipeline:
```bash
flutter build apk
```

---

## 🛠️ Technical Stack

*   **Framework:** Flutter (Dart)
*   **Local Database:** `sqflite` (Relational SQLite schema)
*   **State Management:** `provider` (Multi-provider architecture: AppProvider, SettingsProvider, AttendanceProvider)
*   **Document Generation:** `pdf` & `printing` plugins
*   **Persistent Config:** `shared_preferences`
*   **Notifications:** `flutter_local_notifications`

## 🧪 Testing
The repository contains automated unit tests to verify the integrity of critical data engines.
*   **Time Parsing Tests:** Validates strict formats, lenient `jm` formats, 24-hour edge cases, and corrupted string fallbacks.
*   Run tests via: `flutter test test/time_parsing_test.dart`
