# Unified Card System - Migrationsplan und Fortschritt

## Überblick

Dieses Dokument verfolgt den Fortschritt der UI-Modernisierung durch das Unified Card System und dokumentiert alle durchgeführten Schritte sowie noch ausstehende Aufgaben.

**Letztes Update:** 2026-01-04  
**Status:** Phase 1-4 - Grundlagen, Beispiele und erste Screens abgeschlossen

---

## Phase 1: Grundlagen und Beispiele ✅

### Abgeschlossene Aufgaben

#### 1.1 Ordnerstruktur erstellt
- [x] `lib/widgets/ui_components/base/` - Basiskomponenten
- [x] `lib/widgets/ui_components/shared/` - Gemeinsame Utilities
- [x] `lib/widgets/ui_components/cards/` - Spezifische Card-Implementierungen
- [x] `lib/widgets/ui_components/README.md` - Dokumentation

#### 1.2 Basiskomponenten erstellt
- [x] **unified_card_base.dart**
  - Abstrakte Basisklasse für alle Cards
  - Standardisiertes Card-Layout
  - Konfigurierbare Elevation und Border-Radius
  - Tap-Handling und Selektionsstatus
  - Favorite-Toggle Unterstützung

- [x] **card_header_widget.dart**
  - Standardisierter Header
  - Icon/Avatar Support
  - Titel und Subtitle
  - Additional Info Chips
  - Favorite Button
  - Popup Menu

- [x] **card_content_widget.dart**
  - Flexibler Content-Container
  - Beschreibungstext
  - Tags Support
  - Zusätzlicher benutzerdefinierter Inhalt

- [x] **card_actions_widget.dart**
  - Action-Bar mit Edit-, Delete-Buttons
  - Quick Action Button
  - Konfigurierbare Ausrichtung

- [x] **card_metadata_widget.dart**
  - Erstellungs- und Aktualisierungsdatum
  - Status mit farbcodierter Anzeige
  - Priorität mit farbcodierter Anzeige
  - Item Counts
  - Custom Metadata

#### 1.3 Theme-System erstellt
- [x] **unified_card_theme.dart**
  - Konsistente Farben für alle Card-Typen
  - Unterstützte Typen: campaign, quest, hero, item, sound, wiki, session, creature, default
  - Status-Farben (Aktiv, Abgeschlossen, etc.)
  - Prioritäts-Farben (Hoch, Mittel, Niedrig)

#### 1.4 Beispiel-Implementierungen erstellt
- [x] **unified_campaign_card.dart**
  - Zeigt Campaign-Informationen
  - Shows Helden-, Sessions- und Quest-Counts
  - Quick Actions Bottom Sheet
  - Popup Menu mit Duplizieren, Exportieren, Archivieren, Einstellungen
  - Favorite-Toggle (aktiv/inaktiv)

- [x] **unified_quest_card.dart**
  - Zeigt Quest-Informationen
  - Belohnungsanzeige (Gold/EP)
  - Status und Schwierigkeit
  - Level-Empfehlung und Dauer-Schätzung
  - Location und NPCs
  - Wiki-Links

- [x] **unified_hero_card.dart**
  - Zeigt Helden-Informationen
  - Stats-Row (HP, AC, Init, Bewegung)
  - Attributes Preview (STR, DEX, CON, INT, WIS, CHA)
  - Währungsanzeige (Gold, Silber, Kupfer)
  - Klasse, Rasse, Level
  - Zauber-Slots Support

#### 1.5 Dokumentation erstellt
- [x] **README.md**
  - Architektur-Übersicht
  - Verwendung der Komponenten
  - Code-Beispiele
  - Best Practices
  - Migrations-Anleitung
  - Troubleshooting

---

## Phase 2: Weitere Cards erstellen 🔄

### Ausstehende Aufgaben

