# Plan: Vollständiges Vorlagen-System

## Context

Ein DM kann eine Kampagne vollständig vorplanen (Orte, Szenen, Quests, NPCs, Lore) und diese als Vorlage speichern. Bei Verwendung entsteht eine saubere Kopie — der DM fügt nur noch Helden hinzu und kann sofort spielen. Vorlagen können als `.json`-Datei exportiert und geteilt werden (wie ein veröffentlichtes Abenteuer oder DLC).

**Was bereits existiert:**
- `Campaign.isTemplate` + `Campaign.templateId` (Felder + DB)
- Partieller Copy in `CampaignService.createCopyFromTemplate()`: Orte + Quests (ohne ID-Remapping)
- `Ort.templateOrtId` Tracking
- Basic Template-UI in `campaign_selection_layout_widget.dart`

**Was fehlt:**
- Vollständiger Deep-Copy (Sessions/Szenen, Kreaturen, WikiEntries)
- Korrektes ID-Remapping aller Cross-References
- Export/Import als `.json`-Datei

---

## Ownership-Tree (was kopiert wird)

```
Campaign (neue ID)
├── WikiEntries         → neue IDs, parentId remappen
├── Creatures           → neue IDs
├── Quests              → neue IDs, linkedWikiEntryIds remappen
├── Orte                → neue IDs, connectedOrtIds + parentOrtId remappen
├── Sessions            → neue IDs (Prep-Sessions aus Vorlage)
│   └── Scenes          → neue IDs, linkedQuestIds + linkedWikiEntryIds remappen
└── Campaign.sessionIds / questIds / wikiEntryIds aktualisieren
```

**Was NICHT kopiert wird** (State / Laufzeit-Daten):
- `Session.characterTrackingIds` (Helden-HP, Conditions)
- `Session.questProgressIds` (Fortschritt)
- `Ort.lastVisitedAt`, `Ort.memory`
- Quest.completedAt → Status auf `active` zurücksetzen

---

## Phase 1 — Vollständiger Deep-Copy mit ID-Remapping

### Datei: `lib/services/campaign_service.dart`

Methode `createCopyFromTemplate()` wird komplett neu geschrieben.

**Kern-Muster: ID-Remap-Tabelle**
```dart
final Map<String, String> idMap = {}; // oldId → newId

// Für jede Entity:
final newId = UuidService().generateId();
idMap[old.id] = newId;
```

**Kopier-Reihenfolge** (Abhängigkeiten zuerst):

```dart
Future<Campaign> createCopyFromTemplate(Campaign template, {required String title}) async {
  final idMap = <String, String>{};

  // 1. WikiEntries kopieren
  final wikiEntries = await _wikiRepository.findByCampaign(template.id);
  final copiedWikiIds = <String>[];
  for (final w in wikiEntries) {
    final newId = uuid();
    idMap[w.id] = newId;
    copiedWikiIds.add(newId);
  }
  // parentId remappen nach erster Runde:
  for (final w in wikiEntries) {
    await _wikiRepository.create(w.copyWith(
      id: idMap[w.id]!,
      campaignId: newCampaignId,
      parentId: w.parentId != null ? idMap[w.parentId!] : null,
    ));
  }

  // 2. Creatures kopieren
  final creatures = await _creatureRepository.findByCampaign(template.id);
  for (final c in creatures) {
    final newId = uuid();
    idMap[c.id] = newId;
    await _creatureRepository.create(c.copyWith(id: newId, campaignId: newCampaignId));
  }

  // 3. Quests kopieren
  final quests = await _questRepository.findByCampaign(template.id);
  final copiedQuestIds = <String>[];
  for (final q in quests) {
    final newId = uuid();
    idMap[q.id] = newId;
    copiedQuestIds.add(newId);
  }
  for (final q in quests) {
    await _questRepository.create(q.copyWith(
      id: idMap[q.id]!,
      campaignId: newCampaignId,
      status: QuestStatus.active,
      completedAt: null,
      linkedWikiEntryIds: _remapIds(q.linkedWikiEntryIds, idMap),
    ));
  }

  // 4. Orte kopieren (2 Phasen wegen connectedOrtIds)
  final orte = await _ortRepository.findByCampaign(template.id);
  for (final o in orte) { idMap[o.id] = uuid(); }
  for (final o in orte) {
    await _ortRepository.create(o.copyWith(
      id: idMap[o.id]!,
      campaignId: newCampaignId,
      templateOrtId: o.id,
      connectedOrtIds: _remapIds(o.connectedOrtIds, idMap),
      parentOrtId: o.parentOrtId != null ? idMap[o.parentOrtId!] : null,
      lastVisitedAt: null,
      memory: null,
    ));
  }

  // 5. Sessions + Scenes kopieren
  final sessions = await _sessionRepository.findByCampaign(template.id);
  final copiedSessionIds = <String>[];
  for (final s in sessions) {
    final newSessionId = uuid();
    idMap[s.id] = newSessionId;
    copiedSessionIds.add(newSessionId);

    final scenes = await _sceneRepository.findBySession(s.id);
    final copiedSceneIds = <String>[];
    for (final sc in scenes) {
      final newSceneId = uuid();
      idMap[sc.id] = newSceneId;
      copiedSceneIds.add(newSceneId);
      await _sceneRepository.create(sc.copyWith(
        id: newSceneId,
        sessionId: newSessionId,
        linkedQuestIds: _remapIds(sc.linkedQuestIds, idMap),
        linkedWikiEntryIds: _remapIds(sc.linkedWikiEntryIds, idMap),
      ));
    }

    await _sessionRepository.create(s.copyWith(
      id: newSessionId,
      campaignId: newCampaignId,
      sceneIds: copiedSceneIds,
      characterTrackingIds: [],   // State zurücksetzen
      questProgressIds: [],        // State zurücksetzen
    ));
  }

  // 6. Campaign erstellen
  return await _campaignRepository.create(Campaign.create(
    id: newCampaignId,
    title: title,
    isTemplate: false,
    templateId: template.id,
    sessionIds: copiedSessionIds,
    questIds: copiedQuestIds,
    wikiEntryIds: copiedWikiIds,
    // ... weitere Felder von template übernehmen
  ));
}

List<String> _remapIds(List<String> ids, Map<String, String> idMap) =>
    ids.map((id) => idMap[id] ?? id).toList();
```

