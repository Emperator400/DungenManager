# 🚀 Agenten Access Guide - DungenManager Integrated Delegation System

## 📋 Übersicht aller verfügbaren Agenten

### **🔧 Core System Agenten**
- **`generalist_agent`** - Dateiverwaltung, Dokumentation, übergreifende Koordination
- **`TPL_specialist`** - Technical Project Lead, Gesamtverantwortung

### **🏗️ Backend & Datenbank Agenten**
- **`database_architect_specialist`** - Datenbank-Architektur, Schema-Design
- **`database_error_specialist`** - Datenbank-Fehlerbehandlung, Migrationen
- **`async_state_management_specialist`** - Async State Management, Performance
- **`data_parsing_validation_specialist`** - Daten-Parsing, Validierung, JSON/XML

### **🎨 Frontend & UI Agenten**
- **`ui_error_handling_specialist`** - UI-Fehlerbehandlung, User Experience
- **`performance_error_specialist`** - Performance-Optimierung, Ladezeiten
- **`ui_theme_specialist`** - Theme Systeme, Design Systeme, UI Components

### **🎮 D&D Domain Spezialisten**
- **`character_editor_specialist`** - Character Editor, Inventory Management
- **`quest_library_specialist`** - Quest Management, Reward Integration
- **`sound_audio_specialist`** - Audio Systeme, Sound Management
- **`wiki_lore_keeper_specialist`** - Wiki Systeme, Lore Management
- **`campaign_manager_specialist`** - Campaign Management, Session Koordination
- **`bestiary_monster_specialist`** - Monster Management, Creature Data

### **🔍 Debugging & Qualität Agenten**
- **`debugging_error_specialist`** - Allgemeines Debugging, Fehleranalyse
- **`testing_quality_specialist`** - Test-Strategien, Qualitätssicherung

### **🌐 Integration & Externe Systeme**
- **`mcp_integration_specialist`** - MCP Integration, externe APIs

---

## 🎯 Wie Agenten richtig nutzen

### **1. Direkte Adressierung**
```
@character_editor_specialist Bitte analysiere das Character Editor Widget und optimiere die Performance
```

### **2. Smart-Routing (automatisch)**
Das System wählt automatisch den passendsten Spezialisten basierend auf:
- **Task-Komplexität**
- **Domain-Relevanz**
- **Konfidenz-Level** (70-98%)

### **3. Eskalations-Ketten**
```
character_editor_specialist → ui_error_handling_specialist → performance_error_specialist → debugging_error_specialist
```

---

## 🔄 Standardisiertes A-P-B-V-L Protokoll

Alle Agenten folgen diesem Workflow:

### **A - Analyse**
- Kontext-Laden aus relevanten Dateien
- Problem-Analyse im Fachgebiet
- Identifikation von Dependencies

### **B - Bestätigung**
- Präsentation des Lösungsplans
- User-Gate vor Implementierung
- Explizite Freigabe einholen

### **V - Verifikation**
- Präzise Implementierung
- Einhaltung aller Standards
- Quality Checks

### **L - Lernen**
- Dokumentation für BUG_ARCHIVE.md
- Verbesserungsvorschläge
- Wissens-Update

---

## 🚨 Eskalations-Protokoll

Wenn ein Agent einen Task nicht lösen kann:

### **Syntax**
```
[ESKALATION]

**Problem-Typ:** [Kategorie]
**Fachgebiet:** [aktuelles Gebiet]
**Benötigter Spezialist:** [empfohlener Agent]
**Problem-Beschreibung:** [präzise Beschreibung]
**Kontext-Transfer:** [wichtige Informationen]
```

### **Beispiel**
```
[ESKALATION]

**Problem-Typ:** Performance-Problem
**Fachgebiet:** Character Editor
**Benötigter Spezialist:** performance_error_specialist
**Problem-Beschreibung:** Character Editor lädt 5+ Sekunden bei großen Inventaren
**Kontext-Transfer:** Character-Model hat 1000+ Items, UI friert ein beim Scrollen
```

---

## 📊 Agent-spezifische Kontexte

### **Jeder Agent hat definierte:**
- **Pflicht-Kontext-Dateien** (immer geladen)
- **Optional-Kontext-Dateien** (je nach Task)
- **Domain-spezifische Erfolgskriterien**
- **Fallback-Agenten** bei Eskalation

### **Beispiel: character_editor_specialist**
```markdown
**Pflicht-Kontext:**
- BUG_ARCHIVE.md
- AI_CONSTITUTION.md
- lib/widgets/character_editor/README_INVENTORY_REDESIGN.md
- lib/models/player_character.dart

**Erfolgskriterien:**
- Character-Editor Widgets wiederverwendbar
- Inventory-Management performant
- Hotbar-System supports Drag-and-Drop
```

---

## 🎯 Best Practices für Agenten-Nutzung

### **1. Task-Beschreibung**
- ✅ Präzise und spezifisch
- ✅ Domain klar zugeordnet
- ✅ Erfolgskriterien definiert

### **2. Kontext-Bereitstellung**
- ✅ Relevante Dateien erwähnen
- ✅ Fehlermeldungen inkludieren
- ✅ Gewünschtes Ergebnis beschreiben

### **3. Eskalations-Management**
- ✅ Spezialisten direkt adressieren
- ✅ Bei Fehlern Eskalations-Protokoll nutzen
- ✅ Kontext-Transfer sicherstellen

---

## 🔧 Fallback-System

### **Level 0: Generalist**
- Bei unklaren Task-Zuordnungen
- Konfidenz: 70-85%

### **Level 1: Spezialisten**
- Domain-spezifische Experten
- Konfidenz: 85-95%

### **Level 2: TPL Specialist**
- Bei kritischen Systemproblemen
- Konfidenz: 95-98%

---

## 📱 Quick Reference

| **Domain** | **Agent** | **Konfidenz** | **Fallback** |
|------------|------------|----------------|--------------|
| Character Editor | `character_editor_specialist` | 85-95% | `frontend_agent` |
| Quest System | `quest_library_specialist` | 85-95% | `frontend_agent` |
| Audio/Sound | `sound_audio_specialist` | 85-95% | `frontend_agent` |
| Wiki/Lore | `wiki_lore_keeper_specialist` | 85-95% | `frontend_agent` |
| Campaign | `campaign_manager_specialist` | 85-95% | `frontend_agent` |
| Monster | `bestiary_monster_specialist` | 85-95% | `frontend_agent` |
| Database | `database_error_specialist` | 85-95% | `backend_agent` |
| Performance | `performance_error_specialist` | 90-98% | `backend_agent` |
| Testing | `testing_quality_specialist` | 90-98% | `backend_agent` |
| MCP Integration | `mcp_integration_specialist` | 90-98% | `backend_agent` |
| General Tasks | `generalist_agent` | 70-85% | `TPL_specialist` |

---

## 🚀 Schnellstart

### **Für schnelle Hilfe:**
1. **`@agent_name`** - Direkte Adressierung
2. **[ESKALATION]** - Bei Problemen mit aktuellem Agent
3. **"Hilfe bei [Domain]"** - Smart-Routing aktivieren

### **Beispiele:**
```
@character_editor_specialist Fixe das Inventory Sorting Bug

@quest_library_specialist Implementiere Quest Reward System

[ESKALATION] Performance-Problem im Character Editor
```

**Das System ist bereit für produktiven Einsatz! 🎉**
