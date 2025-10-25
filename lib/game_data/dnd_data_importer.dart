// lib/game_data/dnd_data_importer.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../models/official_monster.dart';
import '../models/official_spell.dart';
import '../models/creature.dart';
import 'dnd_demo_data.dart';

class DndDataImporter {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final String baseUrl = 'https://raw.githubusercontent.com/5etools-mirror-1/5etools-mirror-1.github.io/master/data/';

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
      await _db.clearOfficialData('official_monsters');
      
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
            final monster = OfficialMonster.from5eToolsJson(monsterData);
            await _db.insertOfficialMonster(monster.toMap());
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
      await _db.clearOfficialData('official_spells');
      
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
            final spell = OfficialSpell.from5eToolsJson(spellData);
            await _db.insertOfficialSpell(spell.toMap());
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
      await _db.clearOfficialData('official_classes');
      
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
          final classMap = _parseClassFrom5eTools(classData);
          await _db.insertOfficialClass(classMap);
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
      await _db.clearOfficialData('official_races');
      
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
          final raceMap = _parseRaceFrom5eTools(raceData);
          await _db.insertOfficialRace(raceMap);
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
      await _db.clearOfficialData('official_items');
      
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
            final itemMap = _parseItemFrom5eTools(itemData);
            await _db.insertOfficialItem(itemMap);
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
      await _db.clearOfficialData('official_locations');
      
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
          final locationMap = _parseLocationFrom5eTools(locationData);
          await _db.insertOfficialLocation(locationMap);
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
      await _db.clearOfficialData('official_monsters');
      
      int importedCount = 0;
      
