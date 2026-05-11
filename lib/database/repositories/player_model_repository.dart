import '../../models/player.dart';
import '../core/database_connection.dart';
import 'model_repository.dart';

class PlayerModelRepository extends ModelRepository<Player> {
  PlayerModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => Player.tableName;

  @override
  Map<String, dynamic> toDatabaseMap(Player model) => model.toDatabaseMap();

  @override
  Player fromDatabaseMap(Map<String, dynamic> map) => Player.fromDatabaseMap(map);

  Future<List<Player>> findByName(String query) => findWhere(
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );

  Future<Player?> findByExactName(String name) async {
    final results = await findWhere(
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Player>> findAllSorted() => findAll(orderBy: 'name ASC');
}
