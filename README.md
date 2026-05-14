# DungenManager — D&D 5e Session-Management für Dungeon Master

> Eine Flutter-App für Windows, macOS und iOS, die Dungeon Mastern ein vollständiges digitales Werkzeugset an die Hand gibt — von der Kampagnenplanung bis zum Live-Spielbetrieb am Tisch.

![Version](https://img.shields.io/badge/version-1.0.9-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20iOS-lightgrey)
![Status](https://img.shields.io/badge/status-aktiv%20entwickelt-green)
![License](https://img.shields.io/badge/license-proprietary-red)

---

## Screenshots

> *Screenshots folgen — Bilder können unter `docs/screenshots/` abgelegt werden.*

| DM-Buch & Karte | Heldenverwaltung | Live-Session |
|:---:|:---:|:---:|
| *(coming soon)* | *(coming soon)* | *(coming soon)* |

---

## Features

### 📖 DM-Buch (Kampagnen-Zentrale)
- Mehrere Kampagnen verwalten, jede mit eigenem DM-Buch
- **Interaktive Karte** mit platzierbaren Markern (Dungeon, Stadt, Gebäude, Wildnis, Region …)
- Marker verbinden, auf Subkarten bohren, Positionen sperren
- **Verlaufsplan** — visueller Plot-Graph mit Marker- und Quest-Referenzen
- **LoreKeeper** — Wiki für NPCs, Orte und Weltenbau-Artikel, aus dem Marker direkt erstellt werden können
- **Kampagnen-Templates** — Kampagnen als Vorlagen speichern und mit einem Klick synchronisieren

### 🧙 Spieler & Helden
- **Spieler-Profile** mit eigener Farbe und Hero-Roster
- Helden einer Kampagne ausleihen oder direkt dort erstellen
- Helden-Übersicht mit farbigen Spieler-Badges, Gruppierung nach Spieler
- Rechtsklick auf einen Helden → aus Kampagne abziehen

### 📋 Detaillierter Charakterbogen
- Alle D&D-5e-Werte: Attribute, HP, RK, Initiative, Speed, Proficiencies
- **Automatische Rüstungsklassen-Berechnung** (je nach ausgerüsteter Rüstung)
- **Inventar-System** mit ausrüstbaren Gegenständen aus zentraler Bibliothek
- Charakter-Porträt, Gold/Silber/Kupfer, Beschreibung, Ausrichtung

### ⚔️ Session & Encounter (Live am Tisch)
- **Aktive-Session-Dashboard** mit Szenen-Log, Quest-Status und Zeittracker
- **Encounter-Tracker** mit Initiativ-Reihenfolge, Rundzähler und Runden-Highlighting
- HP-Änderungen, Schaden und Heilung direkt im Tracker
- Zustands-Verwaltung (Conditions: Vergiftet, Betäubt, …)
- „Spickzettel"-Karten für Helden und Monster im Kampf

### 🌍 Weltenbau & Bibliotheken
- **Bestiarium** — Monster- und NPC-Bibliothek
- **Ausrüstungskammer** — wiederverwendbare Items
- **Quest-Bibliothek** — Quest-Ideen und -Vorlagen
- **Szenen-Planer** — sortierbare Szenen-Karteikarten mit Markdown-Notizen und NSC-Dialog-Hervorhebung

### 🔊 Atmosphäre
- Audio-Import (MP3/WAV) und Wiedergabe
- Klanglandschaften pro Szene zusammenstellen

---

## Tech Stack

| Bereich | Technologie |
|---------|-------------|
| Framework | Flutter (Dart) |
| State Management | Provider / ChangeNotifier (MVVM) |
| Datenbank | SQLite via `sqflite` + `sqflite_common_ffi` |
| Audio | `audioplayers` |
| Datei-Import | `file_picker`, `image_picker` |
| Markdown | `flutter_markdown` |
| IDs | `uuid` |

---

## Setup & Installation

### Voraussetzungen

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.x
- Dart ≥ 3.x
- Für Windows: Visual Studio mit C++-Desktop-Workload
- Für macOS/iOS: Xcode

### Schritte

```bash
# 1. Repository klonen
git clone https://github.com/Emperator400/DungenManager.git
cd DungenManager

# 2. Abhängigkeiten laden
flutter pub get

# 3. App starten
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d ios       # iOS Simulator
```

### Datenbankprobleme beheben

Falls beim Start ein `SqfliteFfiException`-Fehler auftritt (z. B. nach einem Schema-Update):

**Windows:** Die Datenbankdatei befindet sich unter:
```
%APPDATA%\com.example.dungenManager\dungen_manager.db
```
Diese Datei löschen — die App legt beim nächsten Start eine neue an.

**iOS/Android:** App deinstallieren und neu installieren.

---

## Projektstruktur

```
lib/
├── models/          # Dart-Domain-Modelle (Ort, PlayerCharacter, Session …)
├── database/        # SQLite-Repositories und Migrationen
├── services/        # Business-Logic
├── viewmodels/      # ChangeNotifier-ViewModels
├── screens/         # Feature-Screens
├── widgets/         # Wiederverwendbare UI-Komponenten
├── theme/           # AppColors, DnDTheme
└── game_data/       # D&D-5e-SRD-Daten und Demo-Content
```

---

## Lizenz

© 2024–2026 Emperator400. Alle Rechte vorbehalten.

Dieser Quellcode ist öffentlich einsehbar, aber **nicht zur Nutzung, Kopie, Modifikation oder Weiterverbreitung freigegeben** ohne ausdrückliche schriftliche Genehmigung des Autors.
