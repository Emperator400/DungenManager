# DELEGATION PROMPT - Backend-Agent

**Generiert:** 2025-11-08  
**Task:** 1.2 Model Tests Fehlerbehebung  
**Agent:** Backend-Agent  
**Priorität:** Hoch

---

## PROMPT FÜR SUB-AGENT

```
Du bist der `Backend-Agent`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `.vscode/PROJECT_TODO.md` für den aktuellen Projekt-Plan.
3. Lies `test/unit_models_test.dart` für die fehlerhaften Tests.
4. Lies `test/widget_comprehensive_test.dart` für den Widget-Test.
5. Lies die relevanten Model-Klassen für Typ-Informationen.

**Dein spezifischer Task:**
Behebe die 7 Fehler in den Model-Tests durch Typ-Konvertierungen:

**Fehlerliste:**
1. `test/unit_models_test.dart(117,20)`: `version: 1` (int) zu String konvertieren
2. `test/unit_models_test.dart(184,15)`: `id: "123"` (String) zu int konvertieren
3. `test/unit_models_test.dart(414,20)`: `version: 1` (int) zu String konvertieren
4. `test/unit_models_test.dart(441,20)`: `version: 1` (int) zu String konvertieren
5. `test/unit_models_test.dart(451,15)`: `id: "123"` (String) zu int konvertieren
6. `test/unit_models_test.dart(460,15)`: `id: "123"` (String) zu int konvertieren
7. `test/widget_comprehensive_test.dart(60,18)`: `version: 1` (int) zu String konvertieren

**Anforderungen:**
1. Analysiere die Model-Klassen um korrekte Typen zu verstehen
2. Konvertiere alle version-Felder zu String
3. Konvertiere alle id-Felder zu int
4. Stelle sicher dass alle Tests kompilieren und laufen
5. Verifiziere mit `flutter test`

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan mit Diffs + Verifikation, Bestätigung, Verifikation, Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast.

**Erfolgskriterien:**
- Alle 7 Typ-Fehler behoben
- `flutter test` läuft ohne compilation failures
- Alle Model-Tests kompilieren erfolgreich
- Typ-Konsistenz über alle Tests hinweg
```

---

## TPL NOTIZEN

- **Status:** Bereit zur Delegation
- **Erwarteter Rückmeldekanal:** User-Feedback mit Agenten-Ergebnissen
- **Nächster Aktion:** Task-Status in PROJECT_TODO.md aktualisieren
- **Potenzielle Eskalationen:** Model-Architektur Probleme, Test-Framework Issues

## ERGEBNIS-VERARBEITUNG

Bei Erfolg:
- [ ] Task in PROJECT_TODO.md auf `[x]` setzen
- [ ] Nächsten Task (1.3) delegieren

Bei Eskalation:
- [ ] Neue Problem-Spezifikation analysieren
- [ ] Passenden Spezialisten-Agenten auswählen
- [ ] Neuen Task zur PROJECT_TODO.md hinzufügen

Bei Fehlschlag:
- [ ] Task als `[F]` markieren
- [ ] User um Anweisung bitten
