// lib/models/creature.dart
import 'package:uuid/uuid.dart';
import 'condition.dart';
import 'inventory_item.dart';

var uuid = const Uuid();

class Creature {
  final String id;
  final String name;
  final int maxHp;
  final int armorClass;
  final String speed;
  final String attacks;
  final int initiativeBonus;
  
  // Temporäre Kampf-Werte
  int currentHp;
  int? initiative;
  List<Condition> conditions = [];
  final bool isPlayer;

  // NEU: Felder für die 6 Hauptattribute (nur temporär für den Kampf)
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  // NEU: Inventar für Spieler-Charaktere
  final List<DisplayInventoryItem> inventory;

  Creature({
    String? id,
    required this.name,
    required this.maxHp,
    required this.currentHp,
    this.armorClass = 10,
    this.speed = "30ft",
    this.attacks = "",
    this.initiativeBonus = 0,
    this.isPlayer = false,
    //  Standardwerten für Monster
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,

    // Standardmäßig ein leeres Inventar
    this.inventory = const [],
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'maxHp': maxHp,
      'armorClass': armorClass,
      'speed': speed,
      'attacks': attacks,
      'initiativeBonus': initiativeBonus,
    };
  }

  factory Creature.fromMap(Map<String, dynamic> map) {
    return Creature(
      id: map['id'],
      name: map['name'],
      maxHp: map['maxHp'],
      currentHp: map['maxHp'],
      armorClass: map['armorClass'] ?? 10,
      speed: map['speed'] ?? "30ft",
      attacks: map['attacks'] ?? "",
      initiativeBonus: map['initiativeBonus'] ?? 0,
    );
  }
}