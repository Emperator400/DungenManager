Du bist der `UI-Theme-Specialist`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `lib/theme/dnd_theme.dart` für das bestehende Design-System.
3. Lies `lib/widgets/campaign/enhanced_campaign_filter_chips_widget.dart` für das aktuelle Widget.

**Dein spezifischer Task:**
Optimiere die Filter-Chips in der Kampagnen-Startseite im Spotify-Stil - kompakt, modern und platzsparend. Die aktuellen Filter-Chips sind zu groß und beeinträchtigen die Übersichtlichkeit.

**Analyse:**
- Die aktuellen Filter-Chips verwenden Standard-Flutter `FilterChip`-Komponenten
- Sie nehmen zu viel vertikalen und horizontalen Platz ein
- Das Layout ist nicht optimal für die mobile Ansicht

**Dein Protokoll (A-P-B-V-L):**

**A - Analyse:**
1. Untersuche das aktuelle `EnhancedCampaignFilterChipsWidget`
2. Identifiziere die drei Chip-Typen: Filter-Chips, Sort-Chips, Active Filter Chips
3. Analysiere das bestehende DnD-Theme für Farbschemata
4. Berücksichtige die Touch-Zielgrößen (mindestens 44px für Accessibility)

**P - Plan (mit Diffs + Verifikation):**
1. **Spotify-Style Merkmale implementieren:**
   - Reduzierte Höhe (28-32px statt Standard)
   - Kleinere Schriftgröße (12-13px)
   - Engere Abstände (horizontal: 6px, vertical: 3px)
   - Abrundung mit größerem radius (16px)
   - Subtile Hintergrundfarben mit starkem Kontrast für aktive Zustände

2. **Layout-Optimierungen:**
   - Reduzierte padding in Wrap-Layouts
   - Kompaktere Vertikalabstände zwischen Filter-Gruppen
   - Optimiertes Card-Layout mit weniger padding

3. **Visuelle Verbesserungen:**
   - Modernere Farbverläufe für aktive Chips
   - Bessere visuelle Hierarchie
   - Konsistente Hover/Press-Effekte

**B - Bestätigung (User-Gate):**
Präsentiere deine geplanten Änderungen mit visuellen Beispielen vor der Implementierung.

**V - Verifikation:**
1. Teste die Touch-Zielgrößen (>44px)
2. Überprüfe die Lesbarkeit auf verschiedenen Bildschirmgrößen
3. Stelle sicher, dass alle Filter-Funktionen erhalten bleiben
4. Teste die Performance bei vielen Filter-Chips

**L - Lernen (Vorschlag für Bug-Archiv):**
Dokumentiere die Spotify-Style Design-Patterns für zukünftige Chip-Implementierungen.

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast.

**Spezifische Anforderungen für Spotify-Style:**
- Höhe: 28-32px
- Schrift: 12px,.medium weight
- Padding: horizontal 12px, vertical 6px
- Border-radius: 16px
- spacing im Wrap: 6px horizontal, 3px vertical
- Aktive Zustände: kräftige Farben mit leichtem Schatten
- Inaktive Zustände: sehr helle Hintergründe (opacity 0.08)
