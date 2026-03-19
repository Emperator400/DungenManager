// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../models/equip_slot.dart';
import '../database/repositories/inventory_item_model_repository.dart';
import '../database/repositories/item_model_repository.dart';
import '../database/core/database_connection.dart';

/// Ergebnis der AC-Berechnung
class ArmorClassResult {
  final int totalAc;
  final int baseAc;
  final int dexModifier;
  final int armorBonus;
  final int shieldBonus;
  final String? armorName;
  final String? shieldName;
  final String formula;

  const ArmorClassResult({
    required this.totalAc,
    required this.baseAc,
    required this.dexModifier,
    required this.armorBonus,
    required this.shieldBonus,
    this.armorName,
    this.shieldName,
    required this.formula,
  });

  /// Gibt zurück ob Rüstung getragen wird
  bool get hasArmor => armorBonus > 0;

  /// Gibt zurück ob Schild geführt wird
  bool get hasShield => shieldBonus > 0;

  @override
  String toString() => 'AC: $totalAc ($formula)';
}

/// Service für die Berechnung der Rüstungsklasse (Armor Class)
/// 
/// Implementiert D&D 5e AC-Berechnungsregeln:
/// - Basis-AC: 10 + Dexterity Modifier
/// - Rüstung: Ersetzt Basis-AC oder addiert Bonus
/// - Schild: +2 AC (oder Item-spezifischer Wert)
class ArmorCalculationService {
  final InventoryItemModelRepository _inventoryRepository;
  final ItemModelRepository _itemRepository;

  ArmorCalculationService({
    InventoryItemModelRepository? inventoryRepository,
    ItemModelRepository? itemRepository,
  }) : _inventoryRepository = inventoryRepository ?? InventoryItemModelRepository(DatabaseConnection.instance),
       _itemRepository = itemRepository ?? ItemModelRepository(DatabaseConnection.instance);

