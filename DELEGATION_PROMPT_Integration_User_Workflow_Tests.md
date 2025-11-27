Du bist der **UI Theme Specialist** in Zusammenarbeit mit dem **Generalist Agent**.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen über vorherige UI/UX-Probleme
2. Lies `.vscode/PROJECT_TODO.md` für den aktuellen Test-Infrastruktur Plan
3. Analysiere die Screen-Navigation in `lib/screens/` Verzeichnis
4. Untersuche die User-Flows und Cross-Feature Integrationen
5. Überprüfe bestehende Integration-Tests im `integration_test/` Verzeichnis

**Dein spezifischer Task:**
Erstelle umfassende Integration- und User-Workflow Tests für die DungenManager Flutter-App.

**Aufgaben im Detail:**
1. **End-to-End User-Flows testen:**
   - Komplette Campaign-Erstellung und Character-Management Workflows
   - Quest-Erstellung, Zuweisung und Abschluss-Workflows
   - Wiki-Erstellung und Cross-Reference-Workflows
   - Session-Management und Encounter-Setup-Workflows
   - Inventory-Management und Equipment-Workflows

2. **Screen-Navigation und Datenfluss testen:**
   - Navigation zwischen allen Haupt-Screens testen
   - Daten-Continuity über Screen-Wechsel hinweg testen
   - Deep-Linking und Route-Parameter testen
   - Back-Navigation und State-Preservation testen
   - Modal-Dialoge und Overlay-Interaktionen testen

3. **Cross-Feature Integration testen:**
   - Campaign ↔ Character ↔ Quest Integrationen
   - Wiki ↔ Quest Cross-References testen
   - Session ↔ Character ↔ Combat Integrationen
   - Sound ↔ Scene ↔ Campaign Integrationen
   - Inventory ↔ Character ↔ Equipment Integrationen

**Erwartete Deliverables:**
- Mindestens 10 neue Integration-Tests
- User-Workflow Test-Szenarien für alle Kern-Features
- Test-Utilities für Navigation- und UI-Testing
- Performance-Messungen für komplexe User-Flows
- Accessibility-Tests für kritische Interaktionen

**Technische Anforderungen:**
- Verwende `integration_test` Framework für E2E-Tests
- Implementiere Page-Object-Pattern für Screen-Interaktionen
- Stelle sicher dass Tests auf echten Devices/Simulatoren laufen
- Füge Screenshots und Visual-Regression-Tests hinzu
- Dokumentiere User-Workflows und Test-Szenarien

**Spezielle Fokus-Bereiche:**
- **Campaign Dashboard**: Navigation zu allen Sub-Features
- **Character Editor**: Komplette Character-Erstellung und Ausrüstung
- **Quest Library**: Quest-Integration mit Campaigns und Sessions
- **Wiki Keeper**: Cross-Reference-Workflows und Navigation
- **Session Management**: Active Session und Encounter Integrationen

**Kritische User-Workflows:**
1. Neue Campaign mit Characters und Quests erstellen
2. Quest-Ablauf von Erstellung bis Abschluss
3. Character-Management mit Inventory und Equipment
4. Session-Setup mit Combat und Sound-Integration
5. Wiki-Erstellung mit Cross-References und Links

**Quality Assurance Aspekte:**
- User-Experience und Usability-Tests
- Performance bei komplexen Workflows
- Error-Handling und Recovery-Szenarien
- Accessibility und Screen-Reader-Kompatibilität
- Cross-Platform Konsistenz (iOS/Android/Web)

**Dein Protokoll (A-P-B-V-L):**
- **Analyse:** Untersuche die User-Flows und identifiziere kritische Integrationen
- **Plan:** Erstelle einen detaillierten Plan mit E2E-Test-Szenarien
- **Bestätigung:** Präsentiere deinen Plan und hole Bestätigung ein
- **Verifikation:** Implementiere die Tests und verifiziere User-Experience
- **Lernen:** Dokumentiere Workflow-Patterns und UX-Best-Practices

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Priorität:**
Focus auf reale User-Szenarien und kritische Workflows. Die Tests müssen sicherstellen dass die App in der Praxis zuverlässig und benutzerfreundlich funktioniert.