#### 2.1 Item Cards
- [ ] **unified_item_card.dart**
  - Zeigt Item-Informationen
  - Typ und Seltenheit
  - Gewicht und Wert
  - Stats und Boni
  - Ausrüstungs-Slots
  - Effekte

#### 2.2 Wiki Entry Cards
- [ ] **unified_wiki_entry_card.dart**
  - Zeigt Wiki-Eintrag
  - Kategorie und Tags
  - Cross-References
  - Markdown-Vorschau
  - Verlinkte Einträge

#### 2.3 Sound Cards
- [ ] **unified_sound_card.dart**
  - Zeigt Sound
  - Dauer und Größe
  - Kategorie
  - Loop-Option
  - Volume

#### 2.4 Session Cards
- [ ] **unified_session_card.dart**
  - Zeigt Session
  - Datum und Dauer
  - Teilnehmer
  - Scene-Verknüpfungen
  - Notizen

#### 2.5 Creature Cards
- [ ] **unified_creature_card.dart**
  - Zeigt Kreatur
  - Stats (HP, AC, etc.)
  - Typ und Größe
  - CR (Challenge Rating)
  - Traits und Aktionen
  - Loot

---

## Phase 3: Migration der alten Cards 📋

### Zu migrierende alte Cards

#### 3.1 Kampagnen
- [x] `lib/widgets/campaign/enhanced_campaign_card_widget.dart`
  - ✅ Ersetzt mit `UnifiedCampaignCard`
  - Wird nicht mehr verwendet

#### 3.2 Quests
- [x] `lib/widgets/quest_library/enhanced_quest_card_widget.dart`
  - ✅ Ersetzt mit `UnifiedQuestCard`
  - Wird nicht mehr verwendet

#### 3.3 Helden
- [ ] `lib/widgets/character_list/enhanced_hero_card_widget.dart`
  - Ersetzen mit `UnifiedHeroCard`

#### 3.4 Items
- [ ] `lib/widgets/character_editor/item_card_widget.dart`
  - Ersetzen mit `UnifiedItemCard` (nach Erstellung)

#### 3.5 Wiki Einträge
- [ ] `lib/widgets/lore_keeper/enhanced_wiki_entry_card_widget.dart`
  - Ersetzen mit `UnifiedWikiEntryCard` (nach Erstellung)

#### 3.6 Sounds
- [ ] Ggf. existierende Sound-Cards migrieren

#### 3.7 Creatures
- [ ] Ggf. existierende Creature-Cards migrieren

---

## Phase 4: Integration in Screens ✅🔄

### Screens, die migriert wurden

#### 4.1 Kampagnen-Screens
- [x] `lib/screens/campaign_selection_screen.dart`
  - ✅ Verwendet `UnifiedCampaignCard`
  - Alle Callbacks korrekt integriert
  - onToggleFavorite für aktiv/inaktiv Status
  - onDuplicate für Duplizieren
- [x] `lib/screens/enhanced_campaign_dashboard_screen.dart`
  - ✅ Verwendet `UnifiedCampaignCard`
  - DnD-Theme im AppBar mit Gradient-Background
  - Alle Callbacks korrekt integriert
  - Popup Menu für Aktionen (über UnifiedCampaignCard)
  - Grid-Ansicht für Kampagnen
