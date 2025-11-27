Du bist der `Frontend-Agent`.

**Kontext-Laden:**
1. Lies `docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `.vscode/PROJECT_TODO.md` für den aktuellen Projekt-Plan.
3. Lies `lib/screens/campaign_list_screen.dart` (Legacy-Version).
4. Lies `lib/screens/enhanced_campaign_dashboard_screen.dart` (Referenz für neue Architektur).
5. Lies `lib/viewmodels/campaign_viewmodel.dart` (ViewModel für State-Management).
6. Lies `lib/widgets/campaign/enhanced_campaign_card_widget.dart` (Moderne UI-Komponenten).

**Dein spezifischer Task:**
Migriere `lib/screens/campaign_list_screen.dart` vollständig auf die neue Service-basierte Architektur:

1. **Architektur-Migration:**
   - Entferne alle direkten DatabaseHelper-Zugriffe
   - Integriere CampaignViewModel mit Provider-Pattern
   - Verwende CampaignService über das ViewModel
   - Implementiere reactive UI mit Consumer/Builder

2. **UI-Modernisierung:**
   - Ersetze ListView durch responsive GridView
   - Integriere EnhancedCampaignCardWidget
   - Übernehme Suche/Filter/Sortier-Funktionen vom enhanced Dashboard
   - Implementiere Loading-States und Fehlerbehandlung
   - Konsistentes DnD-Theme verwenden

3. **Navigation & Aktionen:**
   - Provider-basierte Navigation zu Campaign Dashboard
   - Moderne Dialoge für Erstellen/Löschen/Bearbeiten
   - Floating Action Button mit Provider-Integration
   - PopupMenu durch moderne Aktionen ersetzen

4. **Code-Qualität:**
   - Flutter Analyse auf 0 Errors确保
   - Consistent mit enhanced Dashboard Design
   - Responsive Design für verschiedene Bildschirmgrößen
   - Accessibility berücksichtigen

**Dein Protokoll (A-P-B-V-L):**
(Du führst das volle A-P-B-V-L Protokoll *nur* für diesen Task durch: Analyse, Plan (mit Diffs + Verifikation), Bestätigung (User-Gate), Verifikation, Lernen (Vorschlag für Bug-Archiv))

**KRITISCHES ESKALATIONS-PROTOKOLL (Deine Idee):**
Wenn du (Sub-Agent) während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt (z.B. du bist Frontend, das Problem ist Backend-Services):
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erfolgskriterien:**
- Legacy DatabaseHelper vollständig entfernt
- CampaignViewModel voll integriert mit Provider
- Enhanced UI-Komponenten verwendet
- Suche/Filter/Sortier-Funktionen funktionsfähig
- 0 Flutter-Analyze Errors
- Navigation funktioniert korrekt zum Dashboard

**Hinweis:**
Behalte die gleiche Funktionalität wie der Legacy Screen bei, aber implementiere sie mit der neuen Architektur. Die用户体验 soll verbessert werden durch moderne UI-Elemente und responsive Design.
