# Plan: Companion Mode

Ermöglicht Spielern, während einer laufenden Session ihre Charakterwerte auf dem eigenen
Gerät zu sehen und die vom DM freigegebene Karte in Echtzeit zu verfolgen.
Setzt **Firebase Foundation** voraus.

---

## Kernfunktionen

| Funktion | DM | Spieler |
|----------|----|---------|
| Session-Raum erstellen / beitreten | ✅ erstellt | ✅ tritt bei (Code) |
| Charakterwerte sehen | ✅ alle | ✅ nur eigener |
| HP-Änderungen | ✅ setzt | ✅ sieht live |
| Kartenansicht | ✅ steuert Sichtbarkeit | ✅ sieht freigegebene Bereiche |
| Status-Effekte | ✅ setzt | ✅ sieht eigene |
| Initiative-Reihenfolge | ✅ verwaltet | ✅ sieht Liste |
| Chat / Notizen | ✅ tippt | ✅ sieht |

---

## Firestore-Datenstruktur

```
rooms/{roomId}
  ├── dmUid: string
  ├── campaignId: string          // lokal gespeicherte Campaign-ID des DM
  ├── sessionName: string
  ├── status: 'waiting' | 'active' | 'ended'
  ├── createdAt: timestamp
  ├── joinCode: string            // 6-stellig, z.B. "AX7K2P"
  │
  ├── characters/{characterId}
  │   ├── name: string
  │   ├── playerUid: string?      // null wenn noch nicht gejoint
  │   ├── currentHp: number
  │   ├── maxHp: number
  │   ├── armorClass: number
  │   ├── initiative: number?
  │   ├── conditions: string[]    // ['poisoned', 'stunned', ...]
  │   └── isVisible: bool         // DM kann Char ausblenden
  │
  ├── map
  │   ├── imageStoragePath: string   // Firebase Storage Pfad
  │   ├── fogOfWar: bool
  │   ├── revealedCells: number[]    // Array von Zell-Indizes (Grid)
  │   └── tokens: [{id, x, y, label, color}]
  │
  └── feed/{}                     // DM-Nachrichten, Würfelergebnisse
      ├── type: 'message' | 'roll' | 'event'
      ├── text: string
      └── timestamp: timestamp
```

---

## Neue Flutter-Pakete

```yaml
# Zu pubspec.yaml hinzufügen (nach Firebase Foundation)
firebase_storage: ^12.x     # bereits in Firebase Foundation
```

Keine weiteren Pakete nötig — `cloud_firestore` bietet Echtzeit-Streams nativ.

---

## Neue Dateien

### Backend / Services

| Datei | Inhalt |
|-------|--------|
| `lib/models/companion_room.dart` | Room-Model + CharacterSnapshot |
| `lib/models/companion_map_state.dart` | Map-Zustand (fog, tokens, revealedCells) |
| `lib/services/companion_service.dart` | Room erstellen/joinen, Firestore-Streams |
| `lib/services/companion_map_service.dart` | Karten-Upload (Storage), Fog-of-War |

### ViewModels

| Datei | Inhalt |
|-------|--------|
| `lib/viewmodels/companion_dm_viewmodel.dart` | DM-Seite: Chars pushen, Karte steuern |
| `lib/viewmodels/companion_player_viewmodel.dart` | Spieler-Seite: Stream empfangen |

### Screens

| Datei | Inhalt |
|-------|--------|
| `lib/screens/companion/companion_dm_screen.dart` | DM-Dashboard: QR-Code + Charakterliste |
| `lib/screens/companion/companion_player_screen.dart` | Spieler-Ansicht: Char + Karte |
| `lib/screens/companion/companion_join_screen.dart` | Code-Eingabe für Spieler |
| `lib/screens/companion/companion_map_editor_screen.dart` | Fog-of-War malen |

---

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/screens/session/active_session_screen.dart` | „Companion starten"-Button in AppBar |
| `lib/main.dart` | CompanionDmViewModel registrieren |

---

## Flow: DM startet Session

```
DM öffnet aktive Session
    ↓
[Companion starten] → CompanionDmScreen
    ↓
companion_service.createRoom(campaign, session)
    → erzeugt rooms/{roomId} in Firestore
    → generiert joinCode (6 Zeichen)
    ↓
DM sieht QR-Code + Join-Code
Charaktere aus aktiver Session werden als Snapshots gepusht
    ↓
DM kann HP ändern → updateCharacterHp() → Firestore-Update
DM kann Karte hochladen → Storage-Upload → map.imageStoragePath setzen
DM kann Fog-of-War aufdecken → map.revealedCells updaten
```

## Flow: Spieler tritt bei

```
Spieler öffnet App (ohne Login oder mit Google)
    ↓
CompanionJoinScreen: Join-Code eingeben
    ↓
companion_service.joinRoom(code) → sucht Room in Firestore
    ↓
Spieler wählt Charakter aus der Charakterliste des Rooms
    ↓
CompanionPlayerScreen: Stream auf characters/{characterId}
    → HP, Conditions, Initiative live
Stream auf map → Karte + aufgedeckte Bereiche live
```

---

## Karte & Fog of War

- DM lädt PNG/JPG über `companion_map_service.uploadMapImage()` → Firebase Storage
- Grid wird clientseitig berechnet (z.B. 20×20 Zellen)
- `revealedCells` = Array von Zell-Indizes (0–399 für 20×20)
- Spieler sieht nur Zellen in `revealedCells` (restliche Zellen = schwarzes Overlay)
- Tokens (PCs, NPCs) haben `{x, y}` in Grid-Koordinaten

---

## Sicherheitsregeln (Firestore)

```
rooms/{roomId}
  read: dmUid == request.auth.uid
     OR resource.data.status == 'active'   // Spieler dürfen lesen
  write: dmUid == request.auth.uid          // nur DM darf schreiben
  
  // Ausnahme: Spieler dürfen eigenen Charakter lesen
  characters/{characterId}
    read: resource.data.playerUid == request.auth.uid
       OR request.auth.uid == get(/rooms/$(roomId)).data.dmUid
```

---

## Verifikation

1. `flutter analyze` — null Warnungen
2. DM erstellt Room → Join-Code erscheint → QR-Code anzeigbar
3. Spieler gibt Code ein → sieht Charakterliste → wählt Charakter
4. DM ändert HP → Spieler-Gerät aktualisiert < 1 s
5. Karte hochladen → Spieler sieht Karte
6. Fog-of-War aufdecken → Spieler-Gerät zeigt neue Zellen
7. DM beendet Session → Room-Status = 'ended' → Spieler-Gerät zeigt Ende-Overlay
8. Kein Login benötigt für Spieler mit lokalem Konto (anonyme Firebase Auth)