- [x] `lib/screens/enhanced_edit_campaign_screen.dart`
  - ✅ Visuell überarbeitet (2026-01-04)
  - DnD-Theme Integration mit `getDungeonWallDecoration()`
  - Neue Kampagnen-Einstellungen:
    - Start-Level (1-20) mit interaktivem Slider
    - Max-Level (1-20) mit interaktivem Slider
    - Party-Größe als Text-Input
    - Benutzerdefinierte Inhalte zulassen (Toggle)
    - Öffentlich (Toggle)
  - Verbesserte Status-Dropdown mit Icons:
    - Planung: `edit_note`
    - Aktiv: `play_circle`
    - Pausiert: `pause_circle`
    - Abgeschlossen: `check_circle`
    - Abgebrochen: `cancel`
  - Verbesserte Typ-Dropdown mit Icons:
    - Homebrew: `home`
    - Module: `book`
    - Adventure Path: `map`
    - One-Shot: `flash_on`
  - Zusätzliche Informationen mit goldenen Icons:
    - Spieler-Anzahl mit Verwaltungs-Button
    - Quest-Anzahl mit Anzeige-Button
    - Session-Anzahl mit Anzeige-Button
  - Aktions-Buttons:
    - Abbrechen (OutlinedButton)
    - Speichern (erweiterter Button mit Lade-Indikator)
    - Duplizieren (Button in Rot)
  - Settings werden beim Speichern korrekt übernommen

#### 4.2 Quest-Screens
- [x] `lib/screens/enhanced_quest_library_screen.dart`
  - ✅ Verwendet `UnifiedQuestCard`
  - Alle Filter und Suchfunktionen erhalten
- [ ] `lib/screens/edit_campaign_quest_screen.dart`
  - Verwende `UnifiedQuestCard`

#### 4.3 Helden-Screens
- [ ] `lib/screens/enhanced_pc_list_screen.dart`
  - Verwende `UnifiedHeroCard`
- [ ] `lib/screens/enhanced_edit_pc_screen.dart`
  - Verwende `UnifiedHeroCard`

#### 4.4 Item-Screens
- [ ] `lib/screens/enhanced_item_library_screen.dart`
  - Verwende `UnifiedItemCard` (nach Erstellung)
- [ ] `lib/screens/enhanced_edit_item_screen.dart`
  - Verwende `UnifiedItemCard` (nach Erstellung)

#### 4.5 Wiki-Screens
- [ ] `lib/screens/enhanced_lore_keeper_screen.dart`
  - Verwende `UnifiedWikiEntryCard` (nach Erstellung)
- [ ] `lib/screens/enhanced_edit_wiki_entry_screen.dart`
  - Verwende `UnifiedWikiEntryCard` (nach Erstellung)

#### 4.6 Sound-Screens
- [ ] `lib/screens/enhanced_sound_library_screen.dart`
  - Verwende `UnifiedSoundCard` (nach Erstellung)
- [ ] `lib/screens/enhanced_edit_sound_screen.dart`
  - Verwende `UnifiedSoundCard` (nach Erstellung)

#### 4.7 Session-Screens
- [ ] `lib/screens/enhanced_session_list_for_campaign_screen.dart`
  - Verwende `UnifiedSessionCard` (nach Erstellung)
- [ ] `lib/screens/enhanced_edit_session_screen.dart`
  - Verwende `UnifiedSessionCard` (nach Erstellung)

#### 4.8 Creature-Screens
- [ ] `lib/screens/enhanced_bestiary_screen.dart`
  - Verwende `UnifiedCreatureCard` (nach Erstellung)
- [ ] `lib/screens/enhanced_edit_creature_screen.dart`
  - Verwende `UnifiedCreatureCard` (nach Erstellung)

---

## Phase 5: Testing 🧪

### Zu erstellende Tests

#### 5.1 Unit Tests
- [ ] Tests für Basiskomponenten
  - `unified_card_base_test.dart`
  - `card_header_widget_test.dart`
  - `card_content_widget_test.dart`
  - `card_actions_widget_test.dart`
  - `card_metadata_widget_test.dart`
- [ ] Tests für Theme-System
  - `unified_card_theme_test.dart`

#### 5.2 Widget Tests
- [ ] Tests für Beispiel-Cards
  - `unified_campaign_card_test.dart`
  - `unified_quest_card_test.dart`
  - `unified_hero_card_test.dart`
- [ ] Tests für neue Cards
  - `unified_item_card_test.dart` (nach Erstellung)
  - `unified_wiki_entry_card_test.dart` (nach Erstellung)
  - etc.

