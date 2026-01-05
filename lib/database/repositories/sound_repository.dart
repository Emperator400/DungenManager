import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/sound_entity.dart';
import '../../models/sound.dart';
import 'base_repository.dart';

/// Repository für Sound-Operationen
/// 
/// @deprecated Dieses Repository wird durch SoundModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class SoundRepository extends BaseRepository<SoundEntity> {
  SoundRepository(DatabaseConnection databaseConnection) 
      : super(databaseConnection);

  @override
  String get tableName => SoundEntity.tableName;

  @override
  DatabaseEntity<SoundEntity> get entityFactory => SoundEntityEntityFactory();

  /// Spezielle Sound-spezifische Abfragen
  Future<List<Sound>> findByType(String type) async {
    final maps = await findWhere(
      where: 'type = ?',
      whereArgs: [type],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Sound>> findByCategory(String category) async {
    final maps = await findWhere(
      where: 'category = ?',
      whereArgs: [category],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Sound>> searchSounds(String query) async {
    final maps = await search(query, fields: ['name', 'description']);
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Sound>> findFavoriteSounds() async {
    final maps = await findWhere(
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Sound>> findByDurationRange(double minDuration, double maxDuration) async {
    final maps = await findWhere(
      where: 'duration >= ? AND duration <= ?',
      whereArgs: [minDuration, maxDuration],
      orderBy: 'duration ASC',
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Sound>> findByVolumeRange(double minVolume, double maxVolume) async {
    final maps = await findWhere(
      where: 'volume >= ? AND volume <= ?',
      whereArgs: [minVolume, maxVolume],
      orderBy: 'volume ASC',
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }
}

/// Entity Factory für SoundEntity
class SoundEntityEntityFactory extends DatabaseEntity<SoundEntity> {
  SoundEntityEntityFactory();
  
  @override
  SoundEntity fromDatabaseMap(Map<String, dynamic> map) {
    return SoundEntity.fromMap(map);
  }

  @override
  Map<String, dynamic> toDatabaseMap() {
    return {};
  }
  
  @override
  String get tableName => SoundEntity.tableName;
  
  @override
  List<String> get databaseFields => [
    'id', 'name', 'description', 'type', 'category', 'file_path',
    'duration', 'volume', 'is_looping', 'is_favorite', 'source_type',
    'source_id', 'version', 'created_at', 'updated_at'
  ];
  
  @override
  bool get isValid => true;
  
  @override
  List<String> get validationErrors => [];
  
  @override
  List<String> get createTableSql => [SoundEntity.createTableSql()];
}
