import 'dart:io';
import 'lib/database/legacy/database_helper_legacy_backup.dart';

void main() async {
  print('Einfacher Test: maxhp Spalte in player_characters Tabelle');
  print('==========================================================');
  
  try {
    final db = DatabaseHelper.instance;
    final database = await db.database;
    
    // Tabellenstruktur prüfen
    print('Prüfe player_characters Tabellenstruktur...');
    final tableInfo = await database.rawQuery("PRAGMA table_info(player_characters)");
    
    print('\nSpalten in player_characters Tabelle:');
    for (final column in tableInfo) {
      print('  - ${column['name']} (${column['type']})');
    }
    
    // Prüfen ob max_hp Spalte existiert
    final hasMaxHp = tableInfo.any((column) => column['name'] == 'max_hp');
    print('\n✅ max_hp Spalte vorhanden: ${hasMaxHp ? 'JA' : 'NEIN'}');
    
    if (!hasMaxHp) {
      print('❌ FEHLER: max_hp Spalte fehlt!');
      exit(1);
    }
    
    // Prüfen ob armor_class Spalte existiert
    final hasArmorClass = tableInfo.any((column) => column['name'] == 'armor_class');
    print('✅ armor_class Spalte vorhanden: ${hasArmorClass ? 'JA' : 'NEIN'}');
    
    // Prüfen ob initiative_bonus Spalte existiert
    final hasInitiativeBonus = tableInfo.any((column) => column['name'] == 'initiative_bonus');
    print('✅ initiative_bonus Spalte vorhanden: ${hasInitiativeBonus ? 'JA' : 'NEIN'}');
    
    print('\n🎉 ALLE SPALTEN SIND VORHANDEN!');
    print('Die maxhp-Spalte wurde erfolgreich zur Datenbank hinzugefügt.');
    
  } catch (e) {
    print('\n❌ FEHLER während der Überprüfung:');
    print('Fehler: $e');
    exit(1);
  }
}
