import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/item_entity.dart';
import '../../models/item.dart';
import 'base_repository.dart';

/// Repository für Item-Operationen
/// 
/// @deprecated Dieses Repository wird durch ItemModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class ItemRepository extends BaseRepository<ItemEntity> {
  ItemRepository(DatabaseConnection databaseConnection) 
      : super(databaseConnection);

  @override
  String get tableName => ItemEntity.tableName;

  @override
  DatabaseEntity<ItemEntity> get entityFactory => ItemEntityEntityFactory();

  /// Spezielle Item-spezifische Abfragen
  Future<List<Item>> findByType(String type) async {
    final maps = await findWhere(
      where: 'type = ?',
      whereArgs: [type],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Item>> findByRarity(String rarity) async {
    final maps = await findWhere(
      where: 'rarity = ?',
      whereArgs: [rarity],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Item>> findByCategory(String category) async {
    final maps = await findWhere(
      where: 'category = ?',
      whereArgs: [category],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final maps = await search(query, fields: ['name', 'description']);
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Item>> findFavoriteItems() async {
    final maps = await findWhere(
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<Item>> findByValueRange(double minValue, double maxValue) async {
    final maps = await findWhere(
      where: 'value >= ? AND value <= ?',
      whereArgs: [minValue, maxValue],
      orderBy: 'value ASC',
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }
}

/// Entity Factory für ItemEntity
class ItemEntityEntityFactory extends DatabaseEntity<ItemEntity> {
  ItemEntityEntityFactory();
  
  @override
  ItemEntity fromDatabaseMap(Map<String, dynamic> map) {
    return ItemEntity.fromMap(map);
  }

  @override
  Map<String, dynamic> toDatabaseMap() {
    // Hier müssten wir eine Instanz haben, aber wir verwenden das differently
    // Wir implementieren es als placeholder
    return {};
  }
  
  @override
  String get tableName => ItemEntity.tableName;
  
  @override
  List<String> get databaseFields => [
    'id', 'name', 'description', 'type', 'category', 'rarity', 'value',
    'weight', 'is_magical', 'is_favorite', 'source_type', 'source_id',
    'version', 'created_at', 'updated_at'
  ];
  
  @override
  bool get isValid => true;
  
  @override
  List<String> get validationErrors => [];
  
  @override
  List<String> get createTableSql => [ItemEntity.createTableSql()];
}
