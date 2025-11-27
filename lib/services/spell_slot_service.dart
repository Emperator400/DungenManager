// lib/services/spell_slot_service.dart
import '../models/spell_slot_manager.dart';

/// Service für die Verwaltung von Spell Slots
class SpellSlotService {
  /// Prüft ob ein Zauber gewirkt werden kann
  static bool canCastSpell(SpellSlotManager manager, int spellLevel) {
    return manager.totalSlots[spellLevel] != null && 
           manager.totalSlots[spellLevel]! > (manager.usedSlots[spellLevel] ?? 0);
  }
  
  /// Gibt die verbleibenden Slots für ein Level zurück
  static int getRemainingSlots(SpellSlotManager manager, int spellLevel) {
    return (manager.totalSlots[spellLevel] ?? 0) - (manager.usedSlots[spellLevel] ?? 0);
  }
  
  /// Verwendet einen Spell Slot
  static SpellSlotManager useSpellSlot(SpellSlotManager manager, int spellLevel) {
    if (canCastSpell(manager, spellLevel)) {
      final newUsedSlots = Map<int, int>.from(manager.usedSlots);
      newUsedSlots[spellLevel] = (newUsedSlots[spellLevel] ?? 0) + 1;
      
      return SpellSlotManager(
        totalSlots: manager.totalSlots,
        usedSlots: newUsedSlots,
      );
    }
    return manager;
  }
  
  /// Stellt einen Spell Slot wieder her
  static SpellSlotManager restoreSpellSlot(SpellSlotManager manager, int spellLevel) {
    if (manager.usedSlots[spellLevel] != null && manager.usedSlots[spellLevel]! > 0) {
      final newUsedSlots = Map<int, int>.from(manager.usedSlots);
      newUsedSlots[spellLevel] = newUsedSlots[spellLevel]! - 1;
      
      return SpellSlotManager(
        totalSlots: manager.totalSlots,
        usedSlots: newUsedSlots,
      );
    }
    return manager;
  }
  
  /// Setzt alle Slots zurück
  static SpellSlotManager resetSlots(SpellSlotManager manager) {
    final newUsedSlots = <int, int>{};
    manager.usedSlots.forEach((key, value) {
      newUsedSlots[key] = 0;
    });
    
    return SpellSlotManager(
      totalSlots: manager.totalSlots,
      usedSlots: newUsedSlots,
    );
  }
  
  /// Setzt die Gesamtzahl der Slots für ein Level
  static SpellSlotManager setTotalSlots(SpellSlotManager manager, int spellLevel, int count) {
    final newTotalSlots = Map<int, int>.from(manager.totalSlots);
    newTotalSlots[spellLevel] = count;
    
    return SpellSlotManager(
      totalSlots: newTotalSlots,
      usedSlots: manager.usedSlots,
    );
  }
  
  /// Formatiert die Spell Slots für die Anzeige
  static String formatSpellSlots(SpellSlotManager manager) {
    final buffer = StringBuffer();
    buffer.writeln('Spell Slots:');
    for (int level = 1; level <= 9; level++) {
      final total = manager.totalSlots[level] ?? 0;
      final used = manager.usedSlots[level] ?? 0;
      final remaining = total - used;
      
      if (total > 0) {
        buffer.writeln('  Level $level: $remaining/$total available');
      }
    }
    return buffer.toString();
  }
}
