# DELEGATION PROMPT - Hero Creation Debugging & Verification

**Ziel**: Überprüfung der Heldenerstellung und -anzeige in der UI

---

## **AUFRUF AN SUB-AGENT**

"Du bist der **Debugging Specialist**.

**Kontext-Laden:**
1. Lies `docs/BUG_ARCHIVE.md` für Projekt-Wissen
2. Lies `PROJECT_TODO.md` für aktuellen Problem-Status
3. Lies `test_hero_creation.dart` für existierende Test-Implementierung

**Dein spezifischer Task:**
Überprüfe systematisch, ob Helden korrekt erstellt werden und in der UI angezeigt werden. Das Problem ist, dass erstellte Helden nicht in der Benutzeroberfläche erscheinen.

**Dein Protokoll (A-P-B-V-L):**
(Analyse → Plan → Bestätigung → Verifikation → Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du feststellst, dass du dieses Problem nicht lösen kannst ODER das Problem außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Neue Problem-Spezifikation für mich (TPL)

---

## **PROBLEM-SPEZIFIKATION**

### **Hauptproblem**
Der Benutzer meldet, dass Helden zwar erstellt werden (oder zumindest der Speichervorgang ausgeführt wird), aber in der UI nicht angezeigt werden. Dies deutet auf ein Problem in der Datenkette hin: Erstellung → Speicherung → UI-Aktualisierung.

### **Symptome:**
- **Speicherung scheint zu funktionieren**: Keine Fehlermeldungen beim Speichern
- **UI zeigt keine Helden**: Erstellte Helden erscheinen nicht in der Liste
- **Verifikation erforderlich**: Es ist unklar, ob Helden tatsächlich in der Datenbank gespeichert werden

### **Mögliche Ursachen:**
1. **Daten-Speicherung**: Character wird nicht korrekt in Datenbank geschrieben
2. **Daten-Laden**: UI lädt Character-Daten nicht korrekt aus Datenbank
3. **UI-Refresh**: Liste wird nach Erstellung nicht aktualisiert
4. **Filter/Query**: Character werden durch falsche Filter ausgeschlossen
5. **Navigation**: Falscher Screen wird angezeigt (Platzhalter statt Charakter-Liste)

---

## **ANALYSE-SCHWERPUNKTE**

### **1. Datenverifizierung**
- Überprüfe ob Charakter tatsächlich in Datenbank gespeichert wird
- Validiere Datenstruktur und -integrität
- Kontrolliere Foreign-Key-Beziehungen

### **2. UI-Flow-Analyse**
- Verfolge den kompletten Flow von Erstellung bis Anzeige
- Identifiziere breaking points in der Kette
- Prüfe State-Management und UI-Updates

### **3. Navigation-Verifikation**
- Überprüfe ob richtige Screen-Implementierung genutzt wird
- Kontrolliere Parameter-Übergabe an Screens
- Validiere Routing-Konfiguration

### **4. Test-Implementierung**
- Erstelle systematische Tests zur Verifikation
- Implementiere Debug-Logging für bessere Nachverfolgung
- Schaffe reproduzierbare Test-Szenarien

---

## **ERWARTETE ERGEBNISSE**

### **Funktionale Anforderungen:**
1. **Verifikations-Tool**: Systematische Überprüfung der Heldenerstellung
2. **Debug-Informationen**: Klare Aussagen über Funktionsfähigkeit
3. **Problemidentifikation**: Präzise Lokalisierung des Problems
4. **Lösungs-Strategie**: Konkrete Schritte zur Behebung

### **Technische Anforderungen:**
1. **Datenbank-Check**: Direkte Überprüfung der gespeicherten Daten
2. **UI-Flow-Test**: Kompletter Flow von Erstellung bis Anzeige
3. **Logging-Implementierung**: Ausführliche Protokollierung
4. **Test-Coverage**: Systematische Abdeckung aller Pfade

### **Qualitätsanforderungen:**
1. **Reproduzierbarkeit**: Problem muss zuverlässig nachvollziehbar sein
2. **Klarheit**: Eindeutige Ergebnisse und Empfehlungen
3. **Vollständigkeit**: Alle möglichen Ursachen berücksichtigt
4. **Dokumentation**: Detaillierte Analyse-Ergebnisse

---

## **ANNAHMEN & ABHÄNGIGKEITEN**

### **Existierende Strukturen:**
- `test_hero_creation.dart` existiert als Test-Datei
- Character Editor Speicherung wurde als "behoben" markiert
- Database Helper Methoden sind implementiert
- Grundlegende Navigation funktioniert

### **Technische Annahmen:**
- SQLite-Datenbank ist funktionsfähig
- Flutter-UI-Komponenten sind implementiert
- Provider/State-Management ist aktiv
- Logging-Infrastruktur ist vorhanden

### **Test-Daten Annahmen:**
- Test-Character können ohne Konflikte erstellt werden
- Kampagne-Daten sind für Character-Erstellung verfügbar
- UI-Tests können ohne externe Abhängigkeiten ausgeführt werden

---

## **VERIFIZIERUNGSKRITERIEN**

### **Datenbank-Verifikation:**
- [ ] Charakter wird tatsächlich in `player_characters` Tabelle gespeichert
- [ ] Alle relevanten Felder sind korrekt gefüllt
- [ ] Foreign-Keys (z.B. `campaign_id`) sind korrekt gesetzt
- [ ] Keine Datenkonsistenz-Probleme

### **UI-Flow-Verifikation:**
- [ ] Character-Editor speichert korrekt
- [ ] Character-Liste lädt Daten aus Datenbank
- [ ] UI aktualisiert sich nach Erstellung
- [ ] Navigation funktioniert korrekt

### **Test-Verifikation:**
- [ ] `test_hero_creation.dart` läuft erfolgreich
- [ ] Tests decken alle kritischen Pfade ab
- [ ] Debug-Informationen sind aussagekräftig
- [ ] Problem kann reproduziert werden

### **Lösungs-Verifikation:**
- [ ] Problemursache ist eindeutig identifiziert
- [ ] Lösungsansatz ist technisch fundiert
- [ ] Implementierungsschritte sind klar definiert
- [ ] Erfolgskriterien sind messbar

---

## **RISIKO-ANALYSE**

### **Hohe Risiken:**
1. **Dateninkonsistenz**: Character wird gespeichert aber mit fehlerhaften Daten
2. **UI-State-Problem**: Daten werden geladen aber nicht angezeigt
3. **Navigation-Problem**: Falscher Screen wird angezeigt
4. **Async-Issue**: Race-Conditions beim Speichern/Laden

### **Mittlere Risiken:**
1. **Filter-Problem**: Character werden durch Filter ausgeschlossen
2. **Provider-Issue**: State-Management funktioniert nicht korrekt
3. **Cache-Problem**: Veraltete Daten werden angezeigt

### **Risikominderung:**
1. **Schrittweise Analyse**: Systematische Untersuchung jedes Layers
2. **Logging-Ausbau**: Umfassende Protokollierung
3. **Test-Isolation**: Unabhängige Tests für jede Komponente
4. **Fallback-Strategien**: Alternative Lösungsansätze

---

## **FALLBACK-STRATEGIE**

### **Wenn Datenbank-Problem:**
1. Datenbank-Schema überprüfen und reparieren
2. Migrationen implementieren
3. Datenkonsistenz wiederherstellen

### **Wenn UI-Problem:**
1. State-Management überarbeiten
2. UI-Refresh-Logik implementieren
3. Komponenten neuarchitekturieren

### **Wenn Navigation-Problem:**
1. Routing-Konfiguration korrigieren
2. Parameter-Übergabe reparieren
3. Screen-Implementierungen vereinheitlichen

---

## **SUCCESS METRICS**

### **Quantitative Metriken:**
- 100% Verifikations-Test-Coverage für kritische Pfade
- < 5 Sekunden für kompletten Test-Durchlauf
- 0 verbleibende kritische UI-Probleme
- 100% Reproduzierbarkeit des Problems

### **Qualitative Metriken:**
- Klare und eindeutige Problemidentifikation
- Praxisgerechte Lösungsansätze
- Umfassende Dokumentation
- Nachhaltige Test-Infrastruktur

### **Business Impact:**
- Heldenerstellung funktioniert zuverlässig
- Benutzer können Charaktere sehen und verwalten
- Kampagnen-Management ist vollständig nutzbar
- User Experience ist stabil und vorhersehbar

---

## **BESONDERE ANWEISUNGEN**

### **Fokus auf Verifikation:**
- Priorisiere "nachschauen ob es wirklich funktioniert"
- Implementiere systematische Tests statt Annahmen
- Dokumentiere jeden Schritt der Analyse

### **Pragmatischer Ansatz:**
- Nutze vorhandene `test_hero_creation.dart` als Basis
- Erweitere Tests um Lücken zu schließen
- Implementiere Debug-Outputs für bessere Nachverfolgung

### **User-Perspektive:**
- Simuliere完整的 Benutzer-Workflow
- Identifiziere pain points aus Benutzersicht
- Stelle sicher, dass Kernfunktionalität funktioniert

---

**WICHTIG**: Der Benutzer möchte konkret wissen, ob Helden wirklich erstellt werden und in der UI angezeigt werden. Konzentriere dich auf diese Verifikation!"
