# Playtest-Feedback

## Offen

1. **Ort-Beschreibung vollständig lesbar** — Im Karten-Tab (rechtes Detail-Panel) wird `ort.description` mit `maxLines: 3` abgeschnitten. Soll immer vollständig angezeigt werden (scrollbar wenn nötig).
   - Datei: `lib/screens/campaign/dm_buch_screen.dart` ~Zeile 1625–1631
   - Fix: `maxLines` entfernen, ggf. in scrollbaren Container einbetten

