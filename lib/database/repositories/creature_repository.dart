import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/creature_entity.dart';
import 'base_repository.dart';

/// Repository für Creature-Entitäten
/// Bietet CRUD-Operationen für Creatures
/// 
/// @deprecated Dieses Repository wird durch CreatureModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class CreatureRepository extends BaseRepository<CreatureEntity> {
  static CreatureRepository? _instance;
  
  CreatureRepository(DatabaseConnection connection) : super(connection);
  
  /// Singleton-Instanz für Zugriff von überall
  static CreatureRepository get instance {
    _instance ??= CreatureRepository(DatabaseConnection.instance);
    return _instance!;
  }
  
  @override
  String get tableName => 'creatures';
  
  @override
  DatabaseEntity<CreatureEntity> get entityFactory => CreatureEntity.create(
    id: '',
    name: '',
    maxHp: 10,
    armorClass: 10,
    speed: '30 ft',
    attacks: '',
    initiativeBonus: 0,
    strength: 10,
    dexterity: 10,
    constitution: 10,
    intelligence: 10,
    wisdom: 10,
    charisma: 10,
    isPlayer: false,
  );
  
  // Spezielle Methoden für Creatures (Alias für Basismethoden)
  
  /// Sucht Creatures nach Name (benutzt Basismethode)
  Future<List<CreatureEntity>> searchCreatures(String query) async {
    return search(query, fields: ['name']);
  }
  
  /// Findet Creature nach ID (Alias für findById)
  Future<CreatureEntity?> getById(String id) async {
    return findById(id);
  }
  
  /// Findet Creatures nach Campaign ID
  Future<List<CreatureEntity>> getByCampaignId(String campaignId) async {
    return findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'name ASC',
    );
  }
  
  /// Sucht Creatures nach Source Type
  Future<List<CreatureEntity>> findBySourceType(String sourceType) async {
    final db = await connection.database;
    final maps = await db.query(
      tableName,
      where: 'source_type = ?',
      whereArgs: [sourceType],
      orderBy: 'name ASC',
    );
    return maps.map((map) => entityFactory.fromDatabaseMap(map)).toList();
  }
  
  /// Findet Favoriten-Creatures
  Future<List<CreatureEntity>> findFavoriteCreatures() async {
    final db = await connection.database;
    final maps = await db.query(
      tableName,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => entityFactory.fromDatabaseMap(map)).toList();
  }
  
  /// Sucht Creatures nach Challenge Rating
  Future<List<CreatureEntity>> findByChallengeRating(int cr) async {
    final db = await connection.database;
    final maps = await db.query(
      tableName,
      where: 'challenge_rating = ?',
      whereArgs: [cr],
      orderBy: 'name ASC',
    );
    return maps.map((map) => entityFactory.fromDatabaseMap(map)).toList();
  }
  
  /// Sucht Creatures nach Typ
  Future<List<CreatureEntity>> findByType(String type) async {
    final db = await connection.database;
    final maps = await db.query(
      tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return maps.map((map) => entityFactory.fromDatabaseMap(map)).toList();
  }
}
