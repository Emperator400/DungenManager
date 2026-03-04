// lib/game_data/dnd_data_importer.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/core/database_connection.dart';
import '../models/official_monster.dart';
import '../models/official_spell.dart';
import '../services/official_monster_import_service.dart';
import 'dnd_demo_data.dart';

class DndDataImporter {
  final DatabaseConnection _db = DatabaseConnection.instance;
  final String baseUrl = 'https://raw.githubusercontent.com/5etools-mirror-1/5etools-mirror-1.github.io/master/data/';

  // Öffentliche Getter für den Zugriff auf die Datenbank
  DatabaseConnection get databaseConnection => _db;

  // Hauptmethode zum Importieren aller Daten
  Future<Map<String, int>> downloadAndImportAllData() async {
    final results = <String, int>{};
    
    try {
      // Monster importieren
      final monsterCount = await importMonsters();
      results['monsters'] = monsterCount;
      
      // Spells importieren
      final spellCount = await importSpells();
      results['spells'] = spellCount;
      
      // Klassen importieren
      final classCount = await importClasses();
      results['classes'] = classCount;
      
      // Völker importieren
      final raceCount = await importRaces();
      results['races'] = raceCount;
      
      // Items importieren
      final itemCount = await importItems();
      results['items'] = itemCount;
      
      // Orte importieren
      final locationCount = await importLocations();
      results['locations'] = locationCount;
      
      return results;
    } catch (e) {
      print('Fehler beim Import der D&D-Daten: $e');
      rethrow;
    }
  }

