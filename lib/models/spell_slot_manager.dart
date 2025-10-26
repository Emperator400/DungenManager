// lib/models/spell_slot_manager.dart
class SpellSlotManager {
  final Map<int, int> totalSlots;     // Level -> Anzahl
  final Map<int, int> usedSlots;     // Level -> Verwendet
  
  SpellSlotManager({
    Map<int, int>? totalSlots,
    Map<int, int>? usedSlots,
  }) : totalSlots = totalSlots ?? const {1: 4, 2: 3, 3: 2, 4: 1},
       usedSlots = usedSlots ?? const {1: 0, 2: 0, 3: 0, 4: 0};
  
  SpellSlotManager.fromMap(Map<String, dynamic> map)
      : totalSlots = Map<int, int>.from(
          (map['totalSlots'] as Map?)?.map((k, v) => MapEntry(int.parse(k), v)) ?? {},
        ),
        usedSlots = Map<int, int>.from(
          (map['usedSlots'] as Map?)?.map((k, v) => MapEntry(int.parse(k), v)) ?? {},
        );

  bool canCastSpell(int spellLevel) {
    return totalSlots[spellLevel] != null && 
           totalSlots[spellLevel]! > (usedSlots[spellLevel] ?? 0);
  }
  
  int getRemainingSlots(int spellLevel) {
    return (totalSlots[spellLevel] ?? 0) - (usedSlots[spellLevel] ?? 0);
  }
  
  void useSpellSlot(int spellLevel) {
    if (canCastSpell(spellLevel)) {
      usedSlots[spellLevel] = (usedSlots[spellLevel] ?? 0) + 1;
    }
  }
  
  void restoreSpellSlot(int spellLevel) {
    if (usedSlots[spellLevel] != null && usedSlots[spellLevel]! > 0) {
      usedSlots[spellLevel] = usedSlots[spellLevel]! - 1;
    }
  }
  
  void resetSlots() {
    usedSlots.forEach((key, value) {
      usedSlots[key] = 0;
    });
  }
  
  void setTotalSlots(int spellLevel, int count) {
    totalSlots[spellLevel] = count;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'totalSlots': totalSlots.map((k, v) => MapEntry(k.toString(), v)),
      'usedSlots': usedSlots.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Spell Slots:');
    for (int level = 1; level <= 9; level++) {
      final total = totalSlots[level] ?? 0;
      final used = usedSlots[level] ?? 0;
      final remaining = total - used;
      
      if (total > 0) {
        final remaining = getRemainingSlots(level);
        buffer.writeln('  Level $level: $remaining/$total available');
      }
    }
    return buffer.toString();
  }
}
