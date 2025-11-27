// lib/viewmodels/sound_library_viewmodel.dart
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/sound.dart';

class SoundLibraryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Sound> _sounds = [];
  List<Map<String, dynamic>> _scenes = [];
  List<Sound> _filteredSounds = [];
  bool _isLoadingSounds = false;
  bool _isLoadingScenes = false;
  String _soundSearchQuery = '';
  String _sceneSearchQuery = '';
  SoundType? _selectedSoundType;
  bool _showFavoritesOnly = false;
  String? _soundError;
  String? _sceneError;
  int _currentTabIndex = 0;

  SoundLibraryViewModel() {
    loadSounds();
    loadScenes();
  }

  // Getters
  List<Sound> get sounds => _showFavoritesOnly 
      ? _filteredSounds.where((sound) => sound.isFavorite).toList()
      : _filteredSounds;
      
  List<Map<String, dynamic>> get scenes => _scenes;
  bool get isLoadingSounds => _isLoadingSounds;
  bool get isLoadingScenes => _isLoadingScenes;
  String get soundSearchQuery => _soundSearchQuery;
  String get sceneSearchQuery => _sceneSearchQuery;
  SoundType? get selectedSoundType => _selectedSoundType;
  bool get showFavoritesOnly => _showFavoritesOnly;
  String? get soundError => _soundError;
  String? get sceneError => _sceneError;
  bool get hasError => _soundError != null || _sceneError != null;
  int get currentTabIndex => _currentTabIndex;
  int get soundCount => _sounds.length;
  int get favoriteCount => _sounds.where((sound) => sound.isFavorite).length;

  // Methods
  Future<void> initialize() async {
    await Future.wait([
      loadSounds(),
      loadScenes(),
    ]);
  }

  Future<void> loadSounds() async {
    _isLoadingSounds = true;
    _soundError = null;
    notifyListeners();

    try {
      _sounds = await _dbHelper.getAllSounds();
      _applyFilters();
      _isLoadingSounds = false;
      notifyListeners();
    } catch (e) {
      _soundError = 'Fehler beim Laden der Sounds: $e';
      _sounds = [];
      _isLoadingSounds = false;
      notifyListeners();
    }
  }

  Future<void> loadScenes() async {
    _isLoadingScenes = true;
    _sceneError = null;
    notifyListeners();

    try {
      _scenes = await _dbHelper.getAllSceneSoundLinks();
      _isLoadingScenes = false;
      notifyListeners();
    } catch (e) {
      _sceneError = 'Fehler beim Laden der Szenen: $e';
      _scenes = [];
      _isLoadingScenes = false;
      notifyListeners();
    }
  }

  void setSoundSearchQuery(String query) {
    _soundSearchQuery = query;
    _applyFilters();
  }

  void setSceneSearchQuery(String query) {
    _sceneSearchQuery = query;
    notifyListeners();
  }

  void setSoundTypeFilter(SoundType? type) {
    _selectedSoundType = type;
    _applyFilters();
  }

  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  void resetSoundFilters() {
    _soundSearchQuery = '';
    _selectedSoundType = null;
    _showFavoritesOnly = false;
    _applyFilters();
  }

  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredSounds = _sounds.where((sound) {
      // Search filter
      if (_soundSearchQuery.isNotEmpty) {
        if (!sound.name.toLowerCase().contains(_soundSearchQuery.toLowerCase()) &&
            !sound.description.toLowerCase().contains(_soundSearchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Type filter
      if (_selectedSoundType != null && sound.soundType != _selectedSoundType) {
        return false;
      }
      
      return true;
    }).toList();
    
    notifyListeners();
  }

  Future<void> toggleSoundFavorite(String soundId) async {
    try {
      final soundIndex = _sounds.indexWhere((sound) => sound.id == soundId);
      if (soundIndex != -1) {
        final updatedSound = Sound(
          id: _sounds[soundIndex].id,
          name: _sounds[soundIndex].name,
          description: _sounds[soundIndex].description,
          filePath: _sounds[soundIndex].filePath,
          soundType: _sounds[soundIndex].soundType,
          isFavorite: !_sounds[soundIndex].isFavorite,
          createdAt: _sounds[soundIndex].createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _dbHelper.updateSound(updatedSound);
        _sounds[soundIndex] = updatedSound;
        _applyFilters();
      }
    } catch (e) {
      _soundError = 'Fehler beim Umschalten des Favoritenstatus: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSound(String soundId) async {
    try {
      await _dbHelper.deleteSound(soundId);
      await loadSounds();
    } catch (e) {
      _soundError = 'Fehler beim Löschen des Sounds: $e';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadSounds(),
      loadScenes(),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
