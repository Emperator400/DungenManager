# Delegation Prompt: Test Kompilierungsfehler beheben

"Du bist der **Generalist-Agent**.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `test/unit_models_test.dart` für die spezifischen Fehler.
3. Lies `test/widget_comprehensive_test.dart` für die spezifischen Fehler.
4. Lies `test/wiki_link_test.dart` für die spezifischen Fehler.

**Dein spezifischer Task:**
Behebe die kritischen Kompilierungsfehler in den Test-Dateien:

**Fehlerbeschreibung:**

**1. Argument Type Errors in unit_models_test.dart:**
- Zeile 117: `int` kann nicht `String` zugewiesen werden
- Zeile 414: `int` kann nicht `String` zugewiesen werden  
- Zeile 441: `int` kann nicht `String` zugewiesen werden

**2. Argument Type Error in widget_comprehensive_test.dart:**
- Zeile 60: `int` kann nicht `String` zugewiesen werden

**3. Undefined Class/Function in wiki_link_test.dart:**
- Zeile 133: `WikiHierarchy` Klasse nicht definiert
- Zeile 228: `LinkedWikiEntry` Funktion nicht definiert

**Dein Protokoll (A-P-B-V-L):**

**A - Analyse:**
1. Untersuche die fehlerhaften Zeilen in den betroffenen Test-Dateien
2. Identifiziere die erwarteten vs. tatsächlichen Datentypen
3. Prüfe die Model-Klassen für korrekte Konstruktoren
4. Analysiere fehlende Importe oder Klasse-Definitionen

**P - Plan (mit Diffs + Verifikation):**
1. Korrigiere die Datentypen in den Test-Konstruktoraufrufen
2. Fehlende Klassen/Imports ergänzen oder entfernen
3. Überprüfe Konsistenz mit Model-Definitionen
4. Teste mit `flutter test` nach jeder Änderung

**B - Bestätigung (User-Gate):**
Präsentiere die exakten Korrekturen für jeden Fehler zur Bestätigung vor der Implementierung.

**V - Verifikation:**
Nach Implementierung:
1. Führe `flutter analyze` aus - keine Kompilierungsfehler
2. Führe `flutter test` für die spezifischen Test-Dateien
3. Überprüfe, dass alle Tests kompilieren und laufen

**L - Lernen (Vorschlag für Bug-Archiv):**
Dokumentiere häufige Datentyp-Probleme in Tests und Best Practices.

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du (Sub-Agent) während deiner Analyse feststellst, dass dieser Task nicht gelöst werden kann ODER dass die Ursache außerhalb deines Fachgebiets liegt (z.B. fundamental falsche Model-Struktur):
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann."
