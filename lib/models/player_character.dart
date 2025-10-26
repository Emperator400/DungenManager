// lib/models/player_character.dart
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'inventory_item.dart';
import 'attack.dart';

var uuid = const Uuid();

class PlayerCharacter {
  final String id;
  final String campaignId;
  final String name;
  final String playerName;
  final String className;
  final String raceName;
  final int level;
  final int maxHp;
  final int armorClass;
  final int initiativeBonus;
  final String? imagePath;
  
  // Die 6 Hauptattribute
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  
  // Fertigkeiten
  final List<String> proficientSkills;
  
  // NEU: D&D-Klassifikation (aus Creature übernommen)
  final String? size;              // Größe (Tiny, Small, Medium, Large, Huge, Gargantuan)
  final String? type;              // Typ (Humanoid, Beast, Dragon, etc.)
  final String? subtype;           // Subtyp
  final String? alignment;         // Gesinnung
  
  // NEU: Beschreibung und Fähigkeiten
  final String? description;       // Beschreibung des Charakters
  final String? specialAbilities;  // Spezielle Fähigkeiten
  final String? attacks;           // Angriffe & Aktionen (Legacy String)
  
  // NEU: Strukturierte Angriffsliste
  final List<Attack> attackList;   // Neue strukturierte Angriffe
  
  // NEU: Inventar und Währung
  final List<DisplayInventoryItem> inventory;
  final double gold;
  final double silver;
  final double copper;
  
