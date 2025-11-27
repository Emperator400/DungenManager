Du bist der `UI Theme Specialist`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `lib/screens/enhanced_edit_quest_screen.dart` für den betroffenen Screen.
3. Lies `lib/viewmodels/edit_quest_viewmodel.dart` für den ViewModel.
4. Lies `lib/main.dart` für die aktuelle Provider-Struktur.

**Dein spezifischer Task:**
Korrigiere das Provider-Scoping Problem für den EditQuestViewModel im EnhancedEditQuestScreen. Das Problem ist: `Could not find the correct Provider<EditQuestViewModel> above this EnhancedEditQuestScreen Widget`

**Konkrete Anforderungen:**
1. Analysiere die aktuelle Provider-Implementierung im EnhancedEditQuestScreen
2. Identifizieren wo und wie der EditQuestViewModel bereitgestellt werden sollte
3. Prüfen ob Builder-Pattern verwendet werden muss oder ob der Provider in der falschen Route/Scope ist
4. Stelle sicher dass der Provider im richtigen Widget-Baum verfügbar ist
5. Berücksichtige mögliche Hot-restart Anforderungen nach Provider-Änderungen

**Häufige Ursachen (zur Orientierung):**
- Hot-reload nach Provider-Änderungen (erfordert hot-restart)
- Provider ist in einer anderen Route/Scope definiert
- BuildContext wird verwendet, der Vorfahre des Providers ist
- Provider wird erstellt und sofort darauf zugegriffen (ohne builder)

**Dein Protokoll (A-P-B-V-L):**
(Analysiere den aktuellen Code, erstelle einen Plan mit den genauen Änderungen, lass dir den Plan bestätigen, implementiere die Änderungen, verifiziere die Funktion)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du (Sub-Agent) während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt (z.B. komplexes Routing-Problem):
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erwartetes Ergebnis:**
- Der EditQuestViewModel ist korrekt im EnhancedEditQuestScreen verfügbar
- Die ProviderNotFoundException tritt nicht mehr auf
- Der Screen funktioniert nach hot-restart einwandfrei
- Alle Provider-Scoping-Prinzipien sind korrekt implementiert