**Neue Repos in `CampaignService` injizieren:**
- `WikiEntryModelRepository`
- `CreatureModelRepository`  
- `SessionModelRepository`
- `SceneModelRepository`

---

## Phase 2 — Export/Import

### Neue Datei: `lib/services/campaign_template_export_import_service.dart`

Muster: `WikiExportImportService` — `file_picker`, `path_provider` bereits vorhanden.

**Export-Format `.campaign.json`:**
```json
{
  "format": "dungenmanager_campaign_template",
  "version": "1.0",
  "exportedAt": "2026-05-14T...",
  "campaign": { ...Campaign-Felder... },
  "orte": [ ...Ort-Objekte... ],
  "quests": [ ...Quest-Objekte... ],
  "sessions": [ ...Session-Objekte... ],
  "scenes": [ ...Scene-Objekte... ],
  "creatures": [ ...Creature-Objekte... ],
  "wikiEntries": [ ...WikiEntry-Objekte... ]
}
```

IDs bleiben im Export erhalten (UUIDs). Beim Import: neue IDs + Remapping, genau wie beim Copy.

**Methoden:**
```dart
class CampaignTemplateExportImportService {
  Future<ServiceResult<String>> exportTemplate(String campaignId) async { ... }
  // → .campaign.json in app-Verzeichnis, gibt Dateipfad zurück

  Future<ServiceResult<Campaign>> importTemplate(String filePath) async { ... }
  // → liest JSON, neue IDs zuweisen, in DB speichern, isTemplate: true
}
```

---

## Phase 3 — UI-Erweiterungen

### `campaign_selection_layout_widget.dart` (bestehend erweitern)
- **Export-Button** auf jeder Template-Karte (Icon: `Icons.share_outlined`)
- **Import-Button** in der Template-Sektion (Icon: `Icons.download_outlined`)

### Template-Detail (optional, neue Datei `lib/screens/campaign/template_detail_screen.dart`)
Zeigt was eine Vorlage enthält:
- Anzahl Orte, Szenen, Quests, Kreaturen, Wiki-Einträge
- Beschreibung + Accent-Farbe
- "Vorlage verwenden" → createCopyFromTemplate
- "Exportieren" → Export-Dialog

### ViewModel (`campaign_viewmodel.dart` erweitern)
```dart
Future<void> exportTemplate(String campaignId) async { ... }
Future<void> importTemplate(String filePath) async { ... }
```

---

## Neue/geänderte Dateien

| Datei | Aktion |
|-------|--------|
| `lib/services/campaign_service.dart` | `createCopyFromTemplate()` komplett neu + neue Repo-Injektionen |
| `lib/services/campaign_template_export_import_service.dart` | Neu |
| `lib/viewmodels/campaign_viewmodel.dart` | Export/Import-Methoden |
| `lib/widgets/campaign/campaign_selection_layout_widget.dart` | Export/Import-Buttons |
| `lib/screens/campaign/template_detail_screen.dart` | Neu (optional) |
| `lib/main.dart` | Neuen Service registrieren |

---

## Verifikation

1. Template anlegen → Orte, Szenen, Quests, NPCs, Lore hinzufügen
2. "Vorlage verwenden" → Kopie erstellt, alle Entities vorhanden, IDs frisch, Cross-References korrekt (Ort-Verbindungen zeigen auf neue Ort-IDs)
3. Kopie spielen → Originalvorlage unverändert
4. Vorlage exportieren → `.campaign.json` erstellt
5. Auf anderem Gerät importieren → Vorlage erscheint, alle Inhalte vorhanden
6. `flutter analyze` — null Warnungen (außer `inference_failure_*`)
