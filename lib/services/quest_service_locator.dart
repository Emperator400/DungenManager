import '../database/core/database_connection.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/item_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/inventory_item_model_repository.dart';
import '../services/quest_library_service.dart';
import '../services/quest_helper_service.dart';
import '../services/quest_data_service.dart';
import '../services/quest_reward_service.dart';
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
  QuestModelRepository? _questRepository;
  ItemModelRepository? _itemRepository;
  WikiEntryModelRepository? _wikiRepository;
  PlayerCharacterModelRepository? _playerRepository;
  InventoryItemModelRepository? _inventoryRepository;
  QuestLibraryService? _questLibraryService;
  QuestHelperService? _questHelperService;
  QuestDataService? _questDataService;
  QuestRewardService? _questRewardService;
  QuestLibraryViewModel? _questLibraryViewModel;

  /// QuestRepository Instance
  QuestModelRepository get questRepository {
    _questRepository ??= QuestModelRepository(DatabaseConnection.instance);
    return _questRepository!;
  }

  /// ItemRepository Instance
  ItemModelRepository get itemRepository {
    _itemRepository ??= ItemModelRepository(DatabaseConnection.instance);
    return _itemRepository!;
  }

  /// WikiRepository Instance
  WikiEntryModelRepository get wikiRepository {
    _wikiRepository ??= WikiEntryModelRepository(DatabaseConnection.instance);
    return _wikiRepository!;
  }

  /// PlayerCharacterRepository Instance
  PlayerCharacterModelRepository get playerRepository {
    _playerRepository ??= PlayerCharacterModelRepository(DatabaseConnection.instance);
    return _playerRepository!;
  }

  /// InventoryItemRepository Instance
  InventoryItemModelRepository get inventoryRepository {
    _inventoryRepository ??= InventoryItemModelRepository(DatabaseConnection.instance);
    return _inventoryRepository!;
  }

  /// QuestLibraryService Instance
  QuestLibraryService get questLibraryService {
    _questLibraryService ??= QuestLibraryService(
      questRepository: questRepository,
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

  /// QuestRewardService Instance
  QuestRewardService get questRewardService {
    _questRewardService ??= QuestRewardService(
      questRepository: questRepository,
      itemRepository: itemRepository,
      wikiRepository: wikiRepository,
      playerRepository: playerRepository,
      inventoryRepository: inventoryRepository,
    );
    return _questRewardService!;
  }

  /// QuestLibraryViewModel Instance
  QuestLibraryViewModel get questLibraryViewModel {
    _questLibraryViewModel ??= QuestLibraryViewModel();
    return _questLibraryViewModel!;
  }

  /// Setzt alle Services zurück (nur für Testing)
  void reset() {
    _questRepository = null;
    _itemRepository = null;
    _wikiRepository = null;
    _playerRepository = null;
    _inventoryRepository = null;
    _questLibraryService = null;
    _questHelperService = null;
    _questDataService = null;
    _questRewardService = null;
    _questLibraryViewModel = null;
  }

  /// Initialisiert alle Services mit benutzerdefinierten Dependencies
  /// (nützlich für Testing und Mocking)
  void initialize({
    QuestModelRepository? questRepository,
    ItemModelRepository? itemRepository,
    WikiEntryModelRepository? wikiRepository,
    PlayerCharacterModelRepository? playerRepository,
    InventoryItemModelRepository? inventoryRepository,
    QuestLibraryService? questLibraryService,
    QuestHelperService? questHelperService,
    QuestDataService? questDataService,
    QuestRewardService? questRewardService,
    QuestLibraryViewModel? questLibraryViewModel,
  }) {
    _questRepository = questRepository;
    _itemRepository = itemRepository;
    _wikiRepository = wikiRepository;
    _playerRepository = playerRepository;
    _inventoryRepository = inventoryRepository;
    _questLibraryService = questLibraryService;
    _questHelperService = questHelperService;
    _questDataService = questDataService;
    _questRewardService = questRewardService;
    _questLibraryViewModel = questLibraryViewModel;
  }
}

/// Convenience Extensions für einfacheren Zugriff
extension QuestServiceLocatorExtension on QuestServiceLocator {
  /// Kurzer Zugriff auf das ViewModel
  QuestLibraryViewModel get vm => questLibraryViewModel;

  /// Kurzer Zugriff auf den Haupt-Service
  QuestLibraryService get service => questLibraryService;

  /// Kurzer Zugriff auf den QuestRewardService
  QuestRewardService get rewards => questRewardService;

  /// Kurzer Zugriff auf den QuestRepository
  QuestModelRepository get quests => questRepository;

  /// Kurzer Zugriff auf den ItemRepository
  ItemModelRepository get items => itemRepository;

  /// Kurzer Zugriff auf den WikiRepository
  WikiEntryModelRepository get wiki => wikiRepository;

  /// Kurzer Zugriff auf den PlayerRepository
  PlayerCharacterModelRepository get players => playerRepository;

  /// Kurzer Zugriff auf den InventoryRepository
  InventoryItemModelRepository get inventory => inventoryRepository;
}
