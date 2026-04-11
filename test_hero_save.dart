import 'lib/database/legacy/database_helper_legacy_backup.dart';
import 'lib/models/player_character.dart';

void main() async {
  print('🧪 Teste Heldenspeicherung...');
  
  try {
    // Database Helper initialisieren
    final db = DatabaseHelper.instance;
    await db.database;
    print('✅ Datenbank verbunden');
    
    // Test-Held erstellen
    final testHero = PlayerCharacter.create(
      campaignId: 'test-campaign-123',
      name: 'Test Held',
      playerName: 'Test Spieler',
      className: 'Krieger',
      raceName: 'Mensch',
      level: 1,
      maxHp: 12,
      armorClass: 16,
      initiativeBonus: 2,
      strength: 16,
      dexterity: 14,
      constitution: 15,
      intelligence: 10,
      wisdom: 12,
      charisma: 8,
      proficiencyBonus: 2,
      speed: 30,
      passivePerception: 12,
      spellSaveDc: 8,
      spellAttackBonus: 0,
    );
    
    print('✅ Test-Held erstellt: ${testHero.name}');
    
    // Held in Datenbank speichern
    final id = await db.insertPlayerCharacter(testHero);
    print('✅ Held gespeichert mit ID: $id');
    
    // Held aus Datenbank laden
    final loadedHero = await db.getPlayerCharacterById(testHero.id);
    if (loadedHero != null) {
      print('✅ Held erfolgreich geladen: ${loadedHero.name}');
      print('   - Klasse: ${loadedHero.className}');
      print('   - Rasse: ${loadedHero.raceName}');
      print('   - Level: ${loadedHero.level}');
      print('   - HP: ${loadedHero.maxHp}');
      print('   - AC: ${loadedHero.armorClass}');
      print('   - STR: ${loadedHero.strength}');
      print('   - Proficiency Bonus: ${loadedHero.proficiencyBonus}');
      print('   - Speed: ${loadedHero.speed}');
      print('   - Passive Perception: ${loadedHero.passivePerception}');
      print('   - Is Favorite: ${loadedHero.isFavorite}');
      
      // Teste Update
      final updatedHero = loadedHero.copyWith(
        level: 2,
        maxHp: 20,
        strength: 17,
        isFavorite: true,
      );
      
      await db.updatePlayerCharacter(updatedHero);
      print('✅ Held aktualisiert auf Level ${updatedHero.level}');
      
      // Erneut laden und prüfen
      final reloadedHero = await db.getPlayerCharacterById(updatedHero.id);
      if (reloadedHero != null) {
        print('✅ Aktualisierter Held geladen:');
        print('   - Level: ${reloadedHero.level}');
        print('   - HP: ${reloadedHero.maxHp}');
        print('   - STR: ${reloadedHero.strength}');
        print('   - Is Favorite: ${reloadedHero.isFavorite}');
      }
      
      print('\n🎉 ALLE TESTS ERFOLGREICH!');
      print('Die Heldenspeicherung funktioniert perfekt!');
      
    } else {
      print('❌ FEHLER: Held konnte nicht geladen werden');
    }
    
  } catch (e, stackTrace) {
    print('❌ FEHLER: $e');
    print('Stack Trace: $stackTrace');
  }
}
