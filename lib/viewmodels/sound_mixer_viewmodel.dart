import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sound.dart';
import '../database/repositories/sound_model_repository.dart';
import '../database/core/database_connection.dart';

/// Helfer-Klasse, um einen Player und seinen Zustand zu verwalten
class ActiveSoundPlayer {
  final AudioPlayer player;
  double volume;
  final Sound sound;
  bool isLooping;

  ActiveSoundPlayer({
    required this.player, 
    this.volume = 0.8, 
    required this.sound,
    this.isLooping = false,
  });
}

/// ViewModel für Sound Mixer mit neuer Repository-Architektur
/// HINWEIS: Verwendet jetzt das neue SoundModelRepository
class SoundMixerViewModel extends ChangeNotifier {
  final SoundModelRepository _soundRepository;
  
  // State
  List<Sound> _sounds = [];
  List<Sound> _ambientSounds = [];
  List<Sound> _effectSounds = [];
  bool _isLoading = false;
  String? _error;
  
  // Active Players
  final Map<String, ActiveSoundPlayer> _activePlayers = {};
  
  // Filter
  String _searchQuery = '';
  SoundType? _selectedType;
  bool _showFavoritesOnly = false;

  SoundMixerViewModel({
    SoundModelRepository? soundRepository,
  }) : _soundRepository = soundRepository ?? SoundModelRepository(DatabaseConnection.instance);

  // Getters
  List<Sound> get sounds => List.unmodifiable(_sounds);
  List<Sound> get ambientSounds => List.unmodifiable(_ambientSounds);
  List<Sound> get effectSounds => List.unmodifiable(_effectSounds);
  List<ActiveSoundPlayer> get activePlayers => _activePlayers.values.toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  SoundType? get selectedType => _selectedType;
  bool get showFavoritesOnly => _showFavoritesOnly;

  /// Gibt die Anzahl der aktiven Sounds pro Typ zurück
  int get activeAmbientCount => _activePlayers.values
      .where((player) => player.sound.soundType == SoundType.Ambiente)
      .length;
  
  int get activeEffectCount => _activePlayers.values
      .where((player) => player.sound.soundType == SoundType.Effekt)
      .length;

  /// Prüft ob ein Sound aktiv ist
  bool isSoundActive(String soundId) => _activePlayers.containsKey(soundId);

  /// Gibt den aktiven Player für einen Sound zurück
  ActiveSoundPlayer? getActivePlayer(String soundId) => _activePlayers[soundId];

  /// Lädt alle Sounds aus der Datenbank über neues Repository
  Future<void> loadSounds() async {
    await _performAsyncOperation(() async {
      // findAll gibt bereits Modelle zurück
      _sounds = await _soundRepository.findAll();
      _filterAndCategorizeSounds();
    });
  }

  /// Sucht nach Sounds
  void searchSounds(String query) {
    _searchQuery = query;
    _filterAndCategorizeSounds();
    notifyListeners();
  }

  /// Setzt den Typ-Filter
  void setTypeFilter(SoundType? type) {
    _selectedType = type;
    _filterAndCategorizeSounds();
    notifyListeners();
  }

