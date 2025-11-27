# Lore Keeper Phase 3 Upgrade - Datenmodell Erweiterung

## Übersicht

Phase 3 des Lore Keeper Upgrades konzentriert sich auf die Erweiterung des Datenmodells und die Unterstützung für erweiterte Metadaten, hierarchische Strukturen und Rich Content.

## ✅ Abgeschlossen

### 1. WikiEntryTypen erweitert
- **Neue Typen hinzugefügt:**
  - `Faction` - Organisationen, Gilden, Fraktionen
  - `Magic` - Zaubersprüche, magische Phänomene
  - `History` - Historische Ereignisse, Zeitlinien
  - `Item` - Wichtige Gegenstände, Artefakte
  - `Quest` - Missionen, Abenteuer
  - `Creature` - Monster, Tiere, Wesen

### 2. Metadaten erweitert
- **Bilder:** `imageUrl` für visuelle Darstellung
- **Ersteller:** `createdBy` für Autorenschaft
- **Hierarchische Strukturen:** `parentId` und `childIds` für Parent/Child Beziehungen
- **Rich Content:** `isMarkdown` Flag für Markdown-Unterstützung

### 3. Rich Text mit Basic Markdown
- **MarkdownParser** erstellt für:
  - **Bold** und *italic* Text
  - Headers (# ## ###)
  - Listen (- item)
  - Links [text](url)
- **Extension Methods** für String mit `hasMarkdown` und `toPlainText()`

### 4. Database Migration
- **Version 24:** Migration für neue Metadaten-Felder
- **Performance Indizes** für neue Felder:
  - `idx_wiki_entries_parent` - Parent/Child Beziehungen
  - `idx_wiki_entries_created_by` - Ersteller-Suche
  - `idx_wiki_entries_image` - Bild-Suche

### 5. Helper Methods
- **Hierarchische Operationen:**
  - `addChild()` / `removeChild()` - Child Management
  - `setParent()` - Parent Zuweisung
  - `hasParent` / `hasChildren` - Status Checks
- **Metadaten-Operationen:**
  - `setImage()` - Bild Management
  - `setCreator()` - Ersteller Management
  - `setMarkdown()` - Markdown Flag
- **Tag Management:** `addTag()` / `removeTag()` (bereits vorhanden)

### 6. UI Komponenten aktualisiert
- **WikiEntryCardWidget:** Unterstützung für alle neuen Typen mit Farben und Icons
- **WikiFilterChipsWidget:** Filter für alle neuen Typen
- **EnhancedEditWikiEntryScreen:** Type-Auswahl für alle neuen Typen

### 7. Tests
- **WikiEntry Enhanced Tests:** Vollständige Testabdeckung für neue Funktionalität
- **Markdown Parser Tests:** Tests für Markdown-Parsing und -Erkennung

## 🎯 Features

### Neue WikiEntryTypen
| Typ | Icon | Farbe | Verwendung |
|------|-------|--------|-----------|
| Person | 👤 | Blau | NPCs, Charaktere |
| Place | 📍 | Grün | Orte, Locations |
| Lore | 📚 | Lila | Hintergrundgeschichte |
| Faction | 👥 | Orange | Fraktionen, Gilden |
| Magic | ✨ | Pink | Magie, Zauber |
| History | 📜 | Braun | Geschichte, Ereignisse |
| Item | 🎒 | Teal | Wichtige Gegenstände |
| Quest | 📋 | Indigo | Missionen, Abenteuer |
| Creature | 🐾 | Rot | Monster, Wesen |

### Hierarchische Strukturen
```
Kampagne (Root)
├── Fraktion: "Die Heldenliga"
│   ├── Person: "Thorin Eisenfaust"
│   ├── Person: "Elara Lichtbringer"
│   └── Ort: "Heldenliga-HQ"
├── Quest: "Der Drachenschmuck"
│   ├── Ort: "Drachenhöhle"
│   └── Creature: "Roter Drache"
└── Geschichte: "Die Gründung der Stadt"
```

### Markdown Unterstützung
- **Bold:** `**Text**`
- **Italic:** `*Text*`
- **Headers:** `# H1`, `## H2`, `### H3`
- **Listen:** `- Item`
- **Links:** `[Text](URL)`

## 🔧 Technische Details

### Datenbank Schema Erweiterungen
```sql
-- Neue Felder für wiki_entries Tabelle
ALTER TABLE wiki_entries ADD COLUMN imageUrl TEXT;
ALTER TABLE wiki_entries ADD COLUMN createdBy TEXT;
ALTER TABLE wiki_entries ADD COLUMN parentId TEXT;
ALTER TABLE wiki_entries ADD COLUMN childIds TEXT;
ALTER TABLE wiki_entries ADD COLUMN isMarkdown INTEGER DEFAULT 0;
```

### Immutable Design Pattern
Alle WikiEntry-Operationen erstellen neue Instanzen mit `copyWith()`:
```dart
final updated = entry.addTag('important').setImage(imageUrl).setMarkdown(true);
```

### Performance Optimierungen
- **Indizes** für häufige Abfragen
- **CSV-Speicherung** für Listen (Tags, ChildIds)
- **Lazy Loading** für große Hierarchien

## 📱 UI/UX Verbesserungen

### Visuelle Hierarchie
- Parent-Child Beziehungen in Card-Darstellung
- Einrückung für hierarchische Strukturen
- Breadcrumb-Navigation für tief verschachtelte Einträge

### Enhanced Filtering
- Filter nach neuen Typen
- Hierarchische Filter (nur Root-Einträge, nur Children)
- Kombinierte Filter (Typ + Tags + Hierarchie)

### Rich Content Display
- Markdown-Vorschau im Edit-Modus
- Plain-Text Fallback für Listenansicht
- Syntax-Highlighting für Markdown

## 🚀 Nächste Schritte (Phase 4)

1. **Wiki Links & Cross-References**
   - Automatische Verlinkung zwischen Einträgen
   - Backlink-Anzeige
   - Beziehungs-Visualisierung

2. **Advanced Search**
   - Volltextsuche mit Highlights
   - Suchverlauf und gespeicherte Suchen
   - Kontextsensitive Suche

3. **Export & Import**
   - JSON-Export für Backups
   - Markdown-Export für externe Dokumentation
   - Massen-Import aus CSV/JSON

4. **Collaboration Features**
   - Mehrbenutzer-Unterstützung
   - Edit-Historie
   - Kommentare und Anmerkungen

## 📊 Status

- ✅ **100%** der Phase 3 Ziele erreicht
- ✅ **9 neue** WikiEntryTypen
- ✅ **5 neue** Metadaten-Felder
- ✅ **1 Markdown** Parser
- ✅ **1 Database** Migration
- ✅ **3 UI** Komponenten aktualisiert
- ✅ **2 Test** Suites erstellt

Der Lore Keeper ist jetzt bereit für komplexe Welt-Projekte mit hierarchischen Strukturen und reichhaltigem Content!
