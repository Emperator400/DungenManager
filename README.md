# DungenManager

> A D&D 5e session management app for Dungeon Masters — built with Flutter for Windows, iOS and Android.

![Version](https://img.shields.io/badge/version-1.1.3-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20iOS%20%7C%20Android-lightgrey)
![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?logo=flutter)
![Status](https://img.shields.io/badge/status-active-brightgreen)
![License](https://img.shields.io/badge/license-proprietary-red)

---

## What is DungenManager?

DungenManager is a digital toolbox for Dungeon Masters running D&D 5e campaigns. It covers everything from long-term campaign planning to real-time encounter tracking at the table — all in one app, synced across devices via Firebase.

---

## Screenshots

| Campaign Hub | DM Book & Map | Active Session |
|:---:|:---:|:---:|
| *(coming soon)* | *(coming soon)* | *(coming soon)* |

| Hero Sheet | Encounter Tracker | Resource Library |
|:---:|:---:|:---:|
| *(coming soon)* | *(coming soon)* | *(coming soon)* |

---

## Features

### 📖 DM Book — Campaign Central
- Manage multiple campaigns, each with its own DM Book
- **Interactive world map** with placeable markers (dungeon, city, building, wilderness, region …)
- Drill down from world map into submaps
- **Story graph** — visual plot overview with marker and quest references
- **LoreKeeper** — wiki for NPCs, locations, and world-building articles

### 🔄 Cloud Sync
- Sign in anonymously or with an account — your data follows you
- Campaigns, maps, quests, and scenes sync to **Firebase Firestore**
- Images and maps upload to **Firebase Storage** with deduplication (unchanged files are never re-uploaded)
- **Resource Library** (`resources/` folder) — import images once, reference them in any campaign

### 🧙 Players & Heroes
- Player profiles with custom color and hero roster
- Assign heroes to a campaign or create them directly inside it
- Hero overview with colored player badges
- Full D&D 5e character sheet: attributes, HP, AC, initiative, speed, proficiencies
- **Automatic AC calculation** based on equipped armor
- **Inventory system** with equippable items from a central library

### 📋 Campaign Templates
- Save a campaign as a template and apply it to new campaigns with one click
- Templates stay separate from live campaigns

### ⚔️ Session & Encounter (Live at the Table)
- **Active session dashboard** with scene log, quest status, and time tracker
- **Encounter tracker** with initiative order, round counter, and round highlighting
- HP changes (damage / healing) directly in the tracker
- Condition management (Poisoned, Stunned, …)
- Cheat-sheet cards for heroes and monsters in combat

### 🌍 World-Building Libraries
- **Bestiary** — monster and NPC library
- **Equipment vault** — reusable item library
- **Quest library** — quest ideas and templates
- **Scene planner** — sortable scene cards with Markdown notes and NPC dialogue highlighting

### 🔊 Atmosphere
- Audio import (MP3 / WAV) and playback
- Build soundscapes per scene

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter / Dart |
| State Management | Provider / ChangeNotifier (MVVM) |
| Local Database | SQLite via `sqflite` + `sqflite_common_ffi` |
| Cloud Sync | Firebase Firestore + Firebase Storage |
| Authentication | Firebase Auth (anonymous + email) |
| Audio | `audioplayers` |
| Markdown | `flutter_markdown` |
| IDs | `uuid` |

---

## Architecture

```
UI (Screens + Widgets)
        ↓
ViewModels  (ChangeNotifier + Provider)
        ↓
Services    (Business Logic)
        ↓
Repositories (ModelRepository<T>)
        ↓
Database    (SQLite — local) + Firebase (cloud)
```

```
lib/
├── models/          # Pure Dart domain models
├── database/        # SQLite repositories & migrations
├── services/        # Business logic (40 service classes)
├── viewmodels/      # ChangeNotifier ViewModels (23)
├── screens/         # Feature screens (38)
├── widgets/         # Reusable UI components
├── theme/           # DnDTheme, DnDIcons
└── game_data/       # D&D 5e SRD data & demo content
```

---

## Setup

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.x
- Dart ≥ 3.x
- **Windows:** Visual Studio with C++ Desktop workload
- **iOS/Android:** Xcode / Android Studio

### Run locally

```bash
git clone https://github.com/Emperator400/DungenManager.git
cd DungenManager
flutter pub get

flutter run -d windows   # Windows
flutter run -d ios       # iOS Simulator
flutter run -d android   # Android
```

### Firebase

The app uses Firebase for cloud sync. `lib/firebase_options.dart` and `android/app/google-services.json` are included in the repository — these are client-side configuration files (not secrets) and are [safe to commit](https://firebase.google.com/docs/projects/api-keys) per Firebase's documentation. Security is enforced via Firebase Security Rules.

### Resetting the database

If you hit a `SqfliteFfiException` after a schema update, delete the local database file and restart:

**Windows:**
```
%APPDATA%\com.example.dungenManager\dungen_manager.db
```

**iOS / Android:** Uninstall and reinstall the app.

---

## Roadmap

### v1.2 — Stability & Polish
- [ ] Full test coverage for sync services
- [ ] Conflict resolution UI for simultaneous edits
- [ ] Android production build

### v2.0 — The Open Book *(in design)*
A two-pane layout inspired by an open book:
- **Left page** — persistent world view: map, quest list, audio mixer
- **Right page** — context-sensitive: scene preparation or live session

Locations replace sessions as the core unit — a location remembers everything that happened there.

---

## License

© 2024–2026 Emperator400. All rights reserved.

This source code is publicly visible but **not licensed for use, copying, modification, or redistribution** without explicit written permission from the author.

---

---

## Deutsche Kurzübersicht

DungenManager ist eine D&D-5e-Session-App für Dungeon Master — Flutter-App für Windows, iOS und Android.

**Kernfunktionen:**
- 🗺️ Interaktive Weltkarten mit platzierbaren Markern und Subkarten-Drill-Down
- 📖 LoreKeeper-Wiki für NPCs, Orte und Weltenbau
- 🔄 Cloud-Sync via Firebase (Kampagnen, Bilder, Karten) mit Deduplizierung
- 🖼️ Ressourcen-Bibliothek — Bilder einmal importieren, überall referenzieren
- ⚔️ Live-Session-Dashboard mit Encounter-Tracker und Initiative-Reihenfolge
- 🧙 Vollständiger D&D-5e-Charakterbogen mit automatischer RK-Berechnung
- 🔊 Atmosphären-Sound pro Szene

**Setup:** `flutter pub get && flutter run -d windows`

Weitere Details oben auf Englisch.
