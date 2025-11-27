// lib/models/spell_slot_manager.dart

/// Reines Datenmodell für Spell Slots
class SpellSlotManager {
  final Map<int, int> totalSlots;     // Level -> Anzahl
  final Map<int, int> usedSlots;     // Level -> Verwendet
  
  const SpellSlotManager({
    required this.totalSlots,
    required this.usedSlots,
  });
  
  /// Factory für Standard-Spell Slots (Level 1-4)
  factory SpellSlotManager.defaultSlots() {
    return const SpellSlotManager(
      totalSlots: {1: 4, 2: 3, 3: 2, 4: 1},
      usedSlots: {1: 0, 2: 0, 3: 0, 4: 0},
    );
  }
  
  /// Factory für leere Spell Slots
  factory SpellSlotManager.empty() {
    return const SpellSlotManager(
      totalSlots: {},
      usedSlots: {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_slots': totalSlots.map((k, v) => MapEntry(k.toString(), v)),
      'used_slots': usedSlots.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory SpellSlotManager.fromMap(Map<String, dynamic> map) {
    final totalSlotsMap = <String, dynamic>{};
    final usedSlotsMap = <String, dynamic>{};
    
    // Sicheres Extrahieren der Maps mit Fallback
    if (map['total_slots'] is Map) {
      totalSlotsMap.addAll(Map<String, dynamic>.from(map['total_slots'] as Map));
    }
    if (map['used_slots'] is Map) {
      usedSlotsMap.addAll(Map<String, dynamic>.from(map['used_slots'] as Map));
    }
    
    return SpellSlotManager(
      totalSlots: Map<int, int>.from(
        totalSlotsMap.map((k, v) => MapEntry(
          int.tryParse(k.toString()) ?? 0,
          int.tryParse(v.toString()) ?? 0,
        )),
      ),
      usedSlots: Map<int, int>.from(
        usedSlotsMap.map((k, v) => MapEntry(
          int.tryParse(k.toString()) ?? 0,
          int.tryParse(v.toString()) ?? 0,
        )),
      ),
    );
  }

  /// Berechnet die verbleibenden Slots für jedes Level
  Map<int, int> getRemainingSlots() {
    final remaining = <int, int>{};
    
    // Alle Level aus totalSlots durchgehen
    for (final level in totalSlots.keys) {
      final total = totalSlots[level] ?? 0;
      final used = usedSlots[level] ?? 0;
      remaining[level] = (total - used).clamp(0, total);
    }
    
    // Level aus usedSlots, die nicht in totalSlots sind (sollte nicht vorkommen)
    for (final level in usedSlots.keys) {
      if (!totalSlots.containsKey(level)) {
        remaining[level] = 0; // Keine Slots verfügbar
      }
    }
    
    return remaining;
  }

  @override
  String toString() {
    return 'SpellSlotManager(totalSlots: $totalSlots, usedSlots: $usedSlots)';
  }
}
