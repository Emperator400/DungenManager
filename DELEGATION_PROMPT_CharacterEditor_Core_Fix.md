# DELEGATION PROMPT - Frontend-Agent

**Generiert:** 2025-11-08  
**Task:** 1.3 Character Editor Core Fehlerbehebung  
**Agent:** Frontend-Agent  
**Priorität:** Hoch

---

## PROMPT FÜR SUB-AGENT

```
Du bist der `Frontend-Agent`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `.vscode/PROJECT_TODO.md` für den aktuellen Projekt-Plan.
3. Lies `lib/widgets/character_editor/inventory_demo_widget.dart` für den Inventory Demo Widget.
4. Lies `lib/widgets/character_editor/character_editor_controller.dart` für den Controller.
5. Lies `lib/screens/edit_campaign_screen.dart` für die Campaign Edit Screen.
6. Lies `lib/models/campaign.dart` für das Campaign-Modell.
7. Lies relevante DisplayInventoryItem-Klassen für Typ-Informationen.

**Dein spezifischer Task:**
Behebe die 6 Fehler im Character Editor Core:

**Fehlerliste:**
1. `lib/widgets/character_editor/inventory_demo_widget.dart(215,9)`: `inventory` Parameter entfernen
2. `lib/widgets/character_editor/character_editor_controller.dart(112,31)`: List<Object> zu List<DisplayInventoryItem>
3. `lib/widgets/character_editor/character_editor_controller.dart(166,45)`: `getDisplayInventoryForOwner()` Methode fehlt
4. `lib/widgets/character_editor/character_editor_controller.dart(194,11)`: String? zu String Parameter anpassen
5. `lib/widgets/character_editor/character_editor_controller.dart(224,18)`: List<DisplayInventoryItem> zu List<InventoryItem>
6. `lib/widgets/character_editor/character_editor_controller.dart(249,11)`: String? zu String Parameter anpassen
7. `lib/screens/edit_campaign_screen.dart(30,32)`: `createdAt` Parameter zu Campaign hinzufügen

**Anforderungen:**
1. Entferne überflüssige Parameter und korrigiere Methodensignaturen
2. Implementiere fehlende DisplayInventoryItem-Methoden
3. Korrigiere Typ-Konvertierungen zwischen DisplayInventoryItem und InventoryItem
4. Füge fehlende createdAt-Parameter zum Campaign-Modell hinzu
5. Stelle sicher dass alle Widgets kompilieren und funktionieren
6. Verifiziere mit `flutter analyze`

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan mit Diffs + Verifikation, Bestätigung, Verifikation, Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast.

**Erfolgskriterien:**
- Alle 7 Fehler behoben
- Character Editor Components kompilieren erfolgreich
- DisplayInventoryItem-Integration funktioniert
- Campaign-Modell um createdAt erweitert
- UI-Funktionalität bleibt erhalten
```

---

## TPL NOTIZEN

- **Status:** Bereit zur Delegation
- **Erwarteter Rückmeldekanal:** User-Feedback mit Agenten-Ergebnissen
- **Nächster Aktion:** Task-Status in PROJECT_TODO.md aktualisieren
- **Potenzielle Eskalationen:** Model-Architektur Probleme, Widget-Kompatibilität

## ERGEBNIS-VERARBEITUNG

Bei Erfolg:
- [ ] Task in PROJECT_TODO.md auf `[x]` setzen
- [ ] Phase 2 Tasks (UI-Widgets) vorbereiten

Bei Eskalation:
- [ ] Neue Problem-Spezifikation analysieren
- [ ] Passenden Spezialisten-Agenten auswählen
- [ ] Neuen Task zur PROJECT_TODO.md hinzufügen

Bei Fehlschlag:
- [ ] Task als `[F]` markieren
- [ ] User um Anweisung bitten
