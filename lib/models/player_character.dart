// lib/models/player_character.dart
import 'package:uuid/uuid.dart';
import 'dart:convert';

var uuid = const Uuid();

class PlayerCharacter {
  final String id;
  final String campaignId;
  final String name;
  final String playerName;
  final String className;
  final String raceName; // NEUES FELD: Wir speichern den Namen der Rasse
  final int level;
  final int maxHp;
  final int armorClass;
  final int initiativeBonus;
  final String? imagePath;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final List<String> proficientSkills;

  PlayerCharacter({
    String? id,
    required this.campaignId,
    required this.name,
    required this.playerName,
    required this.className,
    required this.raceName,
    this.level = 1,
    this.maxHp = 10,
    this.armorClass = 10,
    this.initiativeBonus = 0,
    this.imagePath,
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
    this.proficientSkills = const [],
  }) : id = id ?? uuid.v4();

  // toMap und fromMap anpassen
  Map<String, dynamic> toMap() {
    return {
      'id': id, 'campaignId': campaignId, 'name': name, 'playerName': playerName,
      'className': className, 'raceName': raceName, // NEU
      'level': level, 'maxHp': maxHp, 'armorClass': armorClass,
      'initiativeBonus': initiativeBonus, 'imagePath': imagePath, 'strength': strength,
      'dexterity': dexterity, 'constitution': constitution, 'intelligence': intelligence,
      'wisdom': wisdom, 'charisma': charisma,
      'proficientSkills': jsonEncode(proficientSkills),
    };
  }

  factory PlayerCharacter.fromMap(Map<String, dynamic> map) {
    return PlayerCharacter(
      id: map['id'], campaignId: map['campaignId'], name: map['name'],
      playerName: map['playerName'], className: map['className'],
      raceName: map['raceName'] ?? 'Mensch', // NEU
      level: map['level'] ?? 1, maxHp: map['maxHp'] ?? 10,
      armorClass: map['armorClass'] ?? 10, initiativeBonus: map['initiativeBonus'] ?? 0,
      imagePath: map['imagePath'], strength: map['strength'] ?? 10,
      dexterity: map['dexterity'] ?? 10, constitution: map['constitution'] ?? 10,
      intelligence: map['intelligence'] ?? 10, wisdom: map['wisdom'] ?? 10,
      charisma: map['charisma'] ?? 10,
      proficientSkills: map['proficientSkills'] != null 
          ? List<String>.from(jsonDecode(map['proficientSkills'])) 
          : [],
    );
  }
}