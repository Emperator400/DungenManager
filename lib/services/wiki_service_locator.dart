import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../services/wiki_search_service.dart';
import '../services/wiki_link_service.dart';
import '../services/wiki_auto_link_service.dart';
import '../services/wiki_template_service.dart';
import '../services/wiki_bulk_operations_service.dart';
import '../services/wiki_export_import_service.dart';
import '../viewmodels/wiki_viewmodel.dart';

/// Service Locator für Wiki-Komponenten mit Dependency Injection
class WikiServiceLocator {
  static final WikiServiceLocator _instance = WikiServiceLocator._internal();
  factory WikiServiceLocator() => _instance;
  WikiServiceLocator._internal();

  // Singleton-Instanzen
  WikiViewModel? _wikiViewModel;
  DatabaseHelper? _databaseHelper;
  WikiSearchService? _wikiSearchService;
  WikiLinkService? _wikiLinkService;
  WikiAutoLinkService? _wikiAutoLinkService;
  WikiTemplateService? _wikiTemplateService;
  WikiBulkOperationsService? _wikiBulkOperationsService;
  WikiExportImportService? _wikiExportImportService;

  /// Database Helper
  DatabaseHelper get databaseHelper {
    _databaseHelper ??= DatabaseHelper.instance;
    return _databaseHelper!;
  }

  /// Wiki Search Service
  WikiSearchService get wikiSearchService {
    _wikiSearchService ??= WikiSearchService();
    return _wikiSearchService!;
  }

  /// Wiki Link Service
  WikiLinkService get wikiLinkService {
    _wikiLinkService ??= WikiLinkService();
    return _wikiLinkService!;
  }

  /// Wiki Auto Link Service
  WikiAutoLinkService get wikiAutoLinkService {
    _wikiAutoLinkService ??= WikiAutoLinkService();
    return _wikiAutoLinkService!;
  }

  /// Wiki Template Service
  WikiTemplateService get wikiTemplateService {
    _wikiTemplateService ??= WikiTemplateService();
    return _wikiTemplateService!;
  }

  /// Wiki Bulk Operations Service
  WikiBulkOperationsService get wikiBulkOperationsService {
    _wikiBulkOperationsService ??= WikiBulkOperationsService();
    return _wikiBulkOperationsService!;
  }

  /// Wiki Export Import Service
  WikiExportImportService get wikiExportImportService {
    _wikiExportImportService ??= WikiExportImportService();
    return _wikiExportImportService!;
  }

  /// Wiki ViewModel (mit allen Abhängigkeiten)
  WikiViewModel get wikiViewModel {
    _wikiViewModel ??= WikiViewModel(databaseHelper: databaseHelper);
    return _wikiViewModel!;
  }

  /// Erstellt einen neuen Wiki ViewModel (für Screens)
  WikiViewModel createWikiViewModel() => WikiViewModel(databaseHelper: databaseHelper);

  /// Erstellt einen Wiki ViewModel mit custom Database Helper (für Testing)
  WikiViewModel createWikiViewModelWithDatabase(DatabaseHelper databaseHelper) =>
      WikiViewModel(databaseHelper: databaseHelper);

  /// Initialisiert alle Wiki-Services
  Future<void> initialize() async {
    try {
      // Stellt sicher dass die Datenbank initialisiert ist
      await databaseHelper.database;
      
      // Pre-initialisiere häufig genutzte Services
      wikiSearchService;
      wikiLinkService;
      
      if (kDebugMode) {
        debugPrint('WikiServiceLocator: Alle Services initialisiert');
      }
    } catch (e) {
      debugPrint('WikiServiceLocator Initialisierung fehlgeschlagen: $e');
      rethrow;
    }
  }

  /// Setzt alle Services zurück (für Testing)
  void reset() {
    _wikiViewModel = null;
    _databaseHelper = null;
    _wikiSearchService = null;
    _wikiLinkService = null;
    _wikiAutoLinkService = null;
    _wikiTemplateService = null;
    _wikiBulkOperationsService = null;
    _wikiExportImportService = null;
  }

  /// Dispose aller Resources
  Future<void> dispose() async {
    try {
      // ViewModel disposen
      _wikiViewModel?.dispose();
      
      // Database Helper disposen falls nötig
      // (DatabaseHelper hat aktuell keine dispose-Methode)
      
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
      'databaseHelper': _databaseHelper != null,
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
      await databaseHelper.database;
      
      // Teste Wiki Search Service
      await wikiSearchService.fullTextSearch('');
      
      // Teste Wiki Link Service
      await WikiLinkService.buildHierarchy('');
      
      return true;
    } catch (e) {
      debugPrint('WikiServiceLocator Health-Check fehlgeschlagen: $e');
      return false;
    }
  }
}

/// Globale Instanz für einfachen Zugriff
final wikiServiceLocator = WikiServiceLocator();

/// Extension für einfacheren Service-Zugriff
extension WikiServiceLocatorExtension on WikiServiceLocator {
  /// Schneller Zugriff auf alle Wiki-Services
  WikiServices get services => WikiServices(
    searchService: wikiSearchService,
    linkService: wikiLinkService,
    autoLinkService: wikiAutoLinkService,
    templateService: wikiTemplateService,
    bulkOperationsService: wikiBulkOperationsService,
    exportImportService: wikiExportImportService,
  );
}

/// Container für alle Wiki-Services
class WikiServices {
  final WikiSearchService searchService;
  final WikiLinkService linkService;
  final WikiAutoLinkService autoLinkService;
  final WikiTemplateService templateService;
  final WikiBulkOperationsService bulkOperationsService;
  final WikiExportImportService exportImportService;

  const WikiServices({
    required this.searchService,
    required this.linkService,
    required this.autoLinkService,
    required this.templateService,
    required this.bulkOperationsService,
    required this.exportImportService,
  });
}
