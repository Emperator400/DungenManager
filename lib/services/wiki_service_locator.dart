// lib/services/wiki_service_locator.dart
import 'package:flutter/foundation.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/repositories/wiki_link_model_repository.dart';
import '../services/wiki_search_service.dart';
import '../services/wiki_link_service.dart';
import '../services/wiki_auto_link_service.dart';
import '../services/wiki_template_service.dart';
import '../services/wiki_bulk_operations_service.dart';
import '../services/wiki_export_import_service.dart';
import '../services/wiki_entry_service.dart';
import '../viewmodels/wiki_viewmodel.dart';

/// Service Locator für Wiki-Komponenten mit Dependency Injection
/// 
/// Zentralisiert die Erstellung und Verwaltung aller Wiki-Services.
/// Unterstützt die neue Repository-Architektur mit ModelRepositories.
class WikiServiceLocator {
  static final WikiServiceLocator _instance = WikiServiceLocator._internal();
  factory WikiServiceLocator() => _instance;
  WikiServiceLocator._internal();

  // Singleton-Instanzen
  WikiViewModel? _wikiViewModel;
  WikiSearchService? _wikiSearchService;
  WikiLinkService? _wikiLinkService;
  WikiAutoLinkService? _wikiAutoLinkService;
  WikiTemplateService? _wikiTemplateService;
  WikiBulkOperationsService? _wikiBulkOperationsService;
  WikiExportImportService? _wikiExportImportService;
  WikiEntryService? _wikiEntryService;
  
  // ModelRepositories
  WikiEntryModelRepository? _wikiRepository;
  WikiLinkModelRepository? _wikiLinkRepository;
  
  /// Wiki Entry Repository
  WikiEntryModelRepository get wikiRepository {
    _wikiRepository ??= WikiEntryModelRepository(DatabaseConnection.instance);
    return _wikiRepository!;
  }
  
  /// Wiki Link Repository
  WikiLinkModelRepository get wikiLinkRepository {
    _wikiLinkRepository ??= WikiLinkModelRepository(DatabaseConnection.instance);
    return _wikiLinkRepository!;
  }

  /// Wiki Entry Service (mit Repository-Architektur)
  WikiEntryService get wikiEntryService {
    _wikiEntryService ??= WikiEntryService(wikiRepository: wikiRepository);
    return _wikiEntryService!;
  }

  /// Wiki Search Service (mit Repository-Architektur)
  WikiSearchService get wikiSearchService {
    _wikiSearchService ??= WikiSearchService(wikiRepository: wikiRepository);
    return _wikiSearchService!;
  }

  /// Wiki Link Service (mit Repository-Architektur)
  WikiLinkService get wikiLinkService {
    _wikiLinkService ??= WikiLinkService(
      wikiRepository: wikiRepository,
      wikiLinkRepository: wikiLinkRepository,
    );
    return _wikiLinkService!;
  }

  /// Wiki Auto Link Service
  WikiAutoLinkService get wikiAutoLinkService {
    _wikiAutoLinkService ??= WikiAutoLinkService(
      wikiRepository: wikiRepository,
      wikiLinkRepository: wikiLinkRepository,
    );
    return _wikiAutoLinkService!;
  }

  /// Wiki Template Service
  WikiTemplateService get wikiTemplateService {
    _wikiTemplateService ??= WikiTemplateService(
      wikiRepository: wikiRepository,
    );
    return _wikiTemplateService!;
  }

  /// Wiki Bulk Operations Service
  WikiBulkOperationsService get wikiBulkOperationsService {
    _wikiBulkOperationsService ??= WikiBulkOperationsService(
      wikiRepository: wikiRepository,
      wikiLinkRepository: wikiLinkRepository,
    );
    return _wikiBulkOperationsService!;
  }

  /// Wiki Export Import Service
  WikiExportImportService get wikiExportImportService {
    _wikiExportImportService ??= WikiExportImportService(
      wikiRepository: wikiRepository,
      wikiLinkRepository: wikiLinkRepository,
    );
    return _wikiExportImportService!;
  }

  /// Wiki ViewModel (mit allen Abhängigkeiten)
  WikiViewModel get wikiViewModel {
    _wikiViewModel ??= WikiViewModel(
      wikiRepository: wikiRepository,
    );
    return _wikiViewModel!;
  }

  /// Erstellt einen neuen Wiki ViewModel (für Screens)
  WikiViewModel createWikiViewModel() => WikiViewModel(
    wikiRepository: wikiRepository,
  );

  /// Initialisiert alle Wiki-Services
  Future<void> initialize() async {
    try {
      // Stellt sicher dass die Datenbank initialisiert ist
      await DatabaseConnection.instance.database;
      
      // Pre-initialisiere häufig genutzte Services
      wikiEntryService;
      wikiSearchService;
      wikiLinkService;
      
      if (kDebugMode) {
        debugPrint('WikiServiceLocator: Alle Repository-Services initialisiert');
      }
    } catch (e) {
      debugPrint('WikiServiceLocator Initialisierung fehlgeschlagen: $e');
      rethrow;
    }
  }

