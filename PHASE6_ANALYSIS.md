# Phase 6: Aufräumarbeiten - Analyse und Plan

## 📊 Aktueller Stand

### Identifizierte alte Dateien

#### Alte Repositories (11 Dateien)
- `lib/database/repositories/base_repository.dart`
- `lib/database/repositories/campaign_repository.dart`
- `lib/database/repositories/creature_repository.dart`
- `lib/database/repositories/inventory_item_repository.dart`
- `lib/database/repositories/item_repository.dart`
- `lib/database/repositories/player_character_repository.dart`
- `lib/database/repositories/quest_repository.dart`
- `lib/database/repositories/session_repository.dart`
- `lib/database/repositories/sound_repository.dart`
- `lib/database/repositories/wiki_repository.dart`
- `lib/database/repositories/wiki_link_repository.dart`

#### Entity-Klassen (10 Dateien)
- `lib/database/entities/base_entity.dart`
- `lib/database/entities/campaign_entity.dart`
- `lib/database/entities/creature_entity.dart`
- `lib/database/entities/inventory_item_entity.dart`
- `lib/database/entities/item_entity.dart`
- `lib/database/entities/player_character_entity.dart`
- `lib/database/entities/quest_entity.dart`
- `lib/database/entities/session_entity.dart`
- `lib/database/entities/sound_entity.dart`
- `lib/database/entities/wiki_entity.dart`
- `lib/database/entities/wiki_link_entity.dart`

## ⚠️ Blocker

Die alten Repository-Klassen werden noch in folgenden Services verwendet:

### Wiki-Services (7 Services)
1. `wiki_entry_service.dart` - verwendet `wiki_repository`
2. `wiki_link_service.dart` - verwendet `wiki_repository` und `wiki_link_repository`
3. `wiki_search_service.dart` - verwendet `wiki_repository`
4. `wiki_template_service.dart` - verwendet `wiki_repository` und `wiki_link_repository`
5. `wiki_bulk_operations_service.dart` - verwendet `wiki_repository` und `wiki_link_repository`
6. `wiki_export_import_service.dart` - verwendet `wiki_repository` und `wiki_link_repository`
7. `wiki_auto_link_service.dart` - verwendet `wiki_repository`, `wiki_link_repository`, `player_character_repository`, `campaign_repository`, `creature_repository`

### Quest-Services (3 Services)
8. `quest_library_service.dart` - verwendet `quest_repository`
9. `quest_reward_service.dart` - verwendet `quest_repository`, `player_character_repository`, `item_repository`, `wiki_repository`, `inventory_item_repository`
10. `quest_service_locator.dart` - verwendet `quest_repository`, `item_repository`, `wiki_repository`, `player_character_repository`, `inventory_item_repository`

### Character-Services (1 Service)
11. `character_editor_service.dart` - verwendet `player_character_repository`, `creature_repository`

### Campaign-Services (1 Service)
12. `campaign_service_locator.dart` - verwendet `campaign_repository`

### Inventory-Services (1 Service)
13. `inventory_service.dart` - verwendet `inventory_item_repository`, `item_repository`, `creature_repository`, `quest_entity`, `player_character_repository`

### Sound-Services (1 ViewModel)
14. `sound_mixer_viewmodel.dart` - verwendet `sound_repository`

## 🎯 Empfohlener Ansatz

### Option A: Vollständige Service-Migration (Empfohlen für langfristige Sauberkeit)

**Vorteile:**
- Vollständige Konsistenz
- Keine doppelten APIs
- Sauberer Code

**Nachteile:**
- Sehr großer Aufwand (~15 Services migrieren)
- Risiko von Breaking Changes
- Benötigt viel Testing

**Geschätzte Dauer:** 5-7 Tage

### Option B: Alte Repositories als "deprecated" markieren (Empfohlen für kurzfristige Fertigstellung)

**Vorteile:**
- Schnelle Fertigstellung
- Kein Risiko von Breaking Changes
- Services funktionieren weiterhin

**Nachteile:**
- Technische Schulden
- Duplizierter Code bleibt erhalten
- Wartungsaufwand für zwei Systeme

**Geschätzte Dauer:** 1 Tag

## 📝 Empfohlene Vorgehensweise (Option B)

### Schritt 1: Dokumentation aktualisieren
- REFACTORING_PROGRESS.md aktualisieren
- Phase 6 als "Teilweise abgeschlossen" markieren
- Hinweis auf Service-Migration hinzufügen

### Schritt 2: Alte Repositories markieren (optional)
- @deprecated Annotation hinzufügen
- Kommentare mit Hinweis auf neue Repositories

### Schritt 3: Dokumentation für Service-Migration erstellen
- PHASE6_SERVICE_MIGRATION_PLAN.md erstellen
- Schritt-für-Schritt Anleitung für Migration

### Schritt 4: Testing und Verifizierung
- Prüfen ob alle Tests noch laufen
- Verifizieren ob App funktioniert

## 🔍 Nächste Schritte

1. **Option B umsetzen** (1 Tag)
   - Dokumentation aktualisieren
   - PHASE6_SERVICE_MIGRATION_PLAN.md erstellen
   - Phase 6 abschließen

2. **Option A planen** (Optional, später)
   - Service-Migration als separates Projekt aufnehmen
   - Priorität nach Feature-Entwicklung

## ✅ Abschlusskriterien für Phase 6 (Option B)

- [x] Alle alten Dateien identifiziert
- [x] Verwendung in Services analysiert
- [ ] Dokumentation aktualisiert (REFACTORING_PROGRESS.md)
- [ ] Service-Migrationsplan erstellt
- [ ] Tests verifiziert

## 📚 Referenz

- **REFACTORING_PROGRESS.md** - Hauptdokumentation
- **PHASE5_TESTS_UPDATE.md** - Tests Status
- **API_REFACTORING_PLAN.md** - Originalplan

---

*Erstellt: 29.12.2025*
*Status: Analyse abgeschlossen, Umsetzung empfohlen*
