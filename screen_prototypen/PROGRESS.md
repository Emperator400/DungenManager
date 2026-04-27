# Screen Prototype Progress

| Prototype | Flutter Screen | Status |
|---|---|---|
| `startseite.jsx` | `lib/screens/navigation/main_navigation_screen.dart` | ✅ Done |
| `charakter_editor.jsx` | `lib/screens/characters/character_editor_screen.dart` | ✅ Done |
| `ausruestungskammer.jsx` | `lib/screens/items/item_library_screen.dart` | ✅ Done |
| `lore_keeper.jsx` | `lib/screens/lore/lore_keeper_screen.dart` | ✅ Done |
| `bestiarium.jsx` | `lib/screens/bestiary/bestiary_screen.dart` | ✅ Done |
| `sound_bibliothek.jsx` | `lib/screens/audio/sound_library_screen.dart` | ✅ Done |
| `kampagnen_hub.jsx` | `lib/screens/campaign/campaign_selection_screen.dart` | ✅ Done |

## Notes
- `lore_keeper.jsx` required a fix: `MapLocation.name` → `MapLocation.mapId`
- `sound_bibliothek.jsx` includes real audio playback via `audioplayers` package
- `bestiarium.jsx` uses two-pane master-detail layout
- Flutter screen paths for `startseite`, `charakter_editor`, `ausruestungskammer` are approximate — correct if wrong
</thinking>
