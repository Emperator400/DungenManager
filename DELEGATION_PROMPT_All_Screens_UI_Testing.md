# Delegation Prompt: All Screens UI Testing

Du bist der Frontend-Agent.

**Kontext-Laden:**
1. Lies `docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `UI_SZENEN_UEBERSICHT.md` für alle verfügbaren Screens und deren Beschreibungen.
3. Lies `lib/main.dart` um die aktuelle AppSelectionScreen-Struktur zu verstehen.
4. Lies `lib/theme/dnd_theme.dart` um das Design-System zu verstehen.

**Dein spezifischer Task:**
Implementiere eine neue "Alle Screens" Testing-Funktionalität gemäß PROJECT_TODO.md:
1. Erweitere die AppSelectionScreen in main.dart um einen dritten Button "Alle Screens"
2. Erstelle einen neuen AllScreensScreen mit ListView aller verfügbaren Screens
3. Jeder Screen sollte mit Name und Kurzbeschreibung angezeigt werden
4. Navigation zu jedem einzelnen Screen implementieren
5. Konsistentes DnDTheme Design verwenden
6. Rücknavigation sicherstellen

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan (mit Diffs + Verifikation), Bestätigung (User-Gate), Verifikation, Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL (Deine Idee):**
Wenn du (Sub-Agent) während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt (z.B. du bist Frontend, das Problem ist DB):
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.