  // --- Monster Import ---
  Future<int> importMonsters() async {
    try {
      print('Starte Monster-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_monsters');
      
      // Daten von 5e.tools herunterladen
      final response = await http.get(Uri.parse('${baseUrl}bestiary.json'));
      if (response.statusCode != 200) {
        print('Externe Daten nicht verfügbar, verwende Demo-Daten');
        return await importDemoMonsters();
      }
      
      final data = json.decode(response.body);
      final monsters = data['monster'] as List;
      
      int importedCount = 0;
      final batchSize = 50; // In Batches importieren für bessere Performance
      
      for (int i = 0; i < monsters.length; i += batchSize) {
        final end = (i + batchSize < monsters.length) ? i + batchSize : monsters.length;
        final batch = monsters.sublist(i, end);
        
        for (final monsterData in batch) {
          try {
            // Konvertiere zu OfficialMonster
            final monster = OfficialMonsterImportService.from5eToolsJson(monsterData as Map<String, dynamic>);
            
            // Füge in Datenbank ein
            await db.insert('official_monsters', monster.toMap());
            importedCount++;
          } catch (e) {
            print('Fehler beim Import des Monsters "${monsterData['name']}": $e');
          }
        }
        
        print('Monster-Import Fortschritt: $importedCount/${monsters.length}');
        
        // Kleine Pause zwischen Batches um Speicher freizugeben
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      print('Monster-Import abgeschlossen: $importedCount Monster importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Monster-Import, verwende Demo-Daten: $e');
      return await importDemoMonsters();
    }
  }

  // --- Spells Import ---
  Future<int> importSpells() async {
    try {
      print('Starte Spells-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_spells');
      
      // Daten von 5e.tools herunterladen
      final response = await http.get(Uri.parse('${baseUrl}spells.json'));
      if (response.statusCode != 200) {
        print('Externe Daten nicht verfügbar, verwende Demo-Daten');
        return await importDemoSpells();
      }
      
      final data = json.decode(response.body);
      final spells = data['spell'] as List;
      
      int importedCount = 0;
      final batchSize = 50;
      
      for (int i = 0; i < spells.length; i += batchSize) {
        final end = (i + batchSize < spells.length) ? i + batchSize : spells.length;
        final batch = spells.sublist(i, end);
        
        for (final spellData in batch) {
          try {
            final spell = OfficialSpell.from5eToolsJson(spellData as Map<String, dynamic>);
            await db.insert('official_spells', spell.toMap());
            importedCount++;
          } catch (e) {
            print('Fehler beim Import des Spells "${spellData['name']}": $e');
          }
        }
        
        print('Spells-Import Fortschritt: $importedCount/${spells.length}');
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      print('Spells-Import abgeschlossen: $importedCount Spells importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Spells-Import, verwende Demo-Daten: $e');
      return await importDemoSpells();
    }
  }

  // --- Klassen Import ---
  Future<int> importClasses() async {
    try {
      print('Starte Klassen-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_classes');
      
      // Daten von 5e.tools herunterladen
      final response = await http.get(Uri.parse('${baseUrl}classes.json'));
      if (response.statusCode != 200) {
        print('Externe Daten nicht verfügbar, verwende Demo-Daten');
        return await importDemoClasses();
      }
      
      final data = json.decode(response.body);
      final classes = data['class'] as List;
      
      int importedCount = 0;
      
      for (final classData in classes) {
        try {
          final classMap = _parseClassFrom5eTools(classData as Map<String, dynamic>);
          await db.insert('official_classes', classMap);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import der Klasse "${classData['name']}": $e');
        }
      }
      
      print('Klassen-Import abgeschlossen: $importedCount Klassen importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Klassen-Import, verwende Demo-Daten: $e');
      return await importDemoClasses();
    }
  }

  // --- Völker Import ---
  Future<int> importRaces() async {
    try {
      print('Starte Völker-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_races');
      
      // Daten von 5e.tools herunterladen
      final response = await http.get(Uri.parse('${baseUrl}races.json'));
      if (response.statusCode != 200) {
        print('Externe Daten nicht verfügbar, verwende Demo-Daten');
        return await importDemoRaces();
      }
      
      final data = json.decode(response.body);
      final races = data['race'] as List;
      
      int importedCount = 0;
      
      for (final raceData in races) {
        try {
          final raceMap = _parseRaceFrom5eTools(raceData as Map<String, dynamic>);
          await db.insert('official_races', raceMap);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Volkes "${raceData['name']}": $e');
        }
      }
      
      print('Völker-Import abgeschlossen: $importedCount Völker importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Völker-Import, verwende Demo-Daten: $e');
      return await importDemoRaces();
    }
  }

  // --- Items Import ---
  Future<int> importItems() async {
    try {
      print('Starte Items-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_items');
      
      // Daten von 5e.tools herunterladen
      final response = await http.get(Uri.parse('${baseUrl}items.json'));
      if (response.statusCode != 200) {
        print('Externe Daten nicht verfügbar, verwende Demo-Daten');
        return await importDemoItems();
      }
      
      final data = json.decode(response.body);
      final items = data['item'] as List;
      
      int importedCount = 0;
      final batchSize = 50;
      
      for (int i = 0; i < items.length; i += batchSize) {
        final end = (i + batchSize < items.length) ? i + batchSize : items.length;
        final batch = items.sublist(i, end);
        
        for (final itemData in batch) {
          try {
            final itemMap = _parseItemFrom5eTools(itemData as Map<String, dynamic>);
            await db.insert('official_items', itemMap);
            importedCount++;
          } catch (e) {
            print('Fehler beim Import des Items "${itemData['name']}": $e');
          }
        }
        
        print('Items-Import Fortschritt: $importedCount/${items.length}');
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      print('Items-Import abgeschlossen: $importedCount Items importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Items-Import, verwende Demo-Daten: $e');
      return await importDemoItems();
    }
  }

  // --- Orte Import ---
  Future<int> importLocations() async {
    try {
      print('Starte Orte-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_locations');
      
      // Daten von 5e.tools herunterladen
      final response = await http.get(Uri.parse('${baseUrl}locations.json'));
      if (response.statusCode != 200) {
        print('Externe Daten nicht verfügbar, verwende Demo-Daten');
        return await importDemoLocations();
      }
      
      final data = json.decode(response.body);
      final locations = data['location'] as List;
      
      int importedCount = 0;
      
      for (final locationData in locations) {
        try {
          final locationMap = _parseLocationFrom5eTools(locationData as Map<String, dynamic>);
          await db.insert('official_locations', locationMap);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Ortes "${locationData['name']}": $e');
        }
      }
      
      print('Orte-Import abgeschlossen: $importedCount Orte importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Orte-Import, verwende Demo-Daten: $e');
      return await importDemoLocations();
    }
  }

  // --- Parser für komplexe Datenstrukturen ---
  
  Map<String, dynamic> _parseMonsterFrom5eTools(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['name']?.toLowerCase()?.replaceAll(' ', '_'),
      'name': json['name'],
      'size': json['size'],
      'type': json['type'],
      'subtype': json['subtype'],
      'alignment': json['alignment'],
      'armor_class': json['ac']?.toString() ?? '10',
      'hit_points': json['hp']?.toString() ?? '1',
      'hit_dice': json['hd']?.toString() ?? '1d8',
      'speed': json['speed']?.toString() ?? '30 ft.',
      'strength': json['str'] ?? 10,
      'dexterity': json['dex'] ?? 10,
      'constitution': json['con'] ?? 10,
      'intelligence': json['int'] ?? 10,
      'wisdom': json['wis'] ?? 10,
      'charisma': json['cha'] ?? 10,
      'strength_save': json['save']?['str'],
      'dexterity_save': json['save']?['dex'],
      'constitution_save': json['save']?['con'],
      'intelligence_save': json['save']?['int'],
      'wisdom_save': json['save']?['wis'],
      'charisma_save': json['save']?['cha'],
      'challenge_rating': json['cr']?.toString() ?? '1/8',
      'experience_points': _calculateXpFromCr(json['cr']?.toString() ?? '1/8'),
      'skills': json['skill'] != null ? jsonEncode(json['skill']) : null,
      'damage_vulnerabilities': json['vulnerable'] != null ? jsonEncode(json['vulnerable']) : null,
      'damage_resistances': json['resist'] != null ? jsonEncode(json['resist']) : null,
      'damage_immunities': json['immune'] != null ? jsonEncode(json['immune']) : null,
      'condition_immunities': json['conditionImmune'] != null ? jsonEncode(json['conditionImmune']) : null,
      'senses': json['senses']?.toString() ?? 'passive Perception 10',
      'languages': json['languages']?.toString() ?? '',
      'special_abilities': json['trait'] != null ? jsonEncode(json['trait']) : null,
      'actions': json['action'] != null ? jsonEncode(json['action']) : null,
      'legendary_actions': json['legendary'] != null ? jsonEncode(json['legendary']) : null,
      'description': json['entries'] is List ? (json['entries'] as List).join('\n') : json['entries']?.toString() ?? '',
      'source': json['source'] ?? 'MM',
      'page': json['page'] ?? 1,
      'is_custom': 0,
      'version': '1.0',
    };
  }

  int _calculateXpFromCr(String cr) {
    final crMap = {
      '0': 10,
      '1/8': 25,
      '1/4': 50,
      '1/2': 100,
      '1': 200,
      '2': 450,
      '3': 700,
      '4': 1100,
      '5': 1800,
      '6': 2300,
      '7': 2900,
      '8': 3900,
      '9': 5000,
      '10': 5900,
      '11': 7200,
      '12': 8400,
      '13': 10000,
      '14': 11500,
      '15': 13000,
      '16': 15000,
      '17': 18000,
      '18': 20000,
      '19': 22000,
      '20': 25000,
      '21': 33000,
      '22': 41000,
      '23': 50000,
      '24': 62000,
      '30': 155000,
    };
    return crMap[cr] ?? 0;
  }
  
  Map<String, dynamic> _parseClassFrom5eTools(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['name']?.toLowerCase()?.replaceAll(' ', '_'),
      'name': json['name'],
      'hit_die': json['hd']?.toString(),
      'proficiency_choices': json['proficiencyChoices'] != null ? jsonEncode(json['proficiencyChoices']) : null,
      'starting_proficiencies': json['startingProficiencies'] != null ? jsonEncode(json['startingProficiencies']) : null,
      'equipment': json['startingEquipment'] != null ? jsonEncode(json['startingEquipment']) : null,
      'class_table': json['classTable'] != null ? jsonEncode(json['classTable']) : null,
      'spellcasting': json['spellcasting'] != null ? jsonEncode(json['spellcasting']) : null,
      'features': json['classFeatures'] != null ? jsonEncode(json['classFeatures']) : null,
      'subclasses': json['subclasses'] != null ? jsonEncode(json['subclasses']) : null,
      'source': json['source'] ?? 'PHB',
      'page': json['page'] ?? 1,
      'is_custom': 0,
      'version': '1.0',
    };
  }

  Map<String, dynamic> _parseRaceFrom5eTools(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['name']?.toLowerCase()?.replaceAll(' ', '_'),
      'name': json['name'],
      'ability_bonuses': json['ability'] != null ? jsonEncode(json['ability']) : null,
      'age': json['age'],
      'alignment': json['alignment'],
      'size': json['size'],
      'speed': json['speed'] != null ? jsonEncode(json['speed']) : null,
      'languages': json['languageProficiencies'] != null ? jsonEncode(json['languageProficiencies']) : null,
      'traits': json['traits'] != null ? jsonEncode(json['traits']) : null,
      'subraces': json['subraces'] != null ? jsonEncode(json['subraces']) : null,
      'source': json['source'] ?? 'PHB',
      'page': json['page'] ?? 1,
      'is_custom': 0,
      'version': '1.0',
    };
  }

