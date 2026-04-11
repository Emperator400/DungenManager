import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/sound.dart';
import '../database/repositories/sound_model_repository.dart';
import '../database/core/database_connection.dart';
import '../services/sound_service.dart';

/// ViewModel für die Sound Library mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für Sounds und Szenen
/// 
/// HINWEIS: Verwendet jetzt das neue SoundModelRepository
class SoundLibraryViewModel extends ChangeNotifier {
  final SoundModelRepository? _soundRepository;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  List<Sound> _sounds = [];
  List<Sound> _filteredSounds = [];
  List<Map<String, dynamic>> _scenes = [];
  bool _isLoadingSounds = false;
  bool _isLoadingScenes = false;
  String? _soundError;
  String? _sceneError;

  // Filter-Zustände
  String _soundSearchQuery = '';
  String _sceneSearchQuery = '';
  SoundType? _selectedSoundType;
  bool _showFavoritesOnly = false;
  int _currentTabIndex = 0;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<Sound> get sounds => List.unmodifiable(_filteredSounds);
  List<Sound> get allSounds => List.unmodifiable(_sounds);
  List<Map<String, dynamic>> get scenes => List.unmodifiable(_scenes);
  bool get isLoadingSounds => _isLoadingSounds;
  bool get isLoadingScenes => _isLoadingScenes;
  bool get isLoading => _isLoadingSounds || _isLoadingScenes;
  String? get soundError => _soundError;
  String? get sceneError => _sceneError;
  bool get hasError => _soundError != null || _sceneError != null;
  String get soundSearchQuery => _soundSearchQuery;
  String get sceneSearchQuery => _sceneSearchQuery;
  SoundType? get selectedSoundType => _selectedSoundType;
  bool get showFavoritesOnly => _showFavoritesOnly;
  int get currentTabIndex => _currentTabIndex;
  int get soundCount => _sounds.length;
  int get favoriteCount => _sounds.where((sound) => sound.isFavorite).length;

  /// Prüft ob Filter aktiv sind
  bool get hasActiveFilters => 
      _soundSearchQuery.isNotEmpty || 
      _selectedSoundType != null || 
      _showFavoritesOnly;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  /// 
  SoundLibraryViewModel({
    SoundModelRepository? soundRepository,
  }) : _soundRepository = soundRepository ?? SoundModelRepository(DatabaseConnection.instance) {
    initialize();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialisiert das ViewModel und lädt alle Daten
  Future<void> initialize() async {
    await _migrateExistingSoundsToSecureFolder();
    await Future.wait([
      loadSounds(),
      loadScenes(),
    ]);
  }

  // ============================================================================
  // SOUND MANAGEMENT
  // ============================================================================

  /// Migriert bestehende Sounds in den sicheren Dokumente-Ordner (Update-sicher)
  Future<void> _migrateExistingSoundsToSecureFolder() async {
    if (_soundRepository == null) return;
    
    try {
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      final String securePath = path.join(documentsDir.path, 'DungenManager', 'sounds');
      final Directory secureDir = Directory(securePath);

      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }

      final allSounds = await _soundRepository!.findAll();

      for (var sound in allSounds) {
        final File oldFile = File(sound.filePath);
        
        // Wenn die Datei existiert und NOCH NICHT im sicheren Ordner liegt
        if (await oldFile.exists() && !sound.filePath.contains(securePath)) {
          final String fileName = path.basename(sound.filePath);
          final String newFilePath = path.join(securePath, fileName);
          
          if (!await File(newFilePath).exists()) {
            await oldFile.copy(newFilePath);
          }
          
          // Pfad in der DB aktualisieren
          await _soundRepository!.update(sound.copyWith(filePath: newFilePath));
        }
      }
    } catch (e) {
      print('⚠️ Fehler bei der Sound-Migration: $e');
    }
  }

