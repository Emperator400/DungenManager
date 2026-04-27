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