  // NEU: Erweiterte Felder für Unified System
  final String sourceType;        // 'custom', 'official', 'hybrid'
  final String? sourceId;         // Verweis auf Original-Quelle
  final bool isFavorite;          // Ob der Charakter favorisiert ist
  final String version;           // Version des Charakters

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
    // NEU: D&D-Klassifikation
    this.size,
    this.type,
    this.subtype,
    this.alignment,
    // NEU: Beschreibung und Fähigkeiten
    this.description,
    this.specialAbilities,
    this.attacks,
    // NEU: Strukturierte Angriffe
    this.attackList = const [],
    // NEU: Inventar und Währung
    this.inventory = const [],
    this.gold = 0.0,
    this.silver = 0.0,
    this.copper = 0.0,
    // NEU: Erweiterte Felder
    this.sourceType = 'custom',
    this.sourceId,
    this.isFavorite = false,
    this.version = '1.0',
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'campaignId': campaignId,
        'name': name,
        'playerName': playerName,
        'className': className,
        'raceName': raceName,
        'level': level,
        'maxHp': maxHp,
        'armorClass': armorClass,
        'initiativeBonus': initiativeBonus,
        'imagePath': imagePath,
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'charisma': charisma,
        'proficientSkills': jsonEncode(proficientSkills ?? []),
        // NEU: D&D-Klassifikation
        'size': size,
        'type': type,
        'subtype': subtype,
        'alignment': alignment,
        // NEU: Beschreibung und Fähigkeiten
        'description': description,
        'special_abilities': specialAbilities,
        'attacks': attacks,
        // NEU: Strukturierte Angriffe
        'attack_list': attackList.isNotEmpty 
            ? attackList.map((attack) => attack.toMap()).toList()
            : [],
        // NEU: Inventar und Währung
        'gold': gold,
        'silver': silver,
        'copper': copper,
        // NEU: Erweiterte Felder
        'source_type': sourceType,
        'source_id': sourceId,
        'is_favorite': isFavorite ? 1 : 0,
        'version': version,
      };
    } catch (e) {
      // Fallback bei Fehlern
      print('Fehler bei toMap(): $e');
      return {
        'id': id,
        'campaignId': campaignId,
        'name': name,
        'playerName': playerName,
        'className': className,
        'raceName': raceName,
        'level': level,
        'maxHp': maxHp,
        'armorClass': armorClass,
        'initiativeBonus': initiativeBonus,
        'imagePath': imagePath,
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'charisma': charisma,
        'proficientSkills': jsonEncode([]),
        'size': size,
        'type': type,
        'subtype': subtype,
        'alignment': alignment,
        'description': description,
        'special_abilities': specialAbilities,
        'attacks': attacks,
        'attack_list': [],
        'gold': gold,
        'silver': silver,
        'copper': copper,
        'source_type': sourceType,
        'source_id': sourceId,
        'is_favorite': isFavorite ? 1 : 0,
        'version': version,
      };
    }
  }

  factory PlayerCharacter.fromMap(Map<String, dynamic> map) {
    try {
      final attackListData = map['attack_list'] as List<dynamic>?;
      List<Attack> attackList = <Attack>[];
      
      // Sichere Verarbeitung der Angriffsliste
      if (attackListData != null) {
        try {
          attackList = attackListData
              .where((attackMap) => attackMap != null && attackMap is Map<String, dynamic>)
              .map((attackMap) => Attack.fromMap(attackMap as Map<String, dynamic>))
              .where((attack) => attack != null)
              .cast<Attack>()
              .toList();
        } catch (e) {
          print('Fehler bei der Verarbeitung der Angriffsliste: $e');
          attackList = <Attack>[];
        }
      }
      
      // Sichere Verarbeitung der Fertigkeiten
      List<String> proficientSkills = [];
      try {
        if (map['proficientSkills'] != null) {
          final decodedSkills = jsonDecode(map['proficientSkills']);
          if (decodedSkills is List) {
            proficientSkills = List<String>.from(decodedSkills);
          }
        }
      } catch (e) {
        print('Fehler bei der Verarbeitung der Fertigkeiten: $e');
        proficientSkills = [];
      }
      
      return PlayerCharacter(
        id: map['id']?.toString() ?? '',
        campaignId: map['campaignId']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Unbenannt',
        playerName: map['playerName']?.toString() ?? 'Unbekannt',
        className: map['className']?.toString() ?? 'Unbekannt',
        raceName: map['raceName']?.toString() ?? 'Mensch',
        level: (map['level'] as int?) ?? 1,
        maxHp: (map['maxHp'] as int?) ?? 10,
        armorClass: (map['armorClass'] as int?) ?? 10,
        initiativeBonus: (map['initiativeBonus'] as int?) ?? 0,
        imagePath: map['imagePath']?.toString(),
        strength: (map['strength'] as int?) ?? 10,
        dexterity: (map['dexterity'] as int?) ?? 10,
        constitution: (map['constitution'] as int?) ?? 10,
        intelligence: (map['intelligence'] as int?) ?? 10,
        wisdom: (map['wisdom'] as int?) ?? 10,
        charisma: (map['charisma'] as int?) ?? 10,
        proficientSkills: proficientSkills,
        // NEU: D&D-Klassifikation
        size: map['size']?.toString(),
        type: map['type']?.toString(),
        subtype: map['subtype']?.toString(),
        alignment: map['alignment']?.toString(),
        // NEU: Beschreibung und Fähigkeiten
        description: map['description']?.toString(),
        specialAbilities: map['special_abilities']?.toString(),
        attacks: map['attacks']?.toString(),
        // NEU: Strukturierte Angriffe
        attackList: attackList,
        // NEU: Inventar und Währung
        gold: (map['gold'] as num?)?.toDouble() ?? 0.0,
        silver: (map['silver'] as num?)?.toDouble() ?? 0.0,
        copper: (map['copper'] as num?)?.toDouble() ?? 0.0,
        // NEU: Erweiterte Felder
        sourceType: map['source_type']?.toString() ?? 'custom',
        sourceId: map['source_id']?.toString(),
        isFavorite: (map['is_favorite'] as int?) == 1,
        version: map['version']?.toString() ?? '1.0',
      );
    } catch (e) {
      print('Fehler bei fromMap(): $e');
      // Fallback mit sicheren Standardwerten
      return PlayerCharacter(
        id: map['id']?.toString() ?? '',
        campaignId: map['campaignId']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Fehlerhafter Charakter',
        playerName: map['playerName']?.toString() ?? 'Fehler',
        className: map['className']?.toString() ?? 'Fehler',
        raceName: 'Mensch',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        initiativeBonus: 0,
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10,
        proficientSkills: [],
      );
    }
  }

  // NEU: CopyWith-Methode für einfache Anpassungen
  PlayerCharacter copyWith({
    String? id,
    String? campaignId,
    String? name,
    String? playerName,
    String? className,
    String? raceName,
    int? level,
    int? maxHp,
    int? armorClass,
    int? initiativeBonus,
    String? imagePath,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    List<String>? proficientSkills,
    // NEU: D&D-Klassifikation
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    // NEU: Beschreibung und Fähigkeiten
    String? description,
    String? specialAbilities,
    String? attacks,
    // NEU: Strukturierte Angriffe
    List<Attack>? attackList,
    // NEU: Inventar und Währung
    List<DisplayInventoryItem>? inventory,
    double? gold,
    double? silver,
    double? copper,
    // NEU: Erweiterte Felder
    String? sourceType,
    String? sourceId,
    bool? isFavorite,
    String? version,
  }) {
    return PlayerCharacter(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      name: name ?? this.name,
      playerName: playerName ?? this.playerName,
      className: className ?? this.className,
      raceName: raceName ?? this.raceName,
      level: level ?? this.level,
      maxHp: maxHp ?? this.maxHp,
      armorClass: armorClass ?? this.armorClass,
      initiativeBonus: initiativeBonus ?? this.initiativeBonus,
      imagePath: imagePath ?? this.imagePath,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      proficientSkills: proficientSkills ?? this.proficientSkills,
      // NEU: D&D-Klassifikation
      size: size ?? this.size,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      alignment: alignment ?? this.alignment,
      // NEU: Beschreibung und Fähigkeiten
      description: description ?? this.description,
      specialAbilities: specialAbilities ?? this.specialAbilities,
      attacks: attacks ?? this.attacks,
      // NEU: Strukturierte Angriffe
      attackList: attackList ?? this.attackList,
      // NEU: Inventar und Währung
      inventory: inventory ?? this.inventory,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      copper: copper ?? this.copper,
      // NEU: Erweiterte Felder
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isFavorite: isFavorite ?? this.isFavorite,
      version: version ?? this.version,
    );
  }
  
  // NEU: Helper-Methoden für Angriffs-Konvertierung
  String get formattedAttacks {
    if (attackList.isNotEmpty) {
      return AttackHelper.attacksToString(attackList);
    }
    return attacks ?? '';
  }
  
  List<Attack> get effectiveAttacks {
    if (attackList.isNotEmpty) {
      return attackList;
    }
    // Fallback zu Legacy-String
    if (attacks != null && attacks!.isNotEmpty) {
      return AttackHelper.parseAttacksFromString(attacks!);
    }
    return [];
  }
}