  /// Lädt alle Sounds aus der Datenbank über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> loadSounds() async {
    await _executeWithErrorHandling(() async {
      if (_soundRepository != null) {
        _sounds = await _soundRepository!.findAll();
      } else {
        _sounds = [];
      }
      _applyFiltersAndSort();
    }, isSoundOperation: true);
  }

  /// Lädt Sounds nach Typ über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> loadSoundsByType(SoundType soundType) async {
    await _executeWithErrorHandling(() async {
      if (_soundRepository != null) {
        _sounds = await _soundRepository!.findAll();
        // Filtern nach Typ im ViewModel
        _sounds = _sounds.where((s) => s.soundType == soundType).toList();
      } else {
        _sounds = [];
      }
      _applyFiltersAndSort();
    }, isSoundOperation: true);
  }

  /// Lädt Favoriten-Sounds über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> loadFavoriteSounds() async {
    await _executeWithErrorHandling(() async {
      if (_soundRepository != null) {
        _sounds = await _soundRepository!.findAll();
        // Filtern nach isFavorite im ViewModel
        _sounds = _sounds.where((s) => s.isFavorite).toList();
      } else {
        _sounds = [];
      }
      _applyFiltersAndSort();
    }, isSoundOperation: true);
  }

  /// Sucht Sounds über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> searchSounds(String query) async {
    await _executeWithErrorHandling(() async {
      if (_soundRepository != null) {
        _sounds = await _soundRepository!.search(query);
      } else {
        _sounds = [];
      }
      _applyFiltersAndSort();
    }, isSoundOperation: true);
  }

  /// Erstellt einen neuen Sound über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> createSound(Sound sound) async {
    await _executeWithErrorHandling(() async {
      Sound? savedSound;
      
      if (_soundRepository != null) {
        savedSound = await _soundRepository!.create(sound);
      }
      
      if (savedSound != null) {
        _sounds.add(savedSound);
        _applyFiltersAndSort();
      }
    }, isSoundOperation: true);
  }

  /// Aktualisiert einen Sound über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> updateSound(Sound sound) async {
    await _executeWithErrorHandling(() async {
      Sound? updatedSound;
      
      if (_soundRepository != null) {
        updatedSound = await _soundRepository!.update(sound);
      }
      
      if (updatedSound != null) {
        final index = _sounds.indexWhere((s) => s.id == sound.id);
        if (index != -1) {
          _sounds[index] = updatedSound;
        }
        _applyFiltersAndSort();
      }
    }, isSoundOperation: true);
  }

  /// Löscht einen Sound über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> deleteSound(String soundId) async {
    await _executeWithErrorHandling(() async {
      // Datei löschen
      final sound = _sounds.firstWhere((s) => s.id == soundId);
      await SoundService.deleteSoundFile(sound.filePath);
      
      // Aus Datenbank löschen
      if (_soundRepository != null) {
        await _soundRepository!.delete(soundId);
      }
      
      // Aus Liste entfernen
      _sounds.removeWhere((s) => s.id == soundId);
      _applyFiltersAndSort();
    }, isSoundOperation: true);
  }

  /// Schaltet den Favoriten-Status eines Sounds um über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> toggleSoundFavorite(String soundId) async {
    await _executeWithErrorHandling(() async {
      final soundIndex = _sounds.indexWhere((sound) => sound.id == soundId);
      if (soundIndex != -1) {
        final updatedSound = _sounds[soundIndex].copyWith(
          isFavorite: !_sounds[soundIndex].isFavorite,
          updatedAt: DateTime.now(),
        );
        
        if (_soundRepository != null) {
          await _soundRepository!.update(updatedSound);
        }
        
        // Lokalen State aktualisieren
        _sounds[soundIndex] = updatedSound;
        _applyFiltersAndSort();
      }
    }, isSoundOperation: true);
  }

  /// Batch-Operation: Löscht mehrere Sounds auf einmal
  /// 
  /// HINWEIS: Verwendet jetzt das neue SoundModelRepository
  Future<void> deleteSounds(List<String> soundIds) async {
    await _executeWithErrorHandling(() async {
      // Alle Dateien löschen
      for (final soundId in soundIds) {
        final sound = _sounds.firstWhere((s) => s.id == soundId);
        await SoundService.deleteSoundFile(sound.filePath);
      }
      
      // Aus Datenbank löschen
      if (_soundRepository != null) {
        await _soundRepository!.deleteAll(soundIds);
      }
      
      // Aus Liste entfernen
      _sounds.removeWhere((sound) => soundIds.contains(sound.id));
      _applyFiltersAndSort();
    }, isSoundOperation: true);
  }

  /// Lädt eine Sound-Datei hoch und speichert sie in der Datenbank
  Future<Sound?> uploadSound(
    String filePath,
    SoundType soundType, {
    String? customName,
    String description = '',
  }) async {
    try {
      // Datei validieren
      if (!SoundService.isValidAudioFile(filePath)) {
        _soundError = 'Ungültiges Audio-Format. Unterstützte Formate: MP3, WAV, OGG, M4A, AAC';
        notifyListeners();
        return null;
      }

      // Sound hochladen und Datei kopieren
      Sound? sound = await SoundService.uploadAndCreateSound(
        filePath,
        soundType,
        customName: customName,
        description: description,
      );

      if (sound != null) {
        // NEU: Datei in den sicheren Ordner (Dokumente/DungenManager/sounds) verschieben
        try {
          final Directory documentsDir = await getApplicationDocumentsDirectory();
          final String securePath = path.join(documentsDir.path, 'DungenManager', 'sounds');
          final Directory secureDir = Directory(securePath);
          
          if (!await secureDir.exists()) {
            await secureDir.create(recursive: true);
          }
          
          final File sourceFile = File(sound.filePath);
          if (await sourceFile.exists()) {
            final String fileName = path.basename(sound.filePath);
            final String newFilePath = path.join(securePath, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
            
            await sourceFile.copy(newFilePath);
            try { await sourceFile.delete(); } catch (_) {} // Alte Datei aufräumen falls möglich
            
            sound = sound.copyWith(filePath: newFilePath);
          }
        } catch (e) {
          print('⚠️ Fehler beim Sichern der Audio-Datei: $e');
        }

        // In Datenbank speichern
        Sound? savedSound;
        if (_soundRepository != null) {
          savedSound = await _soundRepository!.create(sound!);
        }
        
        if (savedSound != null) {
          _sounds.add(savedSound);
          _applyFiltersAndSort();
          _soundError = null;
          notifyListeners();
          return savedSound;
        }
      }
      
      return null;
    } catch (e) {
      _soundError = 'Fehler beim Hochladen des Sounds: $e';
      notifyListeners();
      return null;
    }
  }

  // ============================================================================
  // SCENE MANAGEMENT (Legacy-Methoden für Übergangszeit)
  // ============================================================================

  /// Lädt alle Szenen (legacy Methode - wird später migriert)
  Future<void> loadScenes() async {
    _isLoadingScenes = true;
    _sceneError = null;
    notifyListeners();

    try {
      // TODO: Migriere zu SceneRepository wenn verfügbar
      // Für jetzt: Dummy-Implementierung
      _scenes = [];
      _isLoadingScenes = false;
      notifyListeners();
    } catch (e) {
      _sceneError = 'Fehler beim Laden der Szenen: $e';
      _scenes = [];
      _isLoadingScenes = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // FILTER UND SUCHE
  // ============================================================================

  /// Setzt den Suchtext für Sounds
  void setSoundSearchQuery(String query) {
    _soundSearchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Suchtext für Szenen
  void setSceneSearchQuery(String query) {
    _sceneSearchQuery = query;
    notifyListeners();
  }

  /// Setzt den Sound-Typ-Filter
  void setSoundTypeFilter(SoundType? type) {
    _selectedSoundType = type;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Favoriten-Filter
  void setFavoritesFilter(bool showOnly) {
    _showFavoritesOnly = showOnly;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Schaltet den Favoriten-Filter um
  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den aktuellen Tab-Index
  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Setzt alle Sound-Filter zurück
  void resetSoundFilters() {
    _soundSearchQuery = '';
    _selectedSoundType = null;
    _showFavoritesOnly = false;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Wendet Filter und Sortierung an
  void _applyFiltersAndSort() {
    _filteredSounds = _sounds.where((sound) {
      // Suchtext filtern
      if (_soundSearchQuery.isNotEmpty) {
        final queryLower = _soundSearchQuery.toLowerCase();
        final nameMatch = sound.name.toLowerCase().contains(queryLower);
        final descriptionMatch = sound.description.toLowerCase().contains(queryLower);
        
        if (!(nameMatch || descriptionMatch)) {
          return false;
        }
      }

      // Typ filtern
      if (_selectedSoundType != null && sound.soundType != _selectedSoundType) {
        return false;
      }

      // Favoriten filtern
      if (_showFavoritesOnly && !sound.isFavorite) {
        return false;
      }

      return true;
    }).toList();

    // Standard-Sortierung: Name
    _filteredSounds.sort((a, b) => a.name.compareTo(b.name));
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Aktualisiert alle Daten
  Future<void> refresh() async {
    await Future.wait([
      loadSounds(),
      loadScenes(),
    ]);
  }

  /// Löscht den Fehler-Zustand
  void clearErrors() {
    _soundError = null;
    _sceneError = null;
    notifyListeners();
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Führt eine Operation mit Error Handling durch
  Future<void> _executeWithErrorHandling(
    Future<void> Function() operation, {
    bool isSoundOperation = true,
  }) async {
    try {
      if (isSoundOperation) {
        _isLoadingSounds = true;
        _soundError = null;
      } else {
        _isLoadingScenes = true;
        _sceneError = null;
      }
      notifyListeners();
      
      await operation();
    } catch (e) {
      if (isSoundOperation) {
        _soundError = e.toString();
      } else {
        _sceneError = e.toString();
      }
      notifyListeners();
      rethrow;
    } finally {
      if (isSoundOperation) {
        _isLoadingSounds = false;
      } else {
        _isLoadingScenes = false;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}