  Map<String, dynamic> _parseItemFrom5eTools(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['name']?.toLowerCase()?.replaceAll(' ', '_'),
      'name': json['name'],
      'item_type': json['type'],
      'rarity': json['rarity'],
      'requires_attunement': json['requiresAttunement'] == true ? 1 : 0,
      'weight': json['weight'],
      'cost': json['value'],
      'weapon_category': json['weaponCategory'],
      'weapon_range': json['range'] != null ? jsonEncode(json['range']) : null,
      'damage': json['damage'] != null ? jsonEncode(json['damage']) : null,
      'properties': json['property'] != null ? jsonEncode(json['property']) : null,
      'armor_category': json['armorCategory'],
      'armor_class': json['ac'],
      'stealth_disadvantage': json['stealthDisadvantage'] == true ? 1 : 0,
      'strength_requirement': json['strReq'],
      'description': json['entries'] is List ? (json['entries'] as List).join('\n') : json['entries']?.toString() ?? '',
      'source': json['source'] ?? 'DMG',
      'page': json['page'] ?? 1,
      'is_custom': 0,
      'version': '1.0',
    };
  }

  Map<String, dynamic> _parseLocationFrom5eTools(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['name']?.toLowerCase()?.replaceAll(' ', '_'),
      'name': json['name'],
      'location_type': json['type'],
      'description': json['entries'] is List ? (json['entries'] as List).join('\n') : json['entries']?.toString() ?? '',
      'region': json['region'],
      'parent_location_id': json['parent'],
      'coordinates': json['coordinates'] != null ? jsonEncode(json['coordinates']) : null,
      'notable_npcs': json['notableNpcs'] != null ? jsonEncode(json['notableNpcs']) : null,
      'notable_locations': json['notableLocations'] != null ? jsonEncode(json['notableLocations']) : null,
      'quests': json['quests'] != null ? jsonEncode(json['quests']) : null,
      'encounters': json['encounters'] != null ? jsonEncode(json['encounters']) : null,
      'source': json['source'] ?? 'PHB',
      'page': json['page'] ?? 1,
      'is_custom': 0,
      'version': '1.0',
    };
  }

  // --- Demo-Daten Import Methoden ---
  
  Future<int> importDemoMonsters() async {
    try {
      print('Starte Demo-Monster-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_monsters');
      
      int importedCount = 0;
      
      for (final monsterData in DndDemoData.demoMonsters) {
        try {
          final monster = OfficialMonster.fromMap(monsterData);
          await db.insert('official_monsters', monster.toMap());
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Demo-Monsters "${monsterData['name']}": $e');
        }
      }
      
      print('Demo-Monster-Import abgeschlossen: $importedCount Monster importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Demo-Monster-Import: $e');
      return 0;
    }
  }

  Future<int> importDemoSpells() async {
    try {
      print('Starte Demo-Spells-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_spells');
      
      int importedCount = 0;
      
      for (final spellData in DndDemoData.demoSpells) {
        try {
          await db.insert('official_spells', spellData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import der Demo-Spells "${spellData['name']}": $e');
        }
      }
      
      print('Demo-Spells-Import abgeschlossen: $importedCount Spells importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Demo-Spells-Import: $e');
      return 0;
    }
  }

  Future<int> importDemoClasses() async {
    try {
      print('Starte Demo-Klassen-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_classes');
      
      int importedCount = 0;
      
      for (final classData in DndDemoData.demoClasses) {
        try {
          await db.insert('official_classes', classData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import der Demo-Klasse "${classData['name']}": $e');
        }
      }
      
      print('Demo-Klassen-Import abgeschlossen: $importedCount Klassen importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Demo-Klassen-Import: $e');
      return 0;
    }
  }

  Future<int> importDemoRaces() async {
    try {
      print('Starte Demo-Völker-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_races');
      
      int importedCount = 0;
      
      for (final raceData in DndDemoData.demoRaces) {
        try {
          await db.insert('official_races', raceData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import der Demo-Volkes "${raceData['name']}": $e');
        }
      }
      
      print('Demo-Völker-Import abgeschlossen: $importedCount Völker importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Demo-Völker-Import: $e');
      return 0;
    }
  }

  Future<int> importDemoItems() async {
    try {
      print('Starte Demo-Items-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_items');
      
      int importedCount = 0;
      
      for (final itemData in DndDemoData.demoItems) {
        try {
          await db.insert('official_items', itemData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import der Demo-Items "${itemData['name']}": $e');
        }
      }
      
      print('Demo-Items-Import abgeschlossen: $importedCount Items importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Demo-Items-Import: $e');
      return 0;
    }
  }

  Future<int> importDemoLocations() async {
    try {
      print('Starte Demo-Orte-Import...');
      
      // Bestehende Daten löschen
      final db = await _db.database;
      await db.execute('DELETE FROM official_locations');
      
      int importedCount = 0;
      
      for (final locationData in DndDemoData.demoLocations) {
        try {
          await db.insert('official_locations', locationData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import der Demo-Ortes "${locationData['name']}": $e');
        }
      }
      
      print('Demo-Orte-Import abgeschlossen: $importedCount Orte importiert');
      return importedCount;
    } catch (e) {
      print('Fehler beim Demo-Orte-Import: $e');
      return 0;
    }
  }

  // --- Hilfsmethoden ---
  
  Future<int> getTotalCount(String tableName) async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int? ?? 0;
  }

  Future<String?> getLatestVersion(String tableName) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT version FROM $tableName ORDER BY id DESC LIMIT 1'
    );
    return result.first['version'] as String?;
  }

  Future<bool> hasData() async {
    final monsterCount = await getTotalCount('official_monsters');
    return monsterCount > 0;
  }

  Future<void> clearAllOfficialData() async {
    final db = await _db.database;
    await db.execute('DELETE FROM official_monsters');
    await db.execute('DELETE FROM official_spells');
    await db.execute('DELETE FROM official_classes');
    await db.execute('DELETE FROM official_races');
    await db.execute('DELETE FROM official_items');
    await db.execute('DELETE FROM official_locations');
  }
}