  /// Setzt alle Services zurück (für Testing)
  void reset() {
    _wikiViewModel = null;
    _wikiRepository = null;
    _wikiLinkRepository = null;
    _wikiSearchService = null;
    _wikiLinkService = null;
    _wikiAutoLinkService = null;
    _wikiTemplateService = null;
    _wikiBulkOperationsService = null;
    _wikiExportImportService = null;
    _wikiEntryService = null;
  }

  /// Dispose aller Resources
  Future<void> dispose() async {
    try {
      // ViewModel disposen
      _wikiViewModel?.dispose();
      
      // Database Connection schließen
      await DatabaseConnection.instance.close();
      
      // References zurücksetzen
      reset();
      
      if (kDebugMode) {
        debugPrint('WikiServiceLocator: Alle Services disposed');
      }
    } catch (e) {
      debugPrint('WikiServiceLocator Dispose fehlgeschlagen: $e');
    }
  }

  /// Gibt den Status der Service-Initialisierung zurück
  Map<String, bool> get initializationStatus {
    return {
      'wikiRepository': _wikiRepository != null,
      'wikiLinkRepository': _wikiLinkRepository != null,
      'wikiEntryService': _wikiEntryService != null,
      'wikiSearchService': _wikiSearchService != null,
      'wikiLinkService': _wikiLinkService != null,
      'wikiAutoLinkService': _wikiAutoLinkService != null,
      'wikiTemplateService': _wikiTemplateService != null,
      'wikiBulkOperationsService': _wikiBulkOperationsService != null,
      'wikiExportImportService': _wikiExportImportService != null,
      'wikiViewModel': _wikiViewModel != null,
    };
  }

  /// Health-Check für alle Services
  Future<bool> performHealthCheck() async {
    try {
      // Teste Datenbank-Verbindung
      await DatabaseConnection.instance.database;
      
      // Teste Wiki Entry Service
      final entryResult = await wikiEntryService.getAllWikiEntries();
      if (!entryResult.isSuccess) return false;
      
      // Teste Wiki Search Service
      final searchResult = await wikiSearchService.fullTextSearch('test');
      if (!searchResult.isSuccess) return false;
      
      // Teste Wiki Link Service
      final linkResult = await wikiLinkService.getLinkStatistics();
      if (!linkResult.isSuccess) return false;
      
      return true;
    } catch (e) {
      debugPrint('WikiServiceLocator Health-Check fehlgeschlagen: $e');
      return false;
    }
  }

  /// Migration-Status für Services
  Map<String, String> get migrationStatus {
    return {
      'wikiEntryService': 'MIGRATED',
      'wikiSearchService': 'MIGRATED',
      'wikiLinkService': 'MIGRATED',
      'wikiAutoLinkService': 'MIGRATED',
      'wikiTemplateService': 'MIGRATED',
      'wikiBulkOperationsService': 'MIGRATED',
      'wikiExportImportService': 'MIGRATED',
      'wikiViewModel': 'MIGRATED',
    };
  }

  /// Erstellt Services mit custom Repositories (für Testing)
  WikiServices createTestServices({
    WikiEntryModelRepository? testWikiRepository,
    WikiLinkModelRepository? testWikiLinkRepository,
    WikiEntryModelRepository? testSearchRepository,
  }) {
    return WikiServices(
      entryService: testWikiRepository != null 
          ? WikiEntryService(wikiRepository: testWikiRepository)
          : wikiEntryService,
      searchService: testSearchRepository != null
          ? WikiSearchService(wikiRepository: testSearchRepository)
          : wikiSearchService,
      linkService: testWikiLinkRepository != null
          ? WikiLinkService(
              wikiRepository: testWikiRepository ?? wikiRepository,
              wikiLinkRepository: testWikiLinkRepository,
            )
          : wikiLinkService,
      autoLinkService: wikiAutoLinkService,
      templateService: wikiTemplateService,
      bulkOperationsService: wikiBulkOperationsService,
      exportImportService: wikiExportImportService,
    );
  }
}

/// Globale Instanz für einfachen Zugriff
final wikiServiceLocator = WikiServiceLocator();

/// Extension für einfacheren Service-Zugriff
extension WikiServiceLocatorExtension on WikiServiceLocator {
  /// Schneller Zugriff auf alle Wiki-Services
  WikiServices get services => WikiServices(
    entryService: wikiEntryService,
    searchService: wikiSearchService,
    linkService: wikiLinkService,
    autoLinkService: wikiAutoLinkService,
    templateService: wikiTemplateService,
    bulkOperationsService: wikiBulkOperationsService,
    exportImportService: wikiExportImportService,
  );

  /// Schneller Zugriff auf migrierte Services
  MigratedWikiServices get migratedServices => MigratedWikiServices(
    entryService: wikiEntryService,
    searchService: wikiSearchService,
    linkService: wikiLinkService,
  );