      for (final monsterData in DndDemoData.demoMonsters) {
        try {
          await _db.insertOfficialMonster(monsterData);
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
      await _db.clearOfficialData('official_spells');
      
      int importedCount = 0;
      
      for (final spellData in DndDemoData.demoSpells) {
        try {
          await _db.insertOfficialSpell(spellData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Demo-Spells "${spellData['name']}": $e');
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
      await _db.clearOfficialData('official_classes');
      
      int importedCount = 0;
      
      for (final classData in DndDemoData.demoClasses) {
        try {
          await _db.insertOfficialClass(classData);
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
      await _db.clearOfficialData('official_races');
      
      int importedCount = 0;
      
      for (final raceData in DndDemoData.demoRaces) {
        try {
          await _db.insertOfficialRace(raceData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Demo-Volkes "${raceData['name']}": $e');
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
      await _db.clearOfficialData('official_items');
      
      int importedCount = 0;
      
      for (final itemData in DndDemoData.demoItems) {
        try {
          await _db.insertOfficialItem(itemData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Demo-Items "${itemData['name']}": $e');
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
      await _db.clearOfficialData('official_locations');
      
      int importedCount = 0;
      
      for (final locationData in DndDemoData.demoLocations) {
        try {
          await _db.insertOfficialLocation(locationData);
          importedCount++;
        } catch (e) {
          print('Fehler beim Import des Demo-Ortes "${locationData['name']}": $e');
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
    return await _db.getOfficialDataCount(tableName);
  }

  Future<String?> getLatestVersion(String tableName) async {
    return await _db.getLatestVersion(tableName);
  }

  Future<bool> hasData() async {
    final monsterCount = await getTotalCount('official_monsters');
    return monsterCount > 0;
  }

  Future<void> clearAllOfficialData() async {
    await _db.clearOfficialData('official_monsters');
    await _db.clearOfficialData('official_spells');
    await _db.clearOfficialData('official_classes');
    await _db.clearOfficialData('official_races');
    await _db.clearOfficialData('official_items');
    await _db.clearOfficialData('official_locations');
  }

  // --- NEU: Migrationsmethoden für Unified Bestiarum ---
  
  /// Migriert bestehende creatures auf das neue Schema
  Future<void> migrateCreaturesToUnifiedSchema() async {
    try {
      print('Starte Migration der creatures auf Unified Bestiarum...');
      
      // Prüfen, ob Migration bereits durchgeführt wurde
      final db = await _db.database;
      final tables = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['creatures']);
      if (tables.isEmpty) {
        print('Tabelle creatures existiert nicht, Migration nicht notwendig');
        return;
      }
      
      // Prüfen, ob die neuen Felder bereits existieren
      final pragmaResult = await db.rawQuery('PRAGMA table_info(creatures)');
      final columns = pragmaResult.map((row) => row['name'] as String).toList();
      
      if (!columns.contains('source_type') || !columns.contains('source_id') || 
          !columns.contains('is_favorite') || !columns.contains('version')) {
        
        print('Führe Migration für creatures durch...');
        
        // Hole alle bestehenden creatures
        final existingCreatures = await db.query('creatures');
        int migratedCount = 0;
        
        for (final creatureData in existingCreatures) {
          final isCustom = (creatureData['is_custom'] ?? 1) == 1;
          final hasOfficialMonsterId = creatureData['official_monster_id'] != null;
          
          // Bestimme den source_type basierend auf vorhandenen Daten
          String sourceType = 'custom';
          String? sourceId;
          
          if (hasOfficialMonsterId && !isCustom) {
            sourceType = 'official';
            sourceId = creatureData['official_monster_id']?.toString();
          } else if (hasOfficialMonsterId && isCustom) {
            sourceType = 'hybrid';
            sourceId = creatureData['official_monster_id']?.toString();
          }
          
          // Aktualisiere den Datensatz mit den neuen Feldern
          await db.update(
            'creatures',
            {
              'source_type': sourceType,
              'source_id': sourceId,
              'is_favorite': 0, // Standardmäßig nicht favorisiert
              'version': '1.0', // Startversion
            },
            where: 'id = ?',
            whereArgs: [creatureData['id'].toString()],
          );
          
          migratedCount++;
        }
        
        print('Migration abgeschlossen: $migratedCount creatures migriert');
        
        // Erstelle Performance-Indizes, falls sie noch nicht existieren
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_creatures_source_type ON creatures(source_type)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_creatures_is_favorite ON creatures(is_favorite)');
          print('Performance-Indizes erstellt');
        } catch (e) {
          print('Fehler beim Erstellen der Indizes: $e');
        }
        
      } else {
        print('Migration bereits durchgeführt oder nicht notwendig');
      }
      
    } catch (e) {
      print('Fehler bei der Migration der creatures: $e');
      rethrow;
    }
  }
  
  /// Synchronisiert offizielle Monster mit der creatures-Tabelle
  Future<Map<String, int>> syncOfficialMonstersToCreatures() async {
    try {
      print('Starte Synchronisation offizieller Monster mit creatures...');
      
      final results = <String, int>{
        'total': 0,
        'synced': 0,
        'updated': 0,
        'skipped': 0,
      };
      
      // Hole alle offiziellen Monster
      final officialMonsters = await _db.getAllOfficialMonsters(limit: 1000);
      results['total'] = officialMonsters.length;
      
      for (final officialData in officialMonsters) {
        final officialMonster = OfficialMonster.fromMap(officialData);
        
        // Prüfe, ob dieses Monster bereits als Creature existiert
        final existing = await (await _db.database).query(
          'creatures',
          where: 'source_id = ? AND source_type = ?',
          whereArgs: [officialMonster.id, 'official'],
        );
        
        if (existing.isEmpty) {
          // Neues Creature aus offiziellem Monster erstellen
          final creature = Creature.fromOfficialMonster(
            officialMonsterId: officialMonster.id,
            name: officialMonster.name,
            maxHp: officialMonster.hitPoints,
            armorClass: int.tryParse(officialMonster.armorClass) ?? 10,
            speed: officialMonster.speed,
            strength: officialMonster.strength,
            dexterity: officialMonster.dexterity,
            constitution: officialMonster.constitution,
            intelligence: officialMonster.intelligence,
            wisdom: officialMonster.wisdom,
            charisma: officialMonster.charisma,
            size: officialMonster.size,
            type: officialMonster.type,
            subtype: officialMonster.subtype,
            alignment: officialMonster.alignment,
            challengeRating: officialMonster.challengeRating.toInt(),
            specialAbilities: officialMonster.specialAbilities.isNotEmpty 
                ? officialMonster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
                : null,
            legendaryActions: officialMonster.legendaryActions?.isNotEmpty == true
                ? officialMonster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
                : null,
            description: officialMonster.description,
          );
          
          await _db.insertCreature(creature);
          results['synced'] = (results['synced'] ?? 0) + 1;
        } else {
          // Prüfe, ob ein Update notwendig ist
          final existingCreature = Creature.fromMap(existing.first);
          final needsUpdate = existingCreature.name != officialMonster.name ||
              existingCreature.maxHp != officialMonster.hitPoints ||
              existingCreature.armorClass != int.tryParse(officialMonster.armorClass) ||
              existingCreature.speed != officialMonster.speed ||
              existingCreature.strength != officialMonster.strength ||
              existingCreature.dexterity != officialMonster.dexterity ||
              existingCreature.constitution != officialMonster.constitution ||
              existingCreature.intelligence != officialMonster.intelligence ||
              existingCreature.wisdom != officialMonster.wisdom ||
              existingCreature.charisma != officialMonster.charisma;
          
          if (needsUpdate) {
            // Aktualisiere das bestehende Creature
            final updatedCreature = existingCreature.copyWith(
              name: officialMonster.name,
              maxHp: officialMonster.hitPoints,
              armorClass: int.tryParse(officialMonster.armorClass),
              speed: officialMonster.speed,
              strength: officialMonster.strength,
              dexterity: officialMonster.dexterity,
              constitution: officialMonster.constitution,
              intelligence: officialMonster.intelligence,
              wisdom: officialMonster.wisdom,
              charisma: officialMonster.charisma,
              size: officialMonster.size,
              type: officialMonster.type,
              subtype: officialMonster.subtype,
              alignment: officialMonster.alignment,
              challengeRating: officialMonster.challengeRating.toInt(),
              specialAbilities: officialMonster.specialAbilities.isNotEmpty 
                  ? officialMonster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
                  : null,
              legendaryActions: officialMonster.legendaryActions?.isNotEmpty == true
                  ? officialMonster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
                  : null,
              description: officialMonster.description,
              version: officialMonster.version ?? '1.0',
            );
            
            await _db.updateCreature(updatedCreature);
            results['updated'] = (results['updated'] ?? 0) + 1;
          } else {
            results['skipped'] = (results['skipped'] ?? 0) + 1;
          }
        }
        
        if (results['synced']! + results['updated']! + results['skipped']! % 50 == 0) {
          print('Synchronisations-Fortschritt: ${results['synced']} neu, ${results['updated']} aktualisiert, ${results['skipped']} übersprungen von ${results['total']}');
        }
      }
      
      print('Synchronisation abgeschlossen: ${results['synced']} neu, ${results['updated']} aktualisiert, ${results['skipped']} übersprungen');
      return results;
      
    } catch (e) {
      print('Fehler bei der Synchronisation offizieller Monster: $e');
      rethrow;
    }
  }
}
