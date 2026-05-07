Wir möchten die gesamte UI des DungenManager Projekts 
nach einer neuen Vision umgestalten. Hier ist die 
vollständige Beschreibung:

── DESIGN SYSTEM ──────────────────────────────────────

Ästhetik: Modern, clean, professionell (wie Linear/Notion)
Schrift: System-Font (-apple-system, SF Pro, Helvetica Neue)

Light Mode Farben:
- bg: #f7f7f5
- bgPanel: #ffffff
- bgHover: #f0f0ed
- bgActive: #eeecea
- border: #e4e4e0
- borderStrong: #d0d0ca
- text: #1a1a18
- textMid: #6b6b66
- textSoft: #9f9f98
- accent: #2f6feb
- green: #1a7f4b
- amber: #b45309
- red: #c93a3a

Dark Mode Farben:
- bg: #111110
- bgPanel: #1a1a18
- bgHover: #232320
- bgActive: #2a2a27
- border: #2e2e2b
- text: #edede8
- textMid: #8a8a82
- accent: #4f8ef7
- green: #34c471
- amber: #d4890a
- red: #e05555

Dark/Light Toggle Button oben rechts in der TopBar.
Alle Screens müssen beide Themes vollständig unterstützen.

── KEINE EMOJIS ───────────────────────────────────────

Emojis komplett entfernen. Ersetzen durch:
- SVG Icons (stroke-basiert, 1.5px, rounded)
- Farbige Punkte für Typ-Kategorien
- Status Badges mit Farbe + Text

── KOMPONENTEN SYSTEM ─────────────────────────────────

Alle wiederverwendbaren Komponenten sollen ein 
einheitliches Design-System nutzen:

StatusBadge: 
- done → grün
- open/offen → amber  
- aktiv → accent blau
- failed/abandoned → rot

TypeTag (für Ort-Typen, Kreatur-Typen etc.):
- Farbiger Punkt + Text + farbiger Hintergrund
- Gebäude: blau
- Stadt/NPC: grün  
- Dungeon: lila
- Wildnis: amber

Cards:
- Weißer/dunkler Hintergrund
- 1px Border
- 6-8px border-radius
- Hover-State mit bgHover
- Kein Schatten — nur Border

Buttons:
- Primary: accent Hintergrund, weißer Text
- Secondary: bgPanel + Border
- Ghost: transparent + hover bgHover
- Kein border-radius > 8px

── HAUPT-LAYOUT: DAS DM-BUCH ──────────────────────────

Das zentrale Layout ist ein aufgeschlagenes Buch 
mit zwei Seiten:

LINKE SEITE (42% Breite):
- Tabs: Karte | Quests
- Scrollbarer Inhalt
- Fix unten: Audio-Mixer (immer sichtbar, nie versteckt)

RECHTE SEITE (flex: 1):
- Zeigt den aktuell ausgewählten Ort
- Header mit Ort-Name, Type-Tag, Szenen-Fortschritt
- Gedächtnis-Banner wenn Ort bereits besucht wurde
- Szenen-Liste (klickbar, expandiert bei Auswahl)
- NPCs, Encounter, Items des Ortes
- Im Live-Modus: Notizfeld + Schnell-Aktionen

TOPBAR:
- Links: Logo + Kampagnen-Name
- Mitte: Toggle Vorbereitung | Live
- Rechts: Aktiver Ort + Dark/Light Toggle Button

── ORTS-SYSTEM ────────────────────────────────────────

Jeder Ort ist die kleinste Einheit (ersetzt Session):
- Kampagne → Orte → Szenen
- Orte haben ein "Gedächtnis" (was beim letzten 
  Besuch passiert ist)
- Karte zeigt alle Orte mit farbigen Punkten als Pins
- Klick auf Ort → öffnet Ort auf der rechten Seite
- Grüner Punkt = Ort bereits besucht
- Amber Icon = Ort hat Gedächtnis

── AUDIO MIXER ────────────────────────────────────────

Immer fix unten auf der linken Seite sichtbar:
- Toggle Switch (an/aus) pro Track
- Label (Umgebung, Musik, Kampf, Regen)
- Klickbarer Lautstärke-Balken
- Prozentzahl rechts

── VORGEHEN ───────────────────────────────────────────

Bitte arbeite in dieser Reihenfolge:

1. Erstelle ein zentrales theme.dart mit allen 
   Farben für Light und Dark Mode als ThemeData

2. Erstelle wiederverwendbare Basis-Widgets:
   - StatusBadge
   - TypeTag  
   - AppCard (Card-Wrapper)
   - AppButton (primary/secondary/ghost)

3. Passe die Navigation an das neue Design an

4. Überarbeite Screen für Screen in dieser Reihenfolge:
   - Active Session Screen (das DM-Buch Layout)
   - Bestiary Screen
   - Campaign Screen
   - Quest Screen
   - Dann alle weiteren Screens

Nach jedem Screen: kurz zeigen was geändert wurde 
und auf meine Bestätigung warten bevor der nächste 
Screen überarbeitet wird.

Wichtig: Behalte alle bestehenden Funktionen. 
Es geht nur um das visuelle Design, nicht um 
Funktionalität.