  /// Berechnet die effektive Rüstungsklasse für einen Character
  /// 
  /// [characterId] - Die ID des Characters (PlayerCharacter oder Creature)
  /// [dexterity] - Der Dexterity-Wert des Characters
  /// [baseArmorClass] - Optional: Die Basis-AC des Characters (Standard: 10)
  /// 
  /// Returns ArmorClassResult mit detaillierten Informationen
  Future<ArmorClassResult> calculateArmorClass({
    required String characterId,
    required int dexterity,
    int baseArmorClass = 10,
  }) async {
    try {
      print('🛡️ [ArmorCalculationService] Berechne AC für Character: $characterId');
      print('🛡️ [ArmorCalculationService] Dexterity: $dexterity, Basis-AC: $baseArmorClass');

      // Dexterity Modifier berechnen
      final dexModifier = _calculateModifier(dexterity);
      print('🛡️ [ArmorCalculationService] Dexterity Modifier: $dexModifier');

      // Ausgerüstete Items laden
      final equippedItems = await _loadEquippedItems(characterId);
      print('🛡️ [ArmorCalculationService] ${equippedItems.length} ausgerüstete Items gefunden');

      // Rüstung und Schild extrahieren
      final armorData = _findArmorInSlot(equippedItems, EquipSlot.chest);
      final shieldData = _findShieldInSlot(equippedItems, EquipSlot.offHand);

      int armorBonus = 0;
      int shieldBonus = 0;
      String? armorName;
      String? shieldName;
      int effectiveBaseAc = baseArmorClass;
      bool armorReplacesBase = false;

      // Rüstung verarbeiten
      if (armorData != null) {
        final armorItem = armorData.$2;
        final acValue = _parseAcFormula(armorItem.acFormula);
        
        if (acValue != null && acValue > 0) {
          // Prüfen ob Rüstung die Basis ersetzt (Heavy Armor in D&D 5e)
          // Heavy Armor: AC ist fest, kein Dex-Bonus
          // Medium Armor: AC + Dex (max +2)
          // Light Armor: AC + Dex
          
          if (_isHeavyArmor(armorItem)) {
            // Heavy Armor: Ersetzt Basis-AC komplett, kein Dex-Modifier
            effectiveBaseAc = acValue;
            armorReplacesBase = true;
            armorBonus = 0; // AC ist bereits in effectiveBaseAc
          } else if (_isMediumArmor(armorItem)) {
            // Medium Armor: AC + Dex (max +2)
            effectiveBaseAc = acValue;
            armorBonus = 0;
            armorReplacesBase = true;
            // Dex Modifier ist bereits limitiert
          } else {
            // Light Armor oder sonstige: AC + voller Dex
            effectiveBaseAc = acValue;
            armorBonus = 0;
            armorReplacesBase = true;
          }
          
          armorName = armorItem.name;
          print('🛡️ [ArmorCalculationService] Rüstung: ${armorItem.name}, AC: $acValue');
        }
      }

      // Schild verarbeiten
      if (shieldData != null) {
        final shieldItem = shieldData.$2;
        final acValue = _parseAcFormula(shieldItem.acFormula);
        
        if (acValue != null && acValue > 0) {
          shieldBonus = acValue;
          shieldName = shieldItem.name;
          print('🛡️ [ArmorCalculationService] Schild: ${shieldItem.name}, AC Bonus: $acValue');
        }
      }

      // Gesamt-AC berechnen
      int totalAc;
      int effectiveDexModifier;

      if (armorReplacesBase) {
        if (_isHeavyArmor(armorData?.$2)) {
          // Heavy Armor: Kein Dex-Modifier
          effectiveDexModifier = 0;
        } else if (_isMediumArmor(armorData?.$2)) {
          // Medium Armor: Dex max +2
          effectiveDexModifier = dexModifier > 2 ? 2 : dexModifier;
        } else {
          // Light Armor: Voller Dex-Modifier
          effectiveDexModifier = dexModifier;
        }
        totalAc = effectiveBaseAc + effectiveDexModifier + shieldBonus;
      } else {
        // Keine Rüstung: Basis-AC + Dex + Schild
        effectiveDexModifier = dexModifier;
        totalAc = effectiveBaseAc + effectiveDexModifier + shieldBonus;
      }

      // Formel für Anzeige erstellen
      final formula = _buildFormula(
        baseAc: effectiveBaseAc,
        dexModifier: effectiveDexModifier,
        shieldBonus: shieldBonus,
        armorName: armorName,
        shieldName: shieldName,
      );

      print('🛡️ [ArmorCalculationService] Ergebnis: $totalAc ($formula)');

      return ArmorClassResult(
        totalAc: totalAc,
        baseAc: baseArmorClass,
        dexModifier: effectiveDexModifier,
        armorBonus: armorBonus,
        shieldBonus: shieldBonus,
        armorName: armorName,
        shieldName: shieldName,
        formula: formula,
      );
    } catch (e) {
      print('❌ [ArmorCalculationService] Fehler: $e');
      // Fallback: Basis-AC + Dex Modifier
      final dexModifier = _calculateModifier(dexterity);
      return ArmorClassResult(
        totalAc: baseArmorClass + dexModifier,
        baseAc: baseArmorClass,
        dexModifier: dexModifier,
        armorBonus: 0,
        shieldBonus: 0,
        formula: '$baseArmorClass + $dexModifier (Dex)',
      );
    }
  }

  /// Berechnet den Ability Modifier für einen gegebenen Wert
  int _calculateModifier(int abilityScore) {
    return (abilityScore - 10) ~/ 2;
  }

  /// Lädt alle ausgerüsteten Items für einen Character
  Future<List<(InventoryItem, Item)>> _loadEquippedItems(String characterId) async {
    final List<(InventoryItem, Item)> result = [];

    try {
      final inventoryItems = await _inventoryRepository.getByOwnerId(characterId);
      
      for (final invItem in inventoryItems) {
        if (invItem.isEquipped) {
          final item = await _itemRepository.findById(invItem.itemId);
          if (item != null) {
            result.add((invItem, item));
          }
        }
      }
    } catch (e) {
      print('❌ [ArmorCalculationService] Fehler beim Laden der Items: $e');
    }

    return result;
  }

  /// Findet Rüstung im angegebenen Slot
  (InventoryItem, Item)? _findArmorInSlot(List<(InventoryItem, Item)> items, EquipSlot slot) {
    for (final item in items) {
      if (item.$1.equipSlot == slot && item.$2.itemType == ItemType.Armor) {
        return item;
      }
    }
    return null;
  }

