# DELEGATION PROMPT - Debugging Error Specialist

**Generiert:** 2025-11-06 19:36
**Task:** 1.3 Übrige Services Standardisierung
**Agent:** Debugging Error Specialist

---

## PROMPT FÜR SUB-AGENT

```
Du bist der `Debugging Error Specialist`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `BUG_ARCHIVE_ENTRY_WIKI_ENTRY_SERVICE.md` für das character_editor_service Erfolgs-Muster.
3. Lies `BUG_ARCHIVE_ENTRY_WIKI_SERVICES_OPTIMIZATION.md` für Wiki-Services Architektur-Pattern.
4. Lies `.vscode/docs/roles/debugging_error_specialist.md` für deine spezifische Rolle.

**Dein spezifischer Task:**
Standardisiere die übrigen Services im Projekt gemäß dem character_editor_service Muster. 

**Betroffene Dateien:**
- lib/services/campaign_service.dart
- lib/services/quest_library_service.dart  
- lib/services/quest_data_service.dart
- lib/services/creature_data_service.dart
- lib/services/inventory_service.dart
- lib/services/player_character_service.dart
- lib/services/wiki_service_locator.dart
- lib/services/campaign_service_locator.dart
- lib/services/quest_service_locator.dart
- lib/services/quest_lore_integration_service.dart
- lib/services/quest_reward_service.dart
- lib/services/item_effect_service.dart
- lib/services/wiki_template_service.dart

**Anforderungen:**
1. Analysiere jeden Service auf Fehler und Code-Quality Issues
2. Wende das character_editor_service Muster an (Import-Reihenfolge, const constructors, expression bodies)
3. Stelle sicher, dass alle Services konsistente Error-Handling Patterns verwenden
4. Dokumentiere gefundene Muster und systematische Probleme
5. Erstelle Bug-Archive-Einträge für signifikante Funde

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan mit Diffs + Verifikation, Bestätigung, Verifikation, Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.
```

---

## TPL NOTIZEN

- **Status:** Delegiert
- **Erwarteter Rückmeldekanal:** User-Feedback mit Agenten-Ergebnissen
- **Nächster Aktion:** Task-Status aktualisieren basierend auf Feedback
- **Potenzielle Eskalationen:** Database Issues, Architectural Problems, Performance Issues

## ERGEBNIS-VERARBEITUNG

Bei Erfolg:
- [ ] Task in PROJECT_TODO.md auf `[x]` setzen
- [ ] Bug-Archive-Einträge prüfen und integrieren
- [ ] Nächsten Task (1.4) delegieren

Bei Eskalation:
- [ ] Neue Problem-Spezifikation analysieren
- [ ] Passenden Spezialisten-Agenten auswählen
- [ ] Neuen Task zur PROJECT_TODO.md hinzufügen

Bei Fehlschlag:
- [ ] Task als `[F]` markieren
- [ ] User um Anweisung bitten