  /// Schneller Zugriff auf Legacy-Services
  LegacyWikiServices get legacyServices => LegacyWikiServices(
    autoLinkService: wikiAutoLinkService,
    templateService: wikiTemplateService,
    bulkOperationsService: wikiBulkOperationsService,
    exportImportService: wikiExportImportService,
  );
}

/// Container für alle Wiki-Services
class WikiServices {
  final WikiEntryService entryService;
  final WikiSearchService searchService;
  final WikiLinkService linkService;
  final WikiAutoLinkService autoLinkService;
  final WikiTemplateService templateService;
  final WikiBulkOperationsService bulkOperationsService;
  final WikiExportImportService exportImportService;

  const WikiServices({
    required this.entryService,
    required this.searchService,
    required this.linkService,
    required this.autoLinkService,
    required this.templateService,
    required this.bulkOperationsService,
    required this.exportImportService,
  });
}

/// Container für migrierte Services (neue Repository-Architektur)
class MigratedWikiServices {
  final WikiEntryService entryService;
  final WikiSearchService searchService;
  final WikiLinkService linkService;

  const MigratedWikiServices({
    required this.entryService,
    required this.searchService,
    required this.linkService,
  });
}

/// Container für Legacy-Services (noch zu migrieren)
class LegacyWikiServices {
  final WikiAutoLinkService autoLinkService;
  final WikiTemplateService templateService;
  final WikiBulkOperationsService bulkOperationsService;
  final WikiExportImportService exportImportService;

  const LegacyWikiServices({
    required this.autoLinkService,
    required this.templateService,
    required this.bulkOperationsService,
    required this.exportImportService,
  });
}

/// Service Configuration für Wiki-Module
class WikiServiceConfig {
  final bool enableCaching;
  final bool enableDebugLogging;
  final int searchResultLimit;
  final Duration searchTimeout;
  final bool enableAutoLinking;
  final bool enableTemplateSystem;

  const WikiServiceConfig({
    this.enableCaching = true,
    this.enableDebugLogging = false,
    this.searchResultLimit = 50,
    this.searchTimeout = const Duration(seconds: 30),
    this.enableAutoLinking = true,
    this.enableTemplateSystem = true,
  });

  /// Production-Konfiguration
  static const WikiServiceConfig production = WikiServiceConfig(
    enableCaching: true,
    enableDebugLogging: false,
    searchResultLimit: 50,
    searchTimeout: Duration(seconds: 30),
    enableAutoLinking: true,
    enableTemplateSystem: true,
  );

  /// Development-Konfiguration
  static const WikiServiceConfig development = WikiServiceConfig(
    enableCaching: false,
    enableDebugLogging: true,
    searchResultLimit: 20,
    searchTimeout: Duration(seconds: 10),
    enableAutoLinking: false,
    enableTemplateSystem: false,
  );

  /// Testing-Konfiguration
  static const WikiServiceConfig testing = WikiServiceConfig(
    enableCaching: false,
    enableDebugLogging: true,
    searchResultLimit: 10,
    searchTimeout: Duration(seconds: 5),
    enableAutoLinking: false,
    enableTemplateSystem: false,
  );
}

/// Service Factory für Wiki-Komponenten
class WikiServiceFactory {
  static WikiServiceConfig _config = WikiServiceConfig.production;

  /// Setzt die Service-Konfiguration
  static void setConfig(WikiServiceConfig config) {
    _config = config;
  }

  /// Aktuelle Konfiguration
  static WikiServiceConfig get config => _config;

  /// Erstellt einen konfigurierten Wiki Search Service
  static WikiSearchService createSearchService({
    WikiEntryModelRepository? customRepository,
  }) {
    if (kDebugMode && _config.enableDebugLogging) {
      debugPrint('WikiServiceFactory: Erstelle WikiSearchService mit Config: $_config');
    }
    
    return customRepository != null
        ? WikiSearchService(wikiRepository: customRepository)
        : WikiSearchService();
  }

  /// Erstellt einen konfigurierten Wiki Entry Service
  static WikiEntryService createEntryService({
    WikiEntryModelRepository? customRepository,
  }) {
    if (kDebugMode && _config.enableDebugLogging) {
      debugPrint('WikiServiceFactory: Erstelle WikiEntryService mit Config: $_config');
    }
    
    return customRepository != null
        ? WikiEntryService(wikiRepository: customRepository)
        : WikiEntryService();
  }

  /// Erstellt einen konfigurierten Wiki Link Service
  static WikiLinkService createLinkService({
    WikiLinkModelRepository? customRepository,
  }) {
    if (kDebugMode && _config.enableDebugLogging) {
      debugPrint('WikiServiceFactory: Erstelle WikiLinkService mit Config: $_config');
    }
    
    return customRepository != null
        ? WikiLinkService(
            wikiRepository: wikiServiceLocator.wikiRepository,
            wikiLinkRepository: customRepository,
          )
        : WikiLinkService(
            wikiRepository: wikiServiceLocator.wikiRepository,
            wikiLinkRepository: wikiServiceLocator.wikiLinkRepository,
          );
  }
}
