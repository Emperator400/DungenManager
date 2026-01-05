# API Refactoring Plan - Unified Database API

## 🎯 Zielsetzung

**Single Source of Truth**: Alle Entity-Klassen entfernen und nur Modelle mit einheitlicher Serialisierung verwenden.

## 🚨 Identifizierte Probleme

### 1. Doppelte Implementierung
- **Modelle**: `toMap()`, `fromMap()` mit `ModelParsingHelper`
- **Entities**: `toDatabaseMap()`, `fromDatabaseMap()`, eigene Konvertierungslogik
- **Ergebnis**: 4 Konvertierungsmethoden pro Modell statt 2

### 2. Feldnamen-Inkonsistenzen

| Model-Feld | Entity-Feld | Datenbank-Feld (alt) | Neu |
|-------------|--------------|---------------------|-----|
| `maxHp` | `maxHitPoints` | `max_hit_points` | `max_hp` |
| `armorClass` | `armorClass` | `armor_class` | `armor_class` |
| `className` | `characterClass` | `character_class` | `class_name` |
| `raceName` | `race` | `race` | `race_name` |
| `playerName` | `background` | `background` | `player_name` |

### 3. Redundante Validierung
- Modelle haben eigene Validierungslogik
- Entities haben eigene Validierungslogik
- Beide prüfen unterschiedliche Dinge

### 4. Performance-Probleme
- Mehrfache Konvertierungsschritte
- Komplexe String-Manipulation (Snake/CamelCase)
- JSON-Serialisierung in characterData

## 💡 Lösungsansatz

### Neue Architektur

```
┌─────────────────────────────────────────┐
│          UI Layer (ViewModels)       │
│    Verwenden nur Modelle!          │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│       Repository Layer                │
│    Spezialisierte Repositories       │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│       Model Layer                    │
│  toDatabaseMap() / fromDatabaseMap() │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│       Database (SQLite)              │
│    Konsistente Feldnamen             │
└─────────────────────────────────────────┘
```

### Vorteile

1. **Drastische Komplexitätsreduktion**
   - Von 4 auf 2 Konvertierungsmethoden pro Modell
   - Keine doppelte Validierung mehr
   - Single Source of Truth

2. **Performance-Verbesserungen**
   - Weniger Objekt-Instanziierungen
   - Direktes JSON-Mapping statt String-Manipulation
   - Reduzierte Memory-Allokation

3. **Bessere Wartbarkeit**
   - Klar Verantwortlichkeiten
   - Einfachere Tests
   - Weniger Code-Duplikation

4. **Type Safety**
   - Compile-Time Checks
   - Weniger Runtime-Fehler
   - Bessere IDE-Unterstützung

## 📋 Implementierungsphasen

### Phase 1: Vorbereitung und Analyse (1-2 Tage)
- [x] Datenbank-API-Dokumentation analysiert
- [x] Modelle und Entities verglichen
- [x] Hauptprobleme identifiziert
- [x] Lösungsansatz dokumentiert
- [ ] Abhängigkeiten kartieren
- [ ] Datenbank-Schema finalisieren

### Phase 2: Modelle erweitern (2-3 Tage)
- [ ] `toDatabaseMap()` implementieren für alle Modelle
- [ ] `fromDatabaseMap()` implementieren für alle Modelle
- [ ] Hilfsmethoden für komplexe Daten erstellen

### Phase 3: Repositories vereinfachen (2-3 Tage)
- [ ] Neue `BaseRepository`-Implementierung
- [ ] Spezifische Repositories anpassen
- [ ] Entity-Referenzen entfernen

### Phase 4: ViewModels migrieren (3-4 Tage)
- [ ] CharacterEditorViewModel migrieren
- [ ] ItemLibraryViewModel migrieren
- [ ] CampaignViewModel migrieren
- [ ] Weitere ViewModels migrieren

### Phase 5: Database-Migration (1-2 Tage)
- [ ] Migration für neue Feldnamen erstellen
- [ ] Tests durchführen
- [ ] Rollback-Optionen bereitstellen

### Phase 6: Aufräumarbeiten (1 Tag)
- [ ] Entity-Klassen entfernen
- [ ] Alte Dependencies entfernen
- [ ] Tests aktualisieren

## 🧪 Test-Strategie

### 1. Parallele Entwicklung
- Altes System weiterhin nutzen
- Neues System parallel entwickeln
- Feature-Flag für Umschaltung

### 2. Integration-Tests
```dart
test('Legacy vs New consistency', () async {
  final character = PlayerCharacter.create(/* ... */);
  
  // Alte Methode
  final legacyMap = character.toMap();
  
  // Neue Methode
  final newMap = character.toDatabaseMap();
  
  // Wichtige Felder vergleichen
  expect(newMap['name'], equals(legacyMap['name']));
  expect(newMap['class_name'], equals(legacyMap['className']));
});
```

