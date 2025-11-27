import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/wiki_entry.dart';
import 'package:dungen_manager/viewmodels/wiki_viewmodel.dart';
import 'package:dungen_manager/services/wiki_service_locator.dart';
import 'package:dungen_manager/database/database_helper.dart';

void main() {
  group('Wiki Components Tests', () {
    late WikiViewModel viewModel;
    late DatabaseHelper databaseHelper;

    setUpAll(() async {
      // Initialisiere Test-Datenbank
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.database;
    });

    setUp(() {
      // Erstelle frisches ViewModel für jeden Test
      viewModel = WikiViewModel(databaseHelper: databaseHelper);
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('WikiViewModel Integration', () {
      test('sollte Einträge korrekt laden', () async {
        await viewModel.loadEntries();
        
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('sollte Suche korrekt durchführen', () async {
        viewModel.searchEntries('Test');
        
        expect(viewModel.searchQuery, equals('Test'));
        expect(viewModel.isLoading, isFalse);
      });

      test('sollte Typ-Filter korrekt setzen', () async {
        viewModel.setTypeFilter(WikiEntryType.Person);
        
        expect(viewModel.selectedType, equals(WikiEntryType.Person));
      });

      test('sollte Sortierung korrekt ändern', () async {
        viewModel.setSortOption(WikiSortOption.title);
        viewModel.setSortAscending(false);
        
        expect(viewModel.sortOption, equals(WikiSortOption.title));
        expect(viewModel.sortAscending, isFalse);
      });
    });

    group('WikiServiceLocator Tests', () {
      test('sollte Services korrekt initialisieren', () {
        final serviceLocator = WikiServiceLocator();
        
        expect(serviceLocator.wikiViewModel, isNotNull);
        expect(serviceLocator.wikiSearchService, isNotNull);
        expect(serviceLocator.wikiLinkService, isNotNull);
        expect(serviceLocator.wikiAutoLinkService, isNotNull);
        expect(serviceLocator.wikiTemplateService, isNotNull);
        expect(serviceLocator.wikiBulkOperationsService, isNotNull);
        expect(serviceLocator.wikiExportImportService, isNotNull);
      });

      test('sollte neue ViewModel-Instanzen erstellen', () {
        final serviceLocator = WikiServiceLocator();
        
        final viewModel1 = serviceLocator.createWikiViewModel();
        final viewModel2 = serviceLocator.createWikiViewModel();
        
        expect(viewModel1, isNot(equals(viewModel2)));
      });
    });
  });
}
