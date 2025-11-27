// Dart Core
import 'dart:async';

// Externe Packages
import 'package:flutter/foundation.dart';

/// Spezifische Exception-Typen für DungenManager Services
/// Ersetzt generische Exception() Aufrufe für besseres Error-Handling

/// Basis-Exception für alle Service-spezifischen Fehler
abstract class ServiceException implements Exception {
  final String message;
  final String? operation;
  final dynamic originalError;
  
  const ServiceException(
    this.message, {
    this.operation,
    this.originalError,
  });
  
  @override
  String toString() => 'ServiceException: $message${operation != null ? ' (Operation: $operation)' : ''}';
}

/// Database-spezifische Fehler
class DatabaseException extends ServiceException {
  const DatabaseException(
    super.message, {
    super.operation,
    super.originalError,
  });
  
  factory DatabaseException.fromSqliteException(
    String operation,
    dynamic sqliteException,
  ) {
    return DatabaseException(
      'Datenbankfehler bei $operation: ${sqliteException.toString()}',
      operation: operation,
      originalError: sqliteException,
    );
  }
}

/// Validierungsfehler bei Business-Logic
class ValidationException extends ServiceException {
  final List<String> validationErrors;
  
  const ValidationException(
    super.message, {
    super.operation,
    super.originalError,
    this.validationErrors = const [],
  });
  
  factory ValidationException.fromErrors(
    List<String> errors, {
    String? operation,
  }) {
    return ValidationException(
      errors.join(', '),
      operation: operation,
      validationErrors: errors,
    );
  }
}

/// Business-Logic Fehler (z.B. ungültiger Status, Regelsverletzungen)
class BusinessException extends ServiceException {
  const BusinessException(
    super.message, {
    super.operation,
    super.originalError,
  });
}

/// Timeout-Fehler bei async Operationen
class ServiceTimeoutException extends ServiceException {
  final Duration timeout;
  
  const ServiceTimeoutException(
    super.message, {
    super.operation,
    super.originalError,
    required this.timeout,
  });
  
  factory ServiceTimeoutException.fromTimeoutException(
    String operation,
    TimeoutException timeoutException,
  ) {
    return ServiceTimeoutException(
      'Timeout bei $operation nach ${timeoutException.duration?.inSeconds ?? 'unbekannt'}s',
      operation: operation,
      originalError: timeoutException,
      timeout: timeoutException.duration ?? Duration.zero,
    );
  }
}

/// Fehler bei der Datenverarbeitung (Parsing, Serialisierung)
class DataProcessingException extends ServiceException {
  const DataProcessingException(
    super.message, {
    super.operation,
    super.originalError,
  });
  
  factory DataProcessingException.fromJsonError(
    String operation,
    dynamic jsonError,
  ) {
    return DataProcessingException(
      'JSON-Verarbeitungsfehler bei $operation: ${jsonError.toString()}',
      operation: operation,
      originalError: jsonError,
    );
  }
  
  factory DataProcessingException.fromMapError(
    String operation,
    dynamic mapError,
  ) {
    return DataProcessingException(
      'Map-Verarbeitungsfehler bei $operation: ${mapError.toString()}',
      operation: operation,
      originalError: mapError,
    );
  }
}

/// Konfigurationsfehler (z.B. fehlende Abhängigkeiten)
class ConfigurationException extends ServiceException {
  const ConfigurationException(
    super.message, {
    super.operation,
    super.originalError,
  });
}

/// Berechtigungsfehler
class AuthorizationException extends ServiceException {
  const AuthorizationException(
    super.message, {
    super.operation,
    super.originalError,
  });
}

/// Resource nicht gefunden (404-ähnlich)
class ResourceNotFoundException extends ServiceException {
  final String resourceId;
  final String resourceType;
  
  const ResourceNotFoundException(
    super.message, {
    super.operation,
    super.originalError,
    required this.resourceId,
    required this.resourceType,
  });
  
  factory ResourceNotFoundException.forId(
    String resourceType,
    String id, {
    String? operation,
  }) {
    return ResourceNotFoundException(
      '$resourceType mit ID "$id" nicht gefunden',
      operation: operation,
      resourceId: id,
      resourceType: resourceType,
    );
  }
}

/// Service Result für standardisierte Rückgabewerte
class ServiceResult<T> {
  final bool success;
  final T? data;
  final List<String> errors;
  final List<String> warnings;
  final String operation;
  final int? affectedCount;
  
  const ServiceResult._({
    required this.success,
    this.data,
    this.errors = const [],
    this.warnings = const [],
    required this.operation,
    this.affectedCount,
  });
  
