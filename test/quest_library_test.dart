import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/services/quest_library_service.dart';
import 'package:dungen_manager/services/quest_helper_service.dart';
import 'package:dungen_manager/services/quest_data_service.dart';
import 'package:dungen_manager/viewmodels/quest_library_viewmodel.dart';
import 'package:dungen_manager/services/quest_service_locator.dart';
import 'package:dungen_manager/database/database_helper.dart';

void main() {
  group('Quest Library Tests', () {
    late QuestLibraryViewModel viewModel;

    setUp(() {
      // Reset service locator
      QuestServiceLocator.instance.reset();
    });

    tearDown(() {
      QuestServiceLocator.instance.reset();
    });

    group('QuestLibraryViewModel Tests', () {
      setUp(() {
        viewModel = QuestLibraryViewModel();
      });

      test('should initialize with empty state', () {
        expect(viewModel.allQuests, isEmpty);
        expect(viewModel.filteredQuests, isEmpty);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, null);
        expect(viewModel.hasActiveFilters, false);
      });

      test('should handle search query correctly', () {
        // Simulate search
        viewModel.searchQuests('Dragon');
        expect(viewModel.searchQuery, 'Dragon');
      });

      test('should toggle tag filter correctly', () {
        const tag = 'Combat';
        
        viewModel.toggleTag(tag);
        expect(viewModel.selectedTags, contains(tag));
        
        viewModel.toggleTag(tag);
        expect(viewModel.selectedTags, isNot(contains(tag)));
      });

      test('should set type filter correctly', () {
        viewModel.setTypeFilter(QuestType.main);
        expect(viewModel.selectedType, QuestType.main);
        
        viewModel.setTypeFilter(null);
        expect(viewModel.selectedType, null);
      });

      test('should clear all filters correctly', () {
        // Set some filters
        viewModel.setTypeFilter(QuestType.main);
        viewModel.toggleTag('Combat');
        viewModel.setFavoritesFilter(true);
        viewModel.searchQuests('Test');
        
        // Clear all
        viewModel.clearAllFilters();
        
        expect(viewModel.selectedType, null);
        expect(viewModel.selectedTags, isEmpty);
        expect(viewModel.showFavoritesOnly, false);
        expect(viewModel.searchQuery, '');
      });

      test('should handle sort option changes', () {
        viewModel.setSortOption(SortOption.type);
        expect(viewModel.sortOption, SortOption.type);
        expect(viewModel.sortAscending, true);
        
        // Same option should toggle direction
        viewModel.setSortOption(SortOption.type);
        expect(viewModel.sortAscending, false);
      });

      test('should detect active filters correctly', () {
        expect(viewModel.hasActiveFilters, false);
        
        viewModel.setTypeFilter(QuestType.main);
        expect(viewModel.hasActiveFilters, true);
        
        viewModel.clearAllFilters();
        expect(viewModel.hasActiveFilters, false);
        
        viewModel.searchQuests('Test');
        expect(viewModel.hasActiveFilters, true);
      });
    });

    group('QuestHelperService Tests', () {
      test('should create quest with correct default values', () {
        final quest = QuestHelperService.createQuest(
          title: 'Test Quest',
          description: 'Test Description',
        );

        expect(quest.title, 'Test Quest');
        expect(quest.description, 'Test Description');
        expect(quest.questType, QuestType.side);
        expect(quest.difficulty, QuestDifficulty.medium);
        expect(quest.isFavorite, false);
        expect(quest.tags, isEmpty);
      });

      test('should toggle favorite status correctly', () {
        final quest = createTestQuest('Test', 'Description');
        expect(quest.isFavorite, false);

        final favoritedQuest = QuestHelperService.toggleFavorite(quest);
        expect(favoritedQuest.isFavorite, true);
        expect(favoritedQuest.updatedAt.isAfter(quest.updatedAt), true);

        final unfavoritedQuest = QuestHelperService.toggleFavorite(favoritedQuest);
        expect(unfavoritedQuest.isFavorite, false);
      });

      test('should validate quest correctly', () {
        // Valid quest
        final validQuest = createTestQuest('Valid Quest', 'Valid Description');
        expect(QuestHelperService.isValidQuest(validQuest), true);

        // Invalid quest - empty title
        final invalidQuest = createTestQuest('', 'Description');
        expect(QuestHelperService.isValidQuest(invalidQuest), false);

        // Invalid quest - empty description
        final invalidQuest2 = createTestQuest('Title', '');
        expect(QuestHelperService.isValidQuest(invalidQuest2), false);
      });

      test('should check if quest has tag correctly', () {
        final quest = createTestQuest('Test', 'Description', tags: ['Combat', 'Exploration']);
        
        expect(QuestHelperService.hasTag(quest, 'Combat'), true);
        expect(QuestHelperService.hasTag(quest, 'Exploration'), true);
        expect(QuestHelperService.hasTag(quest, 'Social'), false);
      });

      test('should get difficulty color correctly', () {
        expect(QuestHelperService.getDifficultyColor(QuestDifficulty.easy), isA<int>());
        expect(QuestHelperService.getDifficultyColor(QuestDifficulty.medium), isA<int>());
        expect(QuestHelperService.getDifficultyColor(QuestDifficulty.hard), isA<int>());
        expect(QuestHelperService.getDifficultyColor(QuestDifficulty.legendary), isA<int>());
      });
    });

    group('QuestDataService Tests', () {
      test('should parse quest type correctly', () {
        expect(QuestDataService.parseQuestType(QuestType.main), QuestType.main);
        expect(QuestDataService.parseQuestType('QuestType.main'), QuestType.main);
        expect(QuestDataService.parseQuestType(null), QuestType.side);
        expect(QuestDataService.parseQuestType('invalid'), QuestType.side);
      });

      test('should parse difficulty correctly', () {
        expect(QuestDataService.parseDifficulty(QuestDifficulty.hard), QuestDifficulty.hard);
        expect(QuestDataService.parseDifficulty('QuestDifficulty.hard'), QuestDifficulty.hard);
        expect(QuestDataService.parseDifficulty(null), QuestDifficulty.medium);
        expect(QuestDataService.parseDifficulty('invalid'), QuestDifficulty.medium);
      });

      test('should parse string list correctly', () {
        expect(QuestDataService.parseStringList('tag1,tag2,tag3'), ['tag1', 'tag2', 'tag3']);
        expect(QuestDataService.parseStringList(['tag1', 'tag2']), ['tag1', 'tag2']);
        expect(QuestDataService.parseStringList(null), isEmpty);
        expect(QuestDataService.parseStringList(''), isEmpty);
      });

      test('should serialize string list correctly', () {
        expect(QuestDataService.serializeStringList(['tag1', 'tag2', 'tag3']), 'tag1,tag2,tag3');
        expect(QuestDataService.serializeStringList([]), '');
      });

      test('should handle safe conversions correctly', () {
        expect(QuestDataService.safeInt(42, 0), 42);
        expect(QuestDataService.safeInt(null, 0), 0);
        expect(QuestDataService.safeInt('42', 0), 42);
        expect(QuestDataService.safeInt('invalid', 0), 0);

        expect(QuestDataService.safeString('test', ''), 'test');
        expect(QuestDataService.safeString(null, ''), '');
        expect(QuestDataService.safeString(42, ''), '42');

        expect(QuestDataService.safeBool(true, false), true);
        expect(QuestDataService.safeBool(1, false), true);
        expect(QuestDataService.safeBool('true', false), true);
        expect(QuestDataService.safeBool(null, false), false);
      });
    });

    group('QuestServiceLocator Tests', () {
      test('should provide singleton instances', () {
        final locator1 = QuestServiceLocator.instance;
        final locator2 = QuestServiceLocator.instance;
        
        expect(locator1, same(locator2));
      });

      test('should reset services correctly', () {
        final locator = QuestServiceLocator.instance;
        
        // Get some services to initialize them
        final db = locator.databaseHelper;
        final service = locator.questLibraryService;
        
        expect(db, isNotNull);
        expect(service, isNotNull);
        
        // Reset
        locator.reset();
        
        // After reset, new instances should be created
        final newDb = locator.databaseHelper;
        expect(newDb, isNotNull);
      });

      test('should provide convenience extensions correctly', () {
        final locator = QuestServiceLocator.instance;
        
        expect(locator.vm, isA<QuestLibraryViewModel>());
        expect(locator.service, isA<QuestLibraryService>());
        expect(locator.db, isA<DatabaseHelper>());
      });
    });
  });
}

// Helper function to create test quests
Quest createTestQuest(String title, String description, {
  QuestType type = QuestType.side,
  QuestDifficulty difficulty = QuestDifficulty.medium,
  List<String> tags = const [],
  bool isFavorite = false,
}) {
  final now = DateTime.now();
  return Quest.create(
    title: title,
    description: description,
    status: QuestStatus.active,
    questType: type,
    difficulty: difficulty,
    tags: tags,
    isFavorite: isFavorite,
  ).copyWith(id: now.millisecondsSinceEpoch);
}
