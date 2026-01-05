import '../core/database_connection.dart';
import '../../models/item.dart';
import 'model_repository.dart';

/// Repository für Item Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Item Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class ItemModelRepository extends ModelRepository<Item> {
  ItemModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'items';

  @override
  Map<String, dynamic> toDatabaseMap(Item item) {
    return item.toDatabaseMap();
  }

  @override
  Item fromDatabaseMap(Map<String, dynamic> map) {
    return Item.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Items nach Typ
  Future<List<Item>> findByType(ItemType type) async {
    return await findWhere(
      where: 'item_type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'name ASC',
    );
  }

  /// Findet Items nach Rarität
  Future<List<Item>> findByRarity(String rarity) async {
    return await findWhere(
      where: 'rarity = ?',
      whereArgs: [rarity],
      orderBy: 'name ASC',
    );
  }

  /// Sucht Items mit komplexen Filtern
  Future<List<Item>> searchItems({
    String? searchTerm,
    ItemType? type,
    String? rarity,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%']);
    }

    if (type != null) {
      whereConditions.add('item_type = ?');
      whereArgs.add(type.toString().split('.').last);
    }

    if (rarity != null) {
      whereConditions.add('rarity = ?');
      whereArgs.add(rarity);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== ITEM-STATISTIKEN =====

  /// Holt umfassende Statistiken über Items
  Future<Map<String, dynamic>> getItemStatistics() async {
    // Gesamtzahl der Items
    final totalCount = await count();
    
    // Typ-Verteilung
    final typeDistributionResult = await rawQuery('''
      SELECT 
        item_type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY item_type
      ORDER BY item_type
    ''');
    
    // Raritäten-Verteilung
    final rarityDistributionResult = await rawQuery('''
      SELECT 
        rarity,
        COUNT(*) as count
      FROM $tableName
      GROUP BY rarity
      ORDER BY rarity
    ''');

    // Favorisierte Items (aus Datenbank-Statistik)
    final favoriteResult = await rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE is_favorite = 1');
    final favoriteCount = favoriteResult.first['count'] as int? ?? 0;

    return {
      'totalItems': totalCount,
      'typeDistribution': typeDistributionResult,
      'rarityDistribution': rarityDistributionResult,
      'favoriteItems': favoriteCount,
    };
  }

  /// ===== ADVANCED SUCHEN =====

  /// Items nach Namen suchen
  Future<List<Item>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

}
