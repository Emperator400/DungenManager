import 'package:uuid/uuid.dart';

class UuidService {
  static final UuidService _instance = UuidService._internal();
  factory UuidService() => _instance;
  UuidService._internal();
  
  final Uuid _uuid = const Uuid();
  
  /// Generiert eine neue UUID
  String generateId() => _uuid.v4();
  
  /// Prüft ob ein String eine gültige UUID ist
  bool isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    try {
      Uuid.parse(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