  /// Toggle für Favorites-Filter
  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _filterAndCategorizeSounds();
    notifyListeners();
  }

  /// Kategorisiert und filtert Sounds
  void _filterAndCategorizeSounds() {
    var filteredSounds = _sounds.where((sound) {
      // Suchtext filtern
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        final nameMatch = sound.name.toLowerCase().contains(queryLower);
        final descriptionMatch = sound.description.toLowerCase().contains(queryLower);
        
        if (!(nameMatch || descriptionMatch)) {
          return false;
        }
      }

      // Typ filtern
      if (_selectedType != null && sound.soundType != _selectedType) {
        return false;
      }

      // Favorites filtern
      if (_showFavoritesOnly && !sound.isFavorite) {
        return false;
      }

      return true;
    }).toList();

    _ambientSounds = filteredSounds
        .where((sound) => sound.soundType == SoundType.Ambiente)
        .toList();
    
    _effectSounds = filteredSounds
        .where((sound) => sound.soundType == SoundType.Effekt)
        .toList();
  }

  /// Startet oder stoppt einen Ambiente-Sound
  Future<void> toggleAmbience(Sound sound) async {
    final soundId = sound.id;
    
    if (_activePlayers.containsKey(soundId)) {
      await _stopSound(soundId);
    } else {
      await _playAmbience(sound);
    }
  }

  /// Spielt einen Ambiente-Sound ab
  Future<void> _playAmbience(Sound sound) async {
    try {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(sound.filePath));
      await player.setVolume(0.8);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.resume();
      
      _activePlayers[sound.id] = ActiveSoundPlayer(
        player: player, 
        sound: sound, 
        volume: 0.8,
        isLooping: true,
      );
      
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Abspielen von ${sound.name}: $e';
      notifyListeners();
    }
  }

  /// Spielt einen Effekt ab
  Future<void> playEffect(Sound effect) async {
    final soundId = effect.id;
    
    // Wenn der Effekt schon läuft, starte ihn nicht nochmal
    if (_activePlayers.containsKey(soundId)) return;

    try {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(effect.filePath));
      await player.setVolume(0.8);
      await player.resume();
      
      _activePlayers[soundId] = ActiveSoundPlayer(
        player: player, 
        sound: effect, 
        volume: 1.0,
        isLooping: false,
      );
      
      notifyListeners();
      
      // Effekt automatisch entfernen wenn fertig
      player.onPlayerComplete.listen((event) {
        _removePlayer(soundId);
        player.dispose();
      });
    } catch (e) {
      _error = 'Fehler beim Abspielen von ${effect.name}: $e';
      notifyListeners();
    }
  }

  /// Stoppt einen Sound
  Future<void> stopSound(String soundId) async {
    await _stopSound(soundId);
  }

  /// Interne Methode zum Stoppen eines Sounds
  Future<void> _stopSound(String soundId) async {
    if (_activePlayers.containsKey(soundId)) {
      final activePlayer = _activePlayers[soundId]!;
      try {
        await activePlayer.player.stop();
        await activePlayer.player.dispose();
      } catch (e) {
        debugPrint('Error stopping sound $soundId: $e');
      }
      _removePlayer(soundId);
    }
  }

  /// Entfernt einen Player aus der aktiven Liste
  void _removePlayer(String soundId) {
    _activePlayers.remove(soundId);
    if (hasListeners) {
      notifyListeners();
    }
  }

  /// Stoppt alle Sounds
  Future<void> stopAllSounds() async {
    final soundIds = _activePlayers.keys.toList();
    
    for (final soundId in soundIds) {
      await _stopSound(soundId);
    }
    
    _activePlayers.clear();
    notifyListeners();
  }

  /// Passt die Lautstärke eines Sounds an
  void setVolume(String soundId, double volume) {
    if (_activePlayers.containsKey(soundId)) {
      final activePlayer = _activePlayers[soundId]!;
      activePlayer.volume = volume;
      activePlayer.player.setVolume(volume);
      notifyListeners();
    }
  }

  /// Setzt die Lautstärke aller aktiven Sounds
  void setMasterVolume(double volume) {
    for (final activePlayer in _activePlayers.values) {
      activePlayer.volume = volume;
      activePlayer.player.setVolume(volume);
    }
    notifyListeners();
  }

  /// Toggle Favorite Status eines Sounds über neues Repository
  Future<void> toggleFavorite(Sound sound) async {
    await _performAsyncOperation(() async {
      final updatedSound = sound.copyWith(
        isFavorite: !sound.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      // Model direkt aktualisieren (keine Entity-Konvertierung nötig)
      await _soundRepository.update(updatedSound);
      
      // Update in lokalen Listen
      final index = _sounds.indexWhere((s) => s.id == sound.id);
      if (index != -1) {
        _sounds[index] = updatedSound;
        _filterAndCategorizeSounds();
      }
      
      // Update in aktiven Playern
      if (_activePlayers.containsKey(sound.id)) {
        final oldPlayer = _activePlayers[sound.id]!;
        _activePlayers[sound.id] = ActiveSoundPlayer(
          player: oldPlayer.player,
          sound: updatedSound,
          volume: oldPlayer.volume,
          isLooping: oldPlayer.isLooping,
        );
      }
    });
  }

  /// Fügt einen neuen Sound hinzu über neues Repository
  Future<void> addSound(Sound sound) async {
    await _performAsyncOperation(() async {
      // Model direkt erstellen (keine Entity-Konvertierung nötig)
      final createdSound = await _soundRepository.create(sound);
      _sounds.add(createdSound);
      _filterAndCategorizeSounds();
    });
  }

  /// Aktualisiert einen Sound über neues Repository
  Future<void> updateSound(Sound sound) async {
    await _performAsyncOperation(() async {
      // Model direkt aktualisieren (keine Entity-Konvertierung nötig)
      await _soundRepository.update(sound);
      
      final index = _sounds.indexWhere((s) => s.id == sound.id);
      if (index != -1) {
        _sounds[index] = sound;
        _filterAndCategorizeSounds();
      }
      
      // Update in aktiven Playern
      if (_activePlayers.containsKey(sound.id)) {
        final oldPlayer = _activePlayers[sound.id]!;
        _activePlayers[sound.id] = ActiveSoundPlayer(
          player: oldPlayer.player,
          sound: sound,
          volume: oldPlayer.volume,
          isLooping: oldPlayer.isLooping,
        );
      }
    });
  }

  /// Löscht einen Sound über neues Repository
  Future<void> deleteSound(String soundId) async {
    await _performAsyncOperation(() async {
      // Zuerst Sound stoppen falls aktiv
      await _stopSound(soundId);
      
      await _soundRepository.delete(soundId);
      _sounds.removeWhere((sound) => sound.id == soundId);
      _filterAndCategorizeSounds();
    });
  }

  /// Führt eine async Operation mit Loading- und Error-Handling aus
  Future<void> _performAsyncOperation(Future<void> Function() operation) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await operation();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error in SoundMixerViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Löscht den Error-State
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Löscht alle Filter
  void clearAllFilters() {
    _searchQuery = '';
    _selectedType = null;
    _showFavoritesOnly = false;
    _filterAndCategorizeSounds();
    notifyListeners();
  }

  /// Refreshed die Daten
  Future<void> refresh() async {
    await loadSounds();
  }

  @override
  void dispose() {
    // Alle Player stoppen und disposen
    for (final activePlayer in _activePlayers.values) {
      try {
        activePlayer.player.dispose();
      } catch (e) {
        debugPrint('Error disposing player: $e');
      }
    }
    _activePlayers.clear();
    super.dispose();
  }
}