  /// Findet Schild im OffHand-Slot
  (InventoryItem, Item)? _findShieldInSlot(List<(InventoryItem, Item)> items, EquipSlot slot) {
    for (final item in items) {
      if (item.$1.equipSlot == slot && item.$2.itemType == ItemType.Shield) {
        return item;
      }
    }
    return null;
  }

  /// Parst die AC-Formel und extrahiert den numerischen AC-Wert
  int? _parseAcFormula(String? acFormula) {
    if (acFormula == null || acFormula.isEmpty) return null;

    // Versuche direkt als Zahl zu parsen (z.B. "16" oder "+2")
    final directParse = int.tryParse(acFormula.replaceAll('+', '').trim());
    if (directParse != null) return directParse;

    // Versuche "AC 16" Format
    final acMatch = RegExp(r'AC\s*(\d+)').firstMatch(acFormula);
    if (acMatch != null) {
      return int.tryParse(acMatch.group(1) ?? '');
    }

    // Versuche "+2" Format
    final bonusMatch = RegExp(r'\+?(\d+)').firstMatch(acFormula);
    if (bonusMatch != null) {
      return int.tryParse(bonusMatch.group(1) ?? '');
    }

    return null;
  }

  /// Prüft ob es sich um Heavy Armor handelt
  /// Verwendet primär die armorCategory, fallback auf String-Erkennung
  bool _isHeavyArmor(Item? item) {
    if (item == null) return false;
    
    // Priorisiere die explizite armorCategory
    if (item.armorCategory != null) {
      return item.armorCategory == ArmorCategory.Heavy;
    }
    
    // Fallback: Prüfen anhand der Properties oder des Namens
    final properties = item.properties?.toLowerCase() ?? '';
    final name = item.name.toLowerCase();
    
    // Heavy Armor Kennzeichner
    return properties.contains('heavy') ||
           name.contains('plate') ||
           name.contains('chain mail') ||
           name.contains('splint') ||
           properties.contains('schwer') ||
           name.contains('platten') ||
           name.contains('kettenrüstung');
  }

  /// Prüft ob es sich um Medium Armor handelt
  /// Verwendet primär die armorCategory, fallback auf String-Erkennung
  bool _isMediumArmor(Item? item) {
    if (item == null) return false;
    
    // Priorisiere die explizite armorCategory
    if (item.armorCategory != null) {
      return item.armorCategory == ArmorCategory.Medium;
    }
    
    // Fallback: Prüfen anhand der Properties oder des Namens
    final properties = item.properties?.toLowerCase() ?? '';
    final name = item.name.toLowerCase();
    
    // Medium Armor Kennzeichner
    return properties.contains('medium') ||
           name.contains('chain shirt') ||
           name.contains('scale mail') ||
           name.contains('breastplate') ||
           name.contains('half plate') ||
           properties.contains('mittel') ||
           name.contains('schuppenpanzer') ||
           name.contains('brustharnisch');
  }

  /// Prüft ob es sich um Light Armor handelt
  /// Verwendet primär die armorCategory, fallback auf String-Erkennung
  bool _isLightArmor(Item? item) {
    if (item == null) return false;
    
    // Priorisiere die explizite armorCategory
    if (item.armorCategory != null) {
      return item.armorCategory == ArmorCategory.Light;
    }
    
    // Fallback: Prüfen anhand der Properties oder des Namens
    final properties = item.properties?.toLowerCase() ?? '';
    final name = item.name.toLowerCase();
    
    // Light Armor Kennzeichner
    return properties.contains('light') ||
           name.contains('leather') ||
           name.contains('padded') ||
           name.contains('studded leather') ||
           properties.contains('leicht') ||
           name.contains('leder');
  }

  /// Gibt die Rüstungskategorie als lesbaren String zurück
  String getArmorCategoryName(Item? item) {
    if (item == null) return 'Keine Rüstung';
    
    if (item.armorCategory != null) {
      switch (item.armorCategory!) {
        case ArmorCategory.Light:
          return 'Leichte Rüstung';
        case ArmorCategory.Medium:
          return 'Mittlere Rüstung';
        case ArmorCategory.Heavy:
          return 'Schwere Rüstung';
      }
    }
    
    // Fallback über String-Erkennung
    if (_isHeavyArmor(item)) return 'Schwere Rüstung';
    if (_isMediumArmor(item)) return 'Mittlere Rüstung';
    if (_isLightArmor(item)) return 'Leichte Rüstung';
    
    return 'Unbekannt';
  }

