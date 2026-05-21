import 'package:sqflite/sqflite.dart';

import '../../models/dm_profile.dart';
import '../core/database_connection.dart';

class DmProfileModelRepository {
  final DatabaseConnection _connection;

  DmProfileModelRepository(this._connection);

  Future<DmProfile> getOrCreate() async {
    final db = await _connection.database;
    final rows = await db.query(
      DmProfile.tableName,
      where: 'id = ?',
      whereArgs: [DmProfile.fixedId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return DmProfile.fromDatabaseMap(rows.first);
    }
    final profile = DmProfile.empty();
    await db.insert(DmProfile.tableName, profile.toDatabaseMap());
    return profile;
  }

  Future<DmProfile> upsertProfile(DmProfile profile) async {
    final db = await _connection.database;
    await db.insert(
      DmProfile.tableName,
      profile.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
    return profile;
  }
}
