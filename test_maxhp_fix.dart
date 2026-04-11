import 'lib/database/legacy/database_helper_legacy_backup.dart';
import 'lib/models/player_character.dart';
import 'package:uuid/uuid.dart';

void main() async {
  print('Test: maxhp Spaltenkorrektur für PlayerCharacter');
  print('===========================================');
  
  try {
    final db = DatabaseHelper.instance;
    final database = await db.database;
    
    // 1. Tabellenstruktur prüfen
    print('1. Prüfe player_characters Tabellenstruktur...');
    final tableInfo = await database.rawQuery("PRAGMA table_info(player_characters)");
    
    print('\nSpalten in player_characters Tabelle:');
    for (final column in tableInfo) {
      print('  - ${column['name']} (${column['type']})');
    }
    
    // 2. Prüfen ob max_hp Spalte existiert
    final hasMaxHp = tableInfo.any((column) => column['name'] == 'max_hp');
    print('\n2. max_hp Spalte vorhanden: ${hasMaxHp ? 'JA' : 'NEIN'}');
    
    if (!hasMaxHp) {
      print('FEHLER: max_hp Spalte fehlt!');
      return;
    }
    
    // 3. Test PlayerCharacter erstellen
    print('\n3. Erstelle Test PlayerCharacter...');
    final uuid = Uuid();
    final testCharacter = PlayerCharacter(
      id: uuid.v4(),
      campaignId: 'test-campaign',
      name: 'Test Held',
      playerName: 'Test Spieler',
      className: 'Krieger',
      raceName: 'Mensch',
      level: 1,
      maxHp: 12, // Dieses Feld sollte jetzt funktionieren
      armorClass: 16,
      initiativeBonus: 1,
      imagePath: null,
      strength: 16,
      dexterity: 14,
      constitution: 14,
      intelligence: 10,
      wisdom: 12,
      charisma: 10,
      proficientSkills: ['Athletik', 'Einschüchtern'],
      attackList: [],
      inventory: [],
      gold: 0.0,
      silver: 0.0,
      copper: 0.0,
      sourceType: 'custom',
      version: '1.0',
      description: 'Ein Testheld zur Überprüfung der maxhp Spalte',
    );
    
    print('PlayerCharacter erstellt mit maxHp: ${testCharacter.maxHp}');
    
    // 4. In Datenbank speichern
    print('\n4. Speichere PlayerCharacter in Datenbank...');
    final id = await db.insertPlayerCharacter(testCharacter);
    print('Character mit ID $id gespeichert');
    
    // 5. Aus Datenbank laden
    print('\n5. Lade PlayerCharacter aus Datenbank...');
    final loadedCharacter = await db.getPlayerCharacterById(id.toString());
    
    if (loadedCharacter != null) {
      print('Character geladen:');
      print('  - Name: ${loadedCharacter.name}');
      print('  - maxHp: ${loadedCharacter.maxHp}');
      print('  - armorClass: ${loadedCharacter.armorClass}');
      print('  - initiativeBonus: ${loadedCharacter.initiativeBonus}');
      
      if (loadedCharacter.maxHp == testCharacter.maxHp) {
        print('\n✅ ERFOLG: maxHp wurde korrekt gespeichert und geladen!');
      } else {
        print('\n❌ FEHLER: maxHp wurde nicht korrekt gespeichert!');
        print('   Erwartet: ${testCharacter.maxHp}');
        print('   Tatsächlich: ${loadedCharacter.maxHp}');
      }
    } else {
      print('\n❌ FEHLER: Character konnte nicht aus Datenbank geladen werden!');
    }
    
    // 6. Aufräumen
    print('\n6. Räume Testdaten auf...');
    await db.deletePlayerCharacter(testCharacter.id.toString());
    print('Testcharacter gelöscht');
    
    print('\n===========================================');
    print('Test abgeschlossen');
    
  } catch (e, stackTrace) {
    print('\n❌ FEHLER während des Tests:');
    print('Fehler: $e');
    print('Stack Trace: $stackTrace');
  }
}