  /// Erstellt die Formel-Anzeige
  String _buildFormula({
    required int baseAc,
    required int dexModifier,
    required int shieldBonus,
    String? armorName,
    String? shieldName,
  }) {
    final parts = <String>[];
    
    if (armorName != null) {
      parts.add('$baseAc ($armorName)');
    } else {
      parts.add('$baseAc');
    }
    
    if (dexModifier != 0) {
      final sign = dexModifier >= 0 ? '+' : '';
      parts.add('$sign$dexModifier (Dex)');
    }
    
    if (shieldBonus > 0) {
      final shieldDisplay = shieldName ?? 'Schild';
      parts.add('+$shieldBonus ($shieldDisplay)');
    }
    
    return parts.join(' ');
  }

  /// Synchron-Methode für schnelle AC-Berechnung (ohne Datenbankzugriff)
  /// 
  /// Verwendet bereits geladene Items für die Berechnung
  int calculateArmorClassSync({
    required int dexterity,
    required List<(EquipSlot, Item?)> equippedItems,
    int baseArmorClass = 10,
  }) {
    final dexModifier = _calculateModifier(dexterity);
    int totalAc = baseArmorClass;
    bool isHeavyArmor = false;
    bool isMediumArmor = false;
    bool hasArmorEquipped = false;

    print('🛡️ [ArmorCalculationService] calculateArmorClassSync gestartet');
    print('🛡️ [ArmorCalculationService] Dex: $dexterity, DexMod: $dexModifier, Basis-AC: $baseArmorClass');
    print('🛡️ [ArmorCalculationService] ${equippedItems.length} Items zum Prüfen');

    for (final (slot, item) in equippedItems) {
      if (item == null) {
        print('🛡️ [ArmorCalculationService] Slot $slot: null Item, überspringen');
        continue;
      }

      print('🛡️ [ArmorCalculationService] Slot $slot: ${item.name} (Type: ${item.itemType}, acFormula: ${item.acFormula})');

      // Rüstung im Chest-Slot
      if (slot == EquipSlot.chest && item.itemType == ItemType.Armor) {
        final acValue = _parseAcFormula(item.acFormula);
        print('🛡️ [ArmorCalculationService] Rüstung erkannt! ${item.name}, AC-Wert: $acValue');
        
        if (acValue != null && acValue > 0) {
          totalAc = acValue;
          hasArmorEquipped = true;
          isHeavyArmor = _isHeavyArmor(item);
          isMediumArmor = _isMediumArmor(item);
          print('🛡️ [ArmorCalculationService] Heavy: $isHeavyArmor, Medium: $isMediumArmor');
        }
      }

      // Schild im OffHand-Slot
      if (slot == EquipSlot.offHand && item.itemType == ItemType.Shield) {
        final acValue = _parseAcFormula(item.acFormula);
        print('🛡️ [ArmorCalculationService] Schild erkannt! ${item.name}, AC-Bonus: $acValue');
        
        if (acValue != null && acValue > 0) {
          totalAc += acValue;
        }
      }
    }

    // Dex-Modifier anwenden (außer bei Heavy Armor)
    if (hasArmorEquipped) {
      if (isHeavyArmor) {
        // Heavy Armor: Kein Dex-Modifier
        print('🛡️ [ArmorCalculationService] Heavy Armor - KEIN Dex-Bonus');
        // totalAc bleibt wie ist
      } else if (isMediumArmor) {
        // Medium Armor: Dex max +2
        final effectiveDex = dexModifier > 2 ? 2 : dexModifier;
        totalAc += effectiveDex;
        print('🛡️ [ArmorCalculationService] Medium Armor - Dex-Bonus max +2: $effectiveDex');
      } else {
        // Light Armor: Voller Dex-Modifier
        totalAc += dexModifier;
        print('🛡️ [ArmorCalculationService] Light Armor - voller Dex-Bonus: $dexModifier');
      }
    } else {
      // Keine Rüstung: Basis-AC + Dex
      totalAc = baseArmorClass + dexModifier;
      print('🛡️ [ArmorCalculationService] Keine Rüstung - Basis + Dex: $baseArmorClass + $dexModifier');
    }

    print('🛡️ [ArmorCalculationService] Finale AC: $totalAc');
    return totalAc;
  }
}