import '../database/database_helper.dart';
import '../services/quest_library_service.dart';
import '../services/quest_helper_service.dart';
import '../services/quest_data_service.dart';
import '../viewmodels/quest_library_viewmodel.dart';

/// Service Locator für Dependency Injection der Quest Components
/// 
/// Dieser Service Locator zentralisiert die Erstellung und Verwaltung
/// aller Quest-bezogenen Services und ViewModels.
class QuestServiceLocator {
  static QuestServiceLocator? _instance;
  static QuestServiceLocator get instance {
    _instance ??= QuestServiceLocator._internal();
    return _instance!;
  }

  QuestServiceLocator._internal();

  // Singleton instances
  DatabaseHelper? _databaseHelper;
  QuestLibraryService? _questLibraryService;
  QuestHelperService? _questHelperService;
  QuestDataService? _questDataService;
  QuestLibraryViewModel? _questLibraryViewModel;

  /// DatabaseHelper Instance
  DatabaseHelper get databaseHelper {
    _databaseHelper ??= DatabaseHelper.instance;
    return _databaseHelper!;
  }

  /// QuestLibraryService Instance
  QuestLibraryService get questLibraryService {
    _questLibraryService ??= QuestLibraryService(
      databaseHelper: databaseHelper,
    );
    return _questLibraryService!;
  }

  /// QuestHelperService Instance
  QuestHelperService get questHelperService {
    _questHelperService ??= QuestHelperService();
    return _questHelperService!;
  }

  /// QuestDataService Instance
  QuestDataService get questDataService {
    _questDataService ??= QuestDataService();
    return _questDataService!;
  }

  /// QuestLibraryViewModel Instance
  QuestLibraryViewModel get questLibraryViewModel {
    _questLibraryViewModel ??= QuestLibraryViewModel();
    return _questLibraryViewModel!;
  }

  /// Setzt alle Services zurück (nur für Testing)
  void reset() {
    _databaseHelper = null;
    _questLibraryService = null;
    _questHelperService = null;
    _questDataService = null;
    _questLibraryViewModel = null;
  }

  /// Initialisiert alle Services mit benutzerdefinierten Dependencies
  /// (nützlich für Testing und Mocking)
  void initialize({
    DatabaseHelper? databaseHelper,
    QuestLibraryService? questLibraryService,
    QuestHelperService? questHelperService,
    QuestDataService? questDataService,
    QuestLibraryViewModel? questLibraryViewModel,
  }) {
    _databaseHelper = databaseHelper;
    _questLibraryService = questLibraryService;
    _questHelperService = questHelperService;
    _questDataService = questDataService;
    _questLibraryViewModel = questLibraryViewModel;
  }
}

/// Convenience Extensions für einfacheren Zugriff
extension QuestServiceLocatorExtension on QuestServiceLocator {
  /// Kurzer Zugriff auf das ViewModel
  QuestLibraryViewModel get vm => questLibraryViewModel;

  /// Kurzer Zugriff auf den Haupt-Service
  QuestLibraryService get service => questLibraryService;

  /// Kurzer Zugriff auf den Database Helper
  DatabaseHelper get db => databaseHelper;
}