#### 5.3 Integration Tests
- [ ] Testen der Screen-Integration
- [ ] Testen der Interaktionen (Tap, Edit, Delete)
- [ ] Testen der State-Updates

---

## Phase 6: Erweiterte Features 🚀

### Zukünftige Erweiterungen

#### 6.1 Animationen
- [ ] Smooth Transitions zwischen Cards
- [ ] Swipe Actions (für iOS-like Experience)
- [ ] Expand/Collapse Animationen

#### 6.2 State Management
- [ ] Integration mit Provider
- [ ] Optimistic Updates
- [ ] Offline Support

#### 6.3 Barrierefreiheit
- [ ] Screen Reader Support
- [ ] Keyboard Navigation
- [ ] High Contrast Mode

#### 6.4 Performance
- [ ] Lazy Loading für lange Listen
- [ ] Virtual Scrolling
- [ ] Efficient Rebuilding

#### 6.5 Weitere UI-Komponenten
- [ ] Filter Chips (für Listen-Filterung)
- [ ] Search Delegate Integration
- [ ] Swipeable Cards
- [ ] Drag & Drop Support

---

## Priorisierte Aufgaben

### Hoch priorisiert (nächste Schritte)
1. **Migration von EnhancedHeroCard** - In PC List Screen
2. **Integration in Campaign Dashboard** - Für Kampagnen-Übersicht
3. **UnifiedItemCard erstellen** - Für Item-Bibliothek
4. **UnifiedWikiEntryCard erstellen** - Für Lore Keeper

### Mittel priorisiert
5. **UnifiedSoundCard erstellen**
6. **UnifiedSessionCard erstellen**
7. **UnifiedCreatureCard erstellen**
8. **Migration aller alten Cards**

### Niedrig priorisiert
9. **Unit Tests erstellen**
10. **Widget Tests erstellen**
11. **Animationen implementieren**
12. **Performance-Optimierungen**

---

## Best Practices

### Neue Cards erstellen

1. Erbe von `UnifiedCardBase`
2. Implementiere `buildCardContent()`
3. Verwende die Basiskomponenten:
   - `CardHeaderWidget` für Header
   - `CardContentWidget` für Content
   - `CardMetadataWidget` für Metadaten
   - `CardActionsWidget` für Aktionen
4. Verwende `UnifiedCardTheme` für Farben
5. Befolge die Konstanten aus `UnifiedCardBase`

### Migration von alten Cards

1. Analysiere die Struktur der alten Card
2. Identifiziere gemeinsame Elemente
3. Ersetze mit neuen Basiskomponenten
4. Teste alle Funktionen
5. Entferne den alten Code

---

## Statistiken

### Erstellte Komponenten
- **Basiskomponenten:** 5/5 ✅
- **Beispiel-Cards:** 3/8 🔄
- **Gesamt:** 8/13

### Migrationsstatus
- **Alte Cards migriert:** 2/7 🔄 (Quest + Campaign)
- **Screens integriert:** 2/16 🔄 (Quest Library + Campaign Selection)

### Testabdeckung
- **Unit Tests:** 0/6 ❌
- **Widget Tests:** 0/8 ❌
- **Integration Tests:** 0/3 ❌

---

## Referenzen

- [README.md](./README.md) - Ausführliche Dokumentation des Systems
- [Datenbank-Architektur](../../database/core/README.md) - Datenbank-Struktur
- [Code-Standards](../../../CODE_STANDARDS.md) - Projekt-Coding-Standards

---

## Kontakt und Feedback

Bei Fragen oder Problemen:
1. Prüfe die README.md Dokumentation
2. Schau dir die Beispiel-Implementierungen an
3. Konsultiere das Flutter Widget-Katalog
4. Eröffne ein Issue im Repository

---

**Hinweis:** Dieses Dokument wird regelmäßig aktualisiert, um den Fortschritt der Migration zu verfolgen.
