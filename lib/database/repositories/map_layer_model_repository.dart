import '../core/database_connection.dart';
import '../../models/map_layer.dart';
import 'model_repository.dart';

class MapLayerModelRepository extends ModelRepository<MapLayer> {
  MapLayerModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => MapLayer.tableName;

  @override
  MapLayer fromDatabaseMap(Map<String, dynamic> map) =>
      MapLayer.fromDatabaseMap(map);

  @override
  Map<String, dynamic> toDatabaseMap(MapLayer model) => model.toDatabaseMap();

  Future<List<MapLayer>> findByContext(String campaignId, String? ortId) =>
      findWhere(
        where: ortId == null
            ? 'campaign_id = ? AND ort_id IS NULL'
            : 'campaign_id = ? AND ort_id = ?',
        whereArgs: ortId == null ? [campaignId] : [campaignId, ortId],
        orderBy: 'sort_order ASC, created_at ASC',
      );

  Future<void> deleteByOrtId(String ortId) async {
    final db = await connection.database;
    await db.delete(tableName, where: 'ort_id = ?', whereArgs: [ortId]);
  }
}