### 3. Schrittweise Migration
- Erst ein Modell migrieren
- Tests durchführen
- Nächstes Modell migrieren

## 📅 Zeitplan

| Phase | Dauer | Status |
|--------|--------|--------|
| 1 | 1-2 Tage | 🔄 In Bearbeitung |
| 2 | 2-3 Tage | ⏸️ Ausstehend |
| 3 | 2-3 Tage | ⏸️ Ausstehend |
| 4 | 3-4 Tage | ⏸️ Ausstehend |
| 5 | 1-2 Tage | ⏸️ Ausstehend |
| 6 | 1 Tag | ⏸️ Ausstehend |
| **Gesamt** | **10-15 Tage** | **🔄 In Bearbeitung** |

## 🔍 Konsistente Feldnamen

### Player Character
```sql
CREATE TABLE player_characters (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL,
  name TEXT NOT NULL,
  player_name TEXT NOT NULL,
  class_name TEXT NOT NULL,
  race_name TEXT NOT NULL,
  level INTEGER NOT NULL,
  max_hp INTEGER NOT NULL,
  armor_class INTEGER NOT NULL,
  initiative_bonus INTEGER NOT NULL,
  image_path TEXT,
  strength INTEGER NOT NULL,
  dexterity INTEGER NOT NULL,
  constitution INTEGER NOT NULL,
  intelligence INTEGER NOT NULL,
  wisdom INTEGER NOT NULL,
  charisma INTEGER NOT NULL,
  proficient_skills TEXT,
  size TEXT,
  type TEXT,
  subtype TEXT,
  alignment TEXT,
  description TEXT,
  special_abilities TEXT,
  attacks TEXT,
  attack_list TEXT,
  inventory TEXT,
  gold REAL DEFAULT 0.0,
  silver REAL DEFAULT 0.0,
  copper REAL DEFAULT 0.0,
  source_type TEXT DEFAULT 'custom',
  source_id TEXT,
  is_favorite INTEGER DEFAULT 0,
  version TEXT DEFAULT '1.0',
  proficiency_bonus INTEGER DEFAULT 2,
  speed INTEGER DEFAULT 30,
  passive_perception INTEGER DEFAULT 10,
  spell_slots TEXT,
  spell_save_dc INTEGER DEFAULT 8,
  spell_attack_bonus INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Item
```sql
CREATE TABLE items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  item_type TEXT NOT NULL,
  weight REAL NOT NULL,
  cost REAL NOT NULL,
  image_url TEXT,
  damage TEXT,
  properties TEXT,
  ac_formula TEXT,
  strength_requirement INTEGER,
  stealth_disadvantage INTEGER DEFAULT 0,
  rarity TEXT,
  requires_attunement INTEGER DEFAULT 0,
  has_durability INTEGER DEFAULT 0,
  max_durability INTEGER,
  is_repairable INTEGER DEFAULT 0,
  spell_id TEXT,
  is_spell INTEGER DEFAULT 0,
  spell_level INTEGER,
  spell_school TEXT,
  is_cantrip INTEGER DEFAULT 0,
  max_casts_per_day INTEGER,
  requires_concentration INTEGER DEFAULT 0,
  source_type TEXT DEFAULT 'custom',
  source_id TEXT,
  is_favorite INTEGER DEFAULT 0,
  version TEXT DEFAULT '1.0',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

## 📝 Beispiel: Neue Serialisierung

### PlayerCharacter.toDatabaseMap()
```dart
Map<String, dynamic> toDatabaseMap() {
  return {
    'id': id,
    'campaign_id': campaignId,
    'name': name,
    'player_name': playerName,
    'class_name': className,
    'race_name': raceName,
    'level': level,
    'max_hp': maxHp,
    'armor_class': armorClass,
    'initiative_bonus': initiativeBonus,
    'image_path': imagePath,
    'strength': strength,
    'dexterity': dexterity,
    'constitution': constitution,
    'intelligence': intelligence,
    'wisdom': wisdom,
    'charisma': charisma,
    'proficient_skills': _serializeList(proficientSkills),
    'attack_list': _serializeAttackList(attackList),
    'inventory': _serializeInventory(inventory),
    'gold': gold,
    'silver': silver,
    'copper': copper,
    'source_type': sourceType,
    'source_id': sourceId,
    'is_favorite': isFavorite ? 1 : 0,
    'version': version,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
```

## 🔄 Next Steps

1. **Phase 1 abschließen**: Abhängigkeiten kartieren
2. **Phase 2 starten**: Erste Modell-Implementierung (PlayerCharacter)
3. **Tests schreiben**: Sicherstellen dass alles funktioniert
4. **Schrittweise Migration**: Ein ViewModel nach dem anderen

---

*Erstellt am: 24.12.2025*
*Status: In Bearbeitung*
