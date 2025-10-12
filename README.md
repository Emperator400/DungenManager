# DM-Cockpit: Dein All-in-One D&D Management Tool

Eine mit Flutter entwickelte Desktop- und Tablet-Anwendung, die Dungeon Mastern dabei hilft, ihre Dungeons & Dragons Kampagnen zu planen, zu verwalten und live am Spieltisch zu leiten.

![Status](https://img.shields.io/badge/status-in_development-orange)

---

### 📖 Projekt-Vision

Das Ziel dieses Projekts ist es, die Zettelwirtschaft und das Springen zwischen unzähligen Apps während einer D&D-Sitzung zu beenden. Das DM-Cockpit soll eine zentrale, intuitive Anwendung sein, die alle wichtigen Werkzeuge eines Spielleiters vereint – von der grossen Kampagnen-Architektur bis hin zum detaillierten Kampf-Management in Echtzeit.

Die App ist modular aufgebaut und wurde mit Fokus auf eine saubere, erweiterbare Architektur entwickelt.

**(Tipp: Füge hier ein oder zwei Screenshots deiner App ein, z.B. vom Kampagnen-Dashboard und dem Kampf-Tracker!)**
`[SCREENSHOT VOM KAMPAGNEN-DASHBOARD HIER EINFÜGEN]`

### ✨ Features

Die Anwendung ist in mehrere, miteinander verknüpfte Module unterteilt:

**🏛️ Kampagnen-Architektur ("Das Bücherregal")**
* **Kampagnen-Verwaltung:** Erstelle mehrere Kampagnen ("Bücher"), um verschiedene Abenteuer sauber voneinander zu trennen.
* **Kampagnen-Dashboard:** Eine zentrale Übersicht für jede Kampagne mit Zugriff auf alle zugehörigen Module.

**👤 Charakter-Management**
* **Detaillierter Charakterbogen:** Erstelle und verwalte Spielercharaktere mit allen wichtigen Werten (Attribute, HP, AC, Level etc.).
* **Intelligente Regel-Logik:** Wähle Klassen und Rassen aus vordefinierten Listen. Boni für Attribute und Fähigkeiten werden automatisch berechnet.
* **Inventar-System:** Rüste Helden mit Gegenständen aus einer zentralen Bibliothek aus und verwalte deren Menge.
* **Charakter-Porträts:** Lade Bilder für jeden Helden hoch.

**🗺️ Story & Weltenbau**
* **Szenen-Planer:** Plane deine Sitzungen nicht als Textwand, sondern als sortierbare Liste von "Szenen-Karteikarten" – ein flexibles Flussdiagramm für deine Story.
* **Intelligente Verknüpfungen:** Verknüpfe NPCs, Orte und Quests direkt mit den Szenen, in denen sie vorkommen.
* **Dialog-Hervorhebung:** Nutze Markdown-Syntax (`>`), um NSC-Dialoge in deinen Notizen hervorzuheben, die im Live-Modus speziell formatiert werden.
* **Globale Bibliotheken:**
    * **Lore Keeper:** Eine zentrale Wiki für alle deine NPCs, Orte und Hintergrundgeschichten.
    * **Bestiarium:** Eine Bibliothek für alle Monster und ihre Kampfwerte.
    * **Ausrüstungskammer:** Eine Bibliothek für alle wiederverwendbaren Gegenstände (Waffen, Rüstungen etc.).
    * **Quest-Bibliothek:** Eine Sammlung von Quest-Ideen und -Schablonen.

**⚔️ Live-Spiel-Cockpit**
* **`ActiveSessionScreen`:** Ein 4-Quadranten-Dashboard für den Live-Spielbetrieb, das dir auf einen Blick den Szenen-Ablauf, das Quest-Log, den Zeit-Tracker und das Soundboard anzeigt.
* **Interaktiver Initiative-Tracker:**
    * **Turn-Management:** Zählt die Runden und hebt den aktiven Kämpfer visuell hervor.
    * **"Spickzettel":** Aufklappbare Karten zeigen per Klick alle relevanten Werte eines Helden (Attribute, Boni) oder Monsters (AC, Angriffe).
    * **Zustands-Verwaltung:** Füge per Klick Conditions (z.B. "Vergiftet") hinzu und entferne sie.
    * **Schnell-Aktionen:** Ein Kontextmenü (langer Klick/Rechtsklick) auf jeden Teilnehmer ermöglicht die blitzschnelle Eingabe von Schaden und Heilung.

**🔊 Atmosphäre**
* **Sound-System:** Importiere eigene Audio-Dateien (Musik & Effekte), komponiere sie zu Klanglandschaften ("Szenen") und spiele sie im Live-Cockpit per Knopfdruck ab.

### 🛠️ Tech Stack

* **Framework:** Flutter
* **Sprache:** Dart
* **Datenbank:** `sqflite` (lokale SQL-Datenbank)
* **Wichtige Pakete:**
    * `file_picker` & `image_picker` (für den Import von Dateien)
    * `audioplayers` (für das Sound-System)
    * `flutter_markdown` (für die Formatierung von Notizen)
    * `path` & `path_provider` (für das Dateimanagement)

### 🚀 Getting Started

Dieses Projekt wurde mit Flutter entwickelt.

1.  **Flutter installieren:** Stelle sicher, dass du eine aktuelle Version des [Flutter SDK](https://flutter.dev/docs/get-started/install) installiert hast.
2.  **Abhängigkeiten laden:** Navigiere ins Projektverzeichnis und führe `flutter pub get` aus.
3.  **App starten:** Führe `flutter run -d windows` (oder `macos`/`linux`) aus, um die App auf dem Desktop zu starten.

**Hinweis:** Da sich die Datenbank-Struktur in der Entwicklung befindet, ist der einfachste Weg bei `SqfliteFfiException`-Fehlern, die App komplett zu deinstallieren (bei mobilen Builds) oder die `.db`-Datei im Build-Verzeichnis zu löschen, um eine Neuerstellung der Datenbank zu erzwingen.

### 🛣️ Zukünftige Ideen (Roadmap)

* [ ] **Karten-Manager:** Eine interaktive Kartenansicht mit Zoom, Pan und "Fog of War".
* [ ] **Spieler-Bildschirm:** Eine separate Ausgabe-Ansicht nur für Spieler (z.B. für einen zweiten Monitor).
* [ ] **Token-Management:** Platzieren und Bewegen von Tokens auf den Karten.
* [ ] **Zufalls-Generatoren:** Für Namen, Orte, Quests und Schätze.

---

Erstellt mit viel Geduld und Freude am Entwerfen.
