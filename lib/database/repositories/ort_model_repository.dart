import '../core/database_connection.dart';
import '../../models/ort.dart';
import 'model_repository.dart';

class OrtModelRepository extends ModelRepository<Ort> {
  OrtModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'orte';

  @override
  Map<String, dynamic> toDatabaseMap(Ort ort) => ort.toDatabaseMap();

  @override
  Ort fromDatabaseMap(Map<String, dynamic> map) => Ort.fromDatabaseMap(map);

  Future<List<Ort>> findByCampaign(String campaignId) => findWhere(
        where: 'campaign_id = ?',
        whereArgs: [campaignId],
        orderBy: 'sort_order ASC, created_at ASC',
      );

  /// Alle Kopien eines Template-Ortes über alle Kampagnen
  Future<List<Ort>> findByTemplateOrtId(String templateOrtId) => findWhere(
        where: 'template_ort_id = ?',
        whereArgs: [templateOrtId],
      );

  Future<List<Ort>> findVisitedByCampaign(String campaignId) => findWhere(
        where: 'campaign_id = ? AND last_visited_at IS NOT NULL',
        whereArgs: [campaignId],
        orderBy: 'last_visited_at DESC',
      );
}
