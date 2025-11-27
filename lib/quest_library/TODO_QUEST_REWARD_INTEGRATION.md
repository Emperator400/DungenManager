# TODO: Quest Reward System Integration

## 🎯 **Ziel**
Integration des Item-Systems in Quest-Belohnungen für:
- **Gold** - Münzen/Währung
- **XP** - Erfahrungspunkte für Spieler
- **Items** - Belohnungs-Items aus der Item-Bibliothek
- **Monster/NPCs** - Gegner und Verbündete für Quests

---

## 📋 **Haupt-Aufgaben**

### **Phase 1: Quest Model Erweiterung**
- [ ] **QuestReward Modell erstellen**
  ```dart
  class QuestReward {
    String id;
    RewardType type; // GOLD, XP, ITEM
    int? goldAmount;
    int? xpAmount;
    String? itemId; // Reference to Item
    int? quantity;
    String? description;
  }
  ```
- [ ] **Quest Model erweitern**
  - `List<QuestReward> rewards` statt `List<String> rewards`
  - `List<String> monsterIds` für Quest-Gegner
  - `List<String> npcIds` für Quest-NPCs

### **Phase 2: Datenbank Integration**
- [ ] **Datenbank-Tabelle erstellen**
  ```sql
  CREATE TABLE quest_rewards (
    id TEXT PRIMARY KEY,
    quest_id TEXT,
    reward_type TEXT,
    gold_amount INTEGER,
    xp_amount INTEGER,
    item_id TEXT,
    quantity INTEGER,
    description TEXT,
    FOREIGN KEY (quest_id) REFERENCES quests (id),
    FOREIGN KEY (item_id) REFERENCES items (id)
  );
  ```
- [ ] **Quest-Monster/NPC Beziehungstabelle**
  ```sql
  CREATE TABLE quest_monsters (
    quest_id TEXT,
    monster_id TEXT,
    role TEXT, // ENEMY, ALLY, NEUTRAL
    FOREIGN KEY (quest_id) REFERENCES quests (id),
    FOREIGN KEY (monster_id) REFERENCES monsters (id)
  );
  ```

### **Phase 3: UI Komponenten**
- [ ] **QuestRewardWidget erstellen**
  - Anzeige von Gold, XP, Items
  - Icons für jeden Reward-Typ
  - Editier-Funktion

- [ ] **RewardSelectorWidget**
  - Auswahl zwischen Gold, XP, Item
  - Item-Auswahl aus Item-Bibliothek
  - Mengen-Eingabe

- [ ] **MonsterSelectorWidget**
  - Monster aus Bestiary auswählen
  - Rolle zuweisen (Gegner/Verbündeter)
  - Anzahl/Stärke definieren

### **Phase 4: Enhanced Edit Screen Integration**
- [ ] **EnhancedEditQuestScreen erweitern**
  - Neuer Abschnitt "Belohnungen" mit RewardSelector
  - Neuer Abschnitt "Monster & NPCs" mit MonsterSelector
  - Validierung für Rewards

### **Phase 5: Quest Card Widget Update**
- [ ] **QuestCardWidget erweitern**
  - Anzeige von Gold/XP Rewards
  - Item-Icons anzeigen
  - Monster-Indikatoren

---

## 🔧 **Technische Details**

### **RewardType Enum**
```dart
enum RewardType {
  gold,
  xp,
  item,
}
```

### **QuestReward Helper Methods**
```dart
class QuestReward {
  // Convenience getters
  String get displayName => // ...
  IconData get icon => // ...
  String get formattedValue => // "100 Gold", "500 XP", "Schwert x2"
}
```

### **Integration Points**
1. **Quest Creation** - Rewards hinzufügen/bearbeiten
2. **Quest Display** - Rewards in Cards anzeigen
3. **Quest Completion** - Rewards an Spieler verteilen
4. **Campaign Management** - Quest-Monster/NPCs verwalten

---

## 🎨 **UI Design Anforderungen**

### **Reward Display**
- Gold: 💰 Gold-Icon mit Menge
- XP: ⭐ Stern-Icon mit Menge  
- Items: 🎁 Item-Icon mit Namen und Menge
- Monster: 👹/🧙 Monster/NPC-Icons mit Rollen

### **Reward Editor**
- Tab-Interface: Gold | XP | Items | Monster
- Drag & Drop für Reihenfolge
- Validierung und Fehlermeldungen

---

## 🔄 **Arbeitsablauf**

1. **Quest erstellen/bearbeiten**
   - Rewards über Selector hinzufügen
   - Monster/NPCs zuweisen
2. **Quest speichern**
   - Rewards in Datenbank speichern
   - Bezieungen zu Items/Monstern herstellen
3. **Quest anzeigen**
   - Rich Card mit allen Rewards
   - Monster/NPC-Indikatoren
4. **Quest abschließen**
   - Rewards an Spieler vergeben
   - Monster als besiegte markieren

---

## 📊 **Prioritäten**

### **High Priority (MVP)**
- [ ] Gold Rewards
- [ ] XP Rewards  
- [ ] Basic Item Rewards
- [ ] Quest Card Display

### **Medium Priority**
- [ ] Monster/NPC Integration
- [ ] Advanced Item Selection
- [ ] Reward History

### **Low Priority**
- [ ] Random Rewards
- [ ] Conditional Rewards
- [ ] Reward Templates

---

## 🧪 **Testing Requirements**

- [ ] Reward Creation & Editing
- [ ] Quest Card Display mit Rewards
- [ ] Database Integration
- [ ] Item/Monster Linking
- [ ] Edge Cases (leere Rewards, ungültige Items)

---

## 📝 **Notizen**

- Items müssen aus der bestehenden Item-Bibliothek kommen
- Monster aus dem Bestiary integrieren
- Rewards sollten sowohl für individuelle Spieler als auch für Party möglich sein
- Consider future: Conditional Rewards basierend auf Spieler-Entscheidungen
