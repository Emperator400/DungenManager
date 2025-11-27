enum EquipSlot {
  // Waffen
  mainHand,      // Haupthand (Schwert, Axt, etc.)
  offHand,       // Nebenhand (Schild, Dolch, Zweitwaffe)
  ranged,        // Fernkampfwaffe (Bogen, Armbrust)
  
  // Spell-Slots (neu)
  spellActive,      // Aktiver Spell (wie "gezogene Waffe")
  cantripReady,     // Cantrip-Slot (immer verfügbar)
  spellPrepared1, spellPrepared2, spellPrepared3, spellPrepared4, // Vorbereitete Spells
  
  // Rüstung
  head,          // Helm
  chest,         // Brustpanzer/Rüstung
  hands,         // Handschuhe
  feet,          // Stiefel
  cloak,         // Umhang
  
  // Accessoires
  ring1, ring2,  // Ringe
  amulet,        // Amulett/Halskette
  belt,          // Gürtel
}

// Extension für UI-Kompatibilität
extension EquipSlotExtension on EquipSlot {
  /// UI-Display-Name für den Slot
  String get displayName {
    switch (this) {
      case EquipSlot.mainHand:
        return 'Haupthand';
      case EquipSlot.offHand:
        return 'Nebenhand';
      case EquipSlot.ranged:
        return 'Fernkampf';
      case EquipSlot.spellActive:
        return 'Aktiver Spell';
      case EquipSlot.cantripReady:
        return 'Cantrip';
      case EquipSlot.spellPrepared1:
        return 'Vorbereiteter Spell 1';
      case EquipSlot.spellPrepared2:
        return 'Vorbereiteter Spell 2';
      case EquipSlot.spellPrepared3:
        return 'Vorbereiteter Spell 3';
      case EquipSlot.spellPrepared4:
        return 'Vorbereiteter Spell 4';
      case EquipSlot.head:
        return 'Kopf';
      case EquipSlot.chest:
        return 'Brust';
      case EquipSlot.hands:
        return 'Hände';
      case EquipSlot.feet:
        return 'Füße';
      case EquipSlot.cloak:
        return 'Umhang';
      case EquipSlot.ring1:
        return 'Ring 1';
      case EquipSlot.ring2:
        return 'Ring 2';
      case EquipSlot.amulet:
        return 'Amulett';
      case EquipSlot.belt:
        return 'Gürtel';
    }
  }

  /// Icon-Name für den Slot
  String get iconName {
    switch (this) {
      case EquipSlot.mainHand:
        return 'sword';
      case EquipSlot.offHand:
        return 'shield';
      case EquipSlot.ranged:
        return 'bow';
      case EquipSlot.spellActive:
        return 'magic_spell';
      case EquipSlot.cantripReady:
        return 'sparkles';
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
        return 'book';
      case EquipSlot.head:
        return 'helmet';
      case EquipSlot.chest:
        return 'armor';
      case EquipSlot.hands:
        return 'gloves';
      case EquipSlot.feet:
        return 'boots';
      case EquipSlot.cloak:
        return 'cloak';
      case EquipSlot.ring1:
      case EquipSlot.ring2:
        return 'ring';
      case EquipSlot.amulet:
        return 'necklace';
      case EquipSlot.belt:
        return 'belt';
    }
  }

  /// Erlaubte Item-Typen für diesen Slot
  List<String> get allowedItemTypes {
    switch (this) {
      case EquipSlot.mainHand:
        return ['Weapon', 'Tool'];
      case EquipSlot.offHand:
        return ['Shield', 'Weapon', 'Tool'];
      case EquipSlot.ranged:
        return ['Weapon', 'Ammunition'];
      case EquipSlot.spellActive:
      case EquipSlot.cantripReady:
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
        return ['Spell', 'Scroll'];
      case EquipSlot.head:
        return ['Armor', 'Helmet', 'Clothing'];
      case EquipSlot.chest:
        return ['Armor', 'Clothing', 'Robe'];
      case EquipSlot.hands:
        return ['Armor', 'Gloves', 'Clothing'];
      case EquipSlot.feet:
        return ['Armor', 'Boots', 'Clothing'];
      case EquipSlot.cloak:
        return ['Cloak', 'Clothing'];
      case EquipSlot.ring1:
      case EquipSlot.ring2:
        return ['Ring', 'Accessory'];
      case EquipSlot.amulet:
        return ['Amulet', 'Necklace', 'Accessory'];
      case EquipSlot.belt:
        return ['Belt', 'Accessory'];
    }
  }

  /// Konvertiere zu JSON-String für Datenbank
  String toJson() {
    return name; // Gibt nur 'mainHand', 'offHand', etc. zurück
  }
}

/// Statische Methoden für EquipSlot-Serialisierung
extension EquipSlotSerialization on EquipSlot {
  /// Erstelle Enum aus JSON-String
  static EquipSlot? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return EquipSlot.values.firstWhere((slot) => slot.name == json);
    } catch (e) {
      return null;
    }
  }
}