  /// Erfolgreiches Ergebnis
  factory ServiceResult.success(
    T data, {
    required String operation,
    int? affectedCount,
    List<String> warnings = const [],
  }) {
    return ServiceResult._(
      success: true,
      data: data,
      operation: operation,
      affectedCount: affectedCount,
      warnings: warnings,
    );
  }
  
  /// Datenbankfehler
  factory ServiceResult.databaseError(
    DatabaseException error, {
    required String operation,
  }) {
    return ServiceResult._(
      success: false,
      errors: [error.message],
      operation: operation,
    );
  }
  
  /// Validierungsfehler
  factory ServiceResult.validationError(
    ValidationException error, {
    required String operation,
  }) {
    return ServiceResult._(
      success: false,
      errors: error.validationErrors.isEmpty ? [error.message] : error.validationErrors,
      operation: operation,
    );
  }
  
  /// Timeout-Fehler
  factory ServiceResult.timeoutError(
    ServiceTimeoutException error, {
    required String operation,
  }) {
    return ServiceResult._(
      success: false,
      errors: [error.message],
      operation: operation,
    );
  }
  
  /// Unerwarteter Fehler
  factory ServiceResult.unexpectedError(
    dynamic error, {
    required String operation,
  }) {
    return ServiceResult._(
      success: false,
      errors: ['Unerwarteter Fehler: ${error.toString()}'],
      operation: operation,
    );
  }
  
  /// Business-Logic Fehler
  factory ServiceResult.businessError(
    BusinessException error, {
    required String operation,
  }) {
    return ServiceResult._(
      success: false,
      errors: [error.message],
      operation: operation,
    );
  }
  
  /// Resource nicht gefunden
  factory ServiceResult.notFound(
    ResourceNotFoundException error, {
    required String operation,
  }) {
    return ServiceResult._(
      success: false,
      errors: [error.message],
      operation: operation,
    );
  }
  
  /// Konvertiert zu Map für Datenbank-Speicherung
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'data': data?.toString(),
      'errors': errors,
      'warnings': warnings,
      'operation': operation,
      'affectedCount': affectedCount,
    };
  }
  
  /// User-Message für UI-Anzeige
  String get userMessage {
    if (success) {
      if (warnings.isNotEmpty) {
        return 'Operation erfolgreich. Warnungen: ${warnings.join(', ')}';
      }
      return 'Operation erfolgreich';
    }
    
    if (errors.isNotEmpty) {
      return errors.first;
    }
    
    return 'Unbekannter Fehler';
  }
  
  /// Prüft ob Ergebnis erfolgreich ist
  bool get isSuccess => success;
  
  /// Prüft ob Fehler vorhanden sind
  bool get hasErrors => errors.isNotEmpty;
  
  /// Prüft ob Warnungen vorhanden sind
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Helper-Function für standardisiertes Error-Handling in Services
Future<ServiceResult<T>> performServiceOperation<T>(
  String operationName,
  Future<T> Function() operation, {
  Duration? timeout,
}) async {
  try {
    // Timeout-Handling falls angegeben
    if (timeout != null) {
      final result = await operation().timeout(timeout);
      return ServiceResult.success(result, operation: operationName);
    } else {
      final result = await operation();
      return ServiceResult.success(result, operation: operationName);
    }
  } on DatabaseException catch (e) {
    debugPrint('Database error in $operationName: $e');
    return ServiceResult.databaseError(e, operation: operationName);
  } on ValidationException catch (e) {
    debugPrint('Validation error in $operationName: $e');
    return ServiceResult.validationError(e, operation: operationName);
  } on BusinessException catch (e) {
    debugPrint('Business error in $operationName: $e');
    return ServiceResult.businessError(e, operation: operationName);
  } on ResourceNotFoundException catch (e) {
    debugPrint('Not found error in $operationName: $e');
    return ServiceResult.notFound(e, operation: operationName);
  } on TimeoutException catch (e) {
    final timeoutException = ServiceTimeoutException.fromTimeoutException(operationName, e);
    debugPrint('Timeout error in $operationName: $timeoutException');
    return ServiceResult.timeoutError(timeoutException, operation: operationName);
  } on FormatException catch (e) {
    final dataException = DataProcessingException.fromJsonError(operationName, e);
    debugPrint('Format error in $operationName: $dataException');
    return ServiceResult.unexpectedError(dataException, operation: operationName);
  } catch (e) {
    debugPrint('Unexpected error in $operationName: $e');
    return ServiceResult.unexpectedError(e, operation: operationName);
  }
}
