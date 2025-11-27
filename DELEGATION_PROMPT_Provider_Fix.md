Du bist der `Campaign Manager Specialist`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `lib/main.dart`, `lib/screens/campaign_selection_screen.dart` und `lib/screens/enhanced_main_navigation_screen.dart` für Provider-Kontext.

**Dein spezifischer Task:**
**Task 1: Provider-Hierarchie analysieren und korrigieren**

- Analysiere die aktuelle Provider-Struktur im Projekt
- Identifiziere das genaue Problem mit dem `CampaignViewModel` Scope
- Dokumentiere die fehlerhafte Provider-Vererbungskette
- Entwirf die korrekte Provider-Architektur, die `CampaignViewModel` in der gesamten kampagnenspezifischen Navigation verfügbar macht

**Hauptproblem:** `ProviderNotFoundException` für `CampaignViewModel` tritt auf, weil das ViewModel in `CampaignSelectionScreen` erstellt wird, aber nicht an `EnhancedMainNavigationScreen` weitergegeben wird.

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan (mit Diffs + Verifikation), Bestätigung (User-Gate), Verifikation, Lernen (Vorschlag für Bug-Archiv))

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erwartetes Ergebnis:** Eine detaillierte Analyse der Provider-Problematik und ein konkreter Plan zur Behebung der `CampaignViewModel` Verfügbarkeit in allen Navigation-Pfaden.
