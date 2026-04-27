import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/sound.dart';
import '../database/repositories/sound_model_repository.dart';
import '../database/core/database_connection.dart';
import '../services/sound_service.dart';

/// ViewModel für die Sound-Bibliothek.
///
/// Verwaltet die Liste aller Sounds, Filter und CRUD-Operationen.
/// Szenen-Verwaltung liegt in [SoundScenesTab] (eigener State mit SoundSceneService).
class SoundLibraryViewModel extends ChangeNotifier {
  final SoundModelRepository _repo;

  List<Sound> _sounds = [];
  List<Sound> _filtered = [];
  bool _loading = false;
  String? _error;

  String _searchQuery = '';
  SoundType? _typeFilter;
  bool _favoritesOnly = false;

  SoundLibraryViewModel({SoundModelRepository? repository})
      : _repo = repository ?? SoundModelRepository(DatabaseConnection.instance);

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<Sound> get sounds => List.unmodifiable(_filtered);
  List<Sound> get allSounds => List.unmodifiable(_sounds);
  bool get isLoading => _loading;

  /// Kompatibilitäts-Getter für Consumer in screen
  bool get isLoadingSounds => _loading;

  String? get soundError => _error;
  bool get hasError => _error != null;
  String get soundSearchQuery => _searchQuery;
  SoundType? get selectedSoundType => _typeFilter;
  bool get showFavoritesOnly => _favoritesOnly;
  int get soundCount => _sounds.length;
  int get favoriteCount => _sounds.where((s) => s.isFavorite).length;

  // ---------------------------------------------------------------------------
  // Laden
  // ---------------------------------------------------------------------------

  Future<void> loadSounds() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _sounds = await _repo.findAll();
      _applyFilter();
    } catch (e) {
      _error = 'Fehler beim Laden: $e';
      debugPrint('SoundLibraryViewModel.loadSounds: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> initialize() async => loadSounds();

  Future<void> refresh() async => loadSounds();

  // ---------------------------------------------------------------------------
  // Filter
  // ---------------------------------------------------------------------------

  void setSoundSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void setSoundTypeFilter(SoundType? type) {
    _typeFilter = type;
    _applyFilter();
    notifyListeners();
  }

  void toggleFavoritesFilter() {
    _favoritesOnly = !_favoritesOnly;
    _applyFilter();
    notifyListeners();
  }

  void resetSoundFilters() {
    _searchQuery = '';
    _typeFilter = null;
    _favoritesOnly = false;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _sounds.where((s) {
      if (_typeFilter != null && s.soundType != _typeFilter) return false;
      if (_favoritesOnly && !s.isFavorite) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ---------------------------------------------------------------------------
  // Favorit togglen
  // ---------------------------------------------------------------------------

  Future<void> toggleSoundFavorite(String soundId) async {
    final i = _sounds.indexWhere((s) => s.id == soundId);
    if (i == -1) return;
    final updated = _sounds[i].copyWith(isFavorite: !_sounds[i].isFavorite);
    try {
      await _repo.update(updated);
      _sounds[i] = updated;
      _applyFilter();
      notifyListeners();
    } catch (e) {
      debugPrint('SoundLibraryViewModel.toggleFavorite: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Sound hochladen
  // ---------------------------------------------------------------------------

  Future<Sound?> uploadSound(
    String filePath,
    SoundType soundType, {
    String? customName,
    String description = '',
  }) async {
    if (!SoundService.isValidAudioFile(filePath)) {
      _error = 'Ungültiges Audioformat. Erlaubt: MP3, WAV, OGG, M4A, AAC, FLAC';
      notifyListeners();
      return null;
    }
    try {
      final sound = await SoundService.uploadAndCreateSound(
        filePath,
        soundType,
        customName: customName,
        description: description,
      );
      final saved = await _repo.create(sound);
      _sounds.add(saved);
      _applyFilter();
      _error = null;
      notifyListeners();
      return saved;
    } catch (e) {
      _error = 'Fehler beim Hochladen: $e';
      notifyListeners();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Sound löschen
  // ---------------------------------------------------------------------------

  Future<bool> deleteSound(String soundId) async {
    final sound = _sounds.firstWhere((s) => s.id == soundId,
        orElse: () => throw StateError('Sound nicht gefunden'));
    try {
      await SoundService.deleteSoundFile(sound.filePath);
      await _repo.delete(soundId);
      _sounds.removeWhere((s) => s.id == soundId);
      _applyFilter();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Fehler beim Löschen: $e';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Fehler löschen
  // ---------------------------------------------------------------------------

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Migration: absolute → relative Pfade
  // ---------------------------------------------------------------------------

  Future<void> migratePathsIfNeeded() async {
    try {
      final soundsDir = await SoundService.getSoundsDirectoryPath();
      final all = await _repo.findAll();
      for (final sound in all) {
        final fp = sound.filePath;
        if (!fp.contains('/') && !fp.contains('\\')) continue;
        final resolved = await SoundService.resolveFilePath(fp);
        final fileName = resolved.split('/').last.split('\\').last;
        final target = '$soundsDir/$fileName';
        if (resolved != target) {
          final src = File(resolved);
          if (await src.exists() && !await File(target).exists()) {
            await src.copy(target);
          }
        }
        await _repo.update(sound.copyWith(filePath: fileName));
      }
    } catch (e) {
      debugPrint('SoundLibraryViewModel.migratePaths: $e');
    }
  }
}
