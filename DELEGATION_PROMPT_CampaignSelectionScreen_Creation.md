Du bist der Campaign Manager Specialist.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für bekannte Fehlermuster
2. Lies `lib/models/campaign.dart` für Kampagnen-Datenstruktur
3. Lies `lib/viewmodels/campaign_viewmodel.dart` für verfügbare Funktionen
4. Lies `lib/widgets/campaign/enhanced_campaign_card_widget.dart` für existierende UI-Komponenten

**Dein spezifischer Task:**
Erstelle eine neue `CampaignSelectionScreen` als Startseite der Anwendung mit:

1. **Kampagnen-Liste mit Enhanced Campaign Cards**
   - Zeige alle verfügbaren Kampagnen
   - Verwende existierende `EnhancedCampaignCardWidget`
   - Zeige wichtige Informationen: Name, Typ, letzte Aktivität, Anzahl Sessions/Charaktere

2. **Quick Actions**
   - "Neue Kampagne erstellen" Button
   - "Kampagne importieren" Button
   - Beide sollten zu den entsprechenden Edit-Screens führen

3. **Suche und Filter-Funktion**
   - SearchBar für Kampagnen-Suche
   - Filter-Chips für Kampagnen-Typen (Homebrew, Module)
   - Verwende existierende `EnhancedCampaignFilterChipsWidget`

4. **Letzte Aktivitäten pro Kampagne**
   - Zeige zuletzt bearbeitete Sessions
   - Zeige kürzlich hinzugefügte Charaktere/Quests
   - Datum der letzten Aktivität

5. **Navigation zur kampagnenspezifischen Hauptseite**
   - Bei Klick auf Kampagne → `EnhancedMainNavigationScreen` mit Kampagnen-Context
   - Übergabe der ausgewählten Kampagne als Parameter

**Technische Anforderungen:**
- Neue Datei: `lib/screens/campaign_selection_screen.dart`
- Verwende `ChangeNotifierProvider` mit `CampaignViewModel`
- Konsistentes DnD Theme Design
- Responsive Layout für verschiedene Bildschirmgrößen
- Lade-States und Fehlerbehandlung

**Dein Protokoll (A-P-B-V-L):**

**Analyse:**
- Existierende Kampagnen-Components und Navigation analysieren
- Datenstruktur von Campaign Modell verstehen
- Verfügbare Funktionen im CampaignViewModel prüfen

**Plan (mit Diffs + Verifikation):**
- Screen-Design mit allen required Components
- Navigation-Flow zur kampagnenspezifischen Hauptseite
- Integration mit existierenden ViewModels und Services

**Bestätigung (User-Gate):**
- Design-Entscheidungen vor der Umsetzung bestätigen
- Navigation-Flow validieren

**Verifikation:**
- Kompilierung prüfen
- Navigation testen
- UI-Responsiveness validieren

**Lernen:**
- Best Practices für Kampagnen-Management dokumentieren
- Erkenntnisse im BUG_ARCHIVE eintragen

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du feststellst, dass das Problem tieferliegt (z.B. Datenmodell-Anpassungen notwendig, Missing Services):
1. **STOPPE.** Schreibe keinen Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erwartetes Ergebnis:**
Eine voll funktionsfähige `CampaignSelectionScreen` die als neue Startseite dient und alle Anforderungen erfüllt. Der Screen sollte nahtlos in die existierende Architektur integriert sein und den Grundstein für die kampagnen-zentrierte Navigation legen.
