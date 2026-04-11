import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/sound.dart';

/// Repräsentiert einen aktiven Sound-Kanal im Mixer
class SoundChannel {
  final String id;
  final Sound sound;
  final AudioPlayer player;
  double volume;
  bool isLooping;
  bool isPlaying;
  Duration currentPosition;
  Duration? totalDuration;
  double playbackSpeed;

  // Stream-Subscriptions für sicheres Dispose
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  SoundChannel({
    required this.id,
    required this.sound,
    required this.player,
    this.volume = 1.0,
    this.isLooping = true,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration,
    this.playbackSpeed = 1.0,
  });

  /// Speichert die Stream-Subscriptions für späteres Canceln
  void setSubscriptions({
    StreamSubscription<PlayerState>? state,
    StreamSubscription<Duration>? position,
    StreamSubscription<Duration>? duration,
  }) {
    _stateSubscription = state;
    _positionSubscription = position;
    _durationSubscription = duration;
  }

  /// Bricht alle Stream-Subscriptions ab
  void cancelSubscriptions() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
  }

  /// Dispose des Channels mit sicherer Reihenfolge
  Future<void> dispose() async {
    // Erst Subscriptions cancellen
    cancelSubscriptions();
    
    // Dann Player stoppen und disposen
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      debugPrint('⚠️ Fehler beim Dispose des Players: $e');
    }
  }
}

/// Multi-Stream Sound Service für gleichzeitige Wiedergabe mehrerer Sounds
/// 
/// Verwaltet mehrere AudioPlayer-Instanzen und ermöglicht:
/// - Gleichzeitige Wiedergabe mehrerer Sounds
/// - Individuelle Lautstärke pro Kanal
/// - Loop-Steuerung pro Kanal
/// - Master-Lautstärke-Steuerung
/// 
/// WICHTIG: Als Singleton über Provider verwenden!
/// Beispiel in main.dart:
/// ```dart
/// ChangeNotifierProvider(create: (_) => MultiStreamSoundService())
/// ```
class MultiStreamSoundService extends ChangeNotifier {
  /// Singleton-Instanz für direkten Zugriff (optional)
  static MultiStreamSoundService? _instance;
  
  /// Map von Channel-ID zu SoundChannel
  final Map<String, SoundChannel> _channels = {};
  
  /// Master-Lautstärke (0.0 bis 1.0)
  double _masterVolume = 1.0;
  
  /// Flag ob der Service bereits disposed wurde
  bool _isDisposed = false;
  
  /// Lock für Channel-Operationen um Race Conditions zu vermeiden
  bool _isProcessing = false;
  
  /// Maximale Anzahl gleichzeitiger Sounds
  static const int maxChannels = 8;
  
  /// Getter für Singleton-Instanz
  static MultiStreamSoundService get instance {
    _instance ??= MultiStreamSoundService._internal();
    return _instance!;
  }
  
  /// Privater Konstruktor für Singleton
  MultiStreamSoundService._internal();
  
  /// Standard-Konstruktor für Provider
  MultiStreamSoundService();
  
  /// Getter für aktive Kanäle
  List<SoundChannel> get channels => _channels.values.toList();
  
  /// Getter für Master-Lautstärke
  double get masterVolume => _masterVolume;
  
  /// Anzahl aktiver Kanäle
  int get channelCount => _channels.length;
  
  /// Anzahl spielender Kanäle
  int get playingCount => _channels.values.where((c) => c.isPlaying).length;
  
  /// Ob der Service bereits disposed wurde
  bool get isDisposed => _isDisposed;

  /// Setzt die Master-Lautstärke
  void setMasterVolume(double volume) {
    if (_isDisposed) return;
    
    _masterVolume = volume.clamp(0.0, 1.0);
    
    // Alle Kanäle aktualisieren
    for (final channel in _channels.values.toList()) {
      _updateChannelVolume(channel);
    }
    
    _safeNotifyListeners();
  }

  /// Fügt einen Sound zum Mixer hinzu und startet die Wiedergabe
  /// 
  /// Gibt die Channel-ID zurück, oder null wenn ein Fehler auftritt
  Future<String?> addSound(
    Sound sound, {
    double volume = 1.0,
    bool isLooping = true,
    bool autoPlay = true,
  }) async {
    if (_isDisposed) {
      debugPrint('⚠️ Service ist bereits disposed');
      return null;
    }
    
    // Warten falls gerade eine Operation läuft
    while (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (_isDisposed) return null;
    }
    
    _isProcessing = true;
    
    try {
      // Prüfen ob Maximum erreicht
      if (_channels.length >= maxChannels) {
        debugPrint('⚠️ Maximale Anzahl an Sound-Kanälen erreicht ($maxChannels)');
        return null;
      }

      // Prüfen ob Datei existiert
      final file = File(sound.filePath);
      if (!await file.exists()) {
        debugPrint('❌ Sound-Datei existiert nicht: ${sound.filePath}');
        return null;
      }

      // Neuen Player erstellen
      final player = AudioPlayer();
      final channelId = sound.id;

      // Channel erstellen
      final channel = SoundChannel(
        id: channelId,
        sound: sound,
        player: player,
        volume: volume,
        isLooping: isLooping,
        isPlaying: false,
      );

      _channels[channelId] = channel;

      // Loop-Setting konfigurieren
      await player.setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.stop);

      // Lautstärke setzen
      _updateChannelVolume(channel);

      // Player-Events überwachen mit gespeicherten Subscriptions
      final stateSubscription = player.onPlayerStateChanged.listen(
        (state) => _handlePlayerState(channelId, state),
        onError: (error) => debugPrint('❌ Player State Error: $error'),
      );

      final positionSubscription = player.onPositionChanged.listen(
        (position) => _handlePositionChanged(channelId, position),
        onError: (error) => debugPrint('❌ Position Error: $error'),
      );

      final durationSubscription = player.onDurationChanged.listen(
        (duration) => _handleDurationChanged(channelId, duration),
        onError: (error) => debugPrint('❌ Duration Error: $error'),
      );

      // Subscriptions im Channel speichern für späteres Canceln
      channel.setSubscriptions(
        state: stateSubscription,
        position: positionSubscription,
        duration: durationSubscription,
      );

      // Auto-Play
      if (autoPlay) {
        await playSound(channelId);
      }

      _safeNotifyListeners();
      return channelId;
    } catch (e) {
      debugPrint('❌ Fehler beim Hinzufügen des Sounds: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Handler für Player-State-Changes
  void _handlePlayerState(String channelId, PlayerState state) {
    if (_isDisposed || !_channels.containsKey(channelId)) return;
    
    _channels[channelId]!.isPlaying = state == PlayerState.playing;
    _safeNotifyListeners();
  }

  /// Handler für Position-Changes (throttled)
  DateTime? _lastPositionUpdateTime;
  void _handlePositionChanged(String channelId, Duration position) {
    if (_isDisposed || !_channels.containsKey(channelId)) return;
    
    // Throttle: Max alle 500ms updaten um Performance zu verbessern
    final now = DateTime.now();
    final lastUpdate = _lastPositionUpdateTime;
    if (lastUpdate != null && now.difference(lastUpdate).inMilliseconds < 500) {
      return;
    }
    _lastPositionUpdateTime = now;
    
    _channels[channelId]!.currentPosition = position;
    _safeNotifyListeners();
  }

  /// Handler für Duration-Changes
  void _handleDurationChanged(String channelId, Duration duration) {
    if (_isDisposed || !_channels.containsKey(channelId)) return;
    
    _channels[channelId]!.totalDuration = duration;
    _safeNotifyListeners();
  }

  /// Entfernt einen Sound aus dem Mixer
  Future<void> removeSound(String channelId) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    // Warten falls gerade eine Operation läuft
    while (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (_isDisposed) return;
    }
    
    _isProcessing = true;
    
    try {
      // Channel aus Map entfernen VOR dispose
      _channels.remove(channelId);
      
      // Channel disposen
      await channel.dispose();
      
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Entfernen des Sounds: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Startet die Wiedergabe eines Sounds
  Future<bool> playSound(String channelId) async {
    if (_isDisposed) return false;
    
    final channel = _channels[channelId];
    if (channel == null) return false;

    try {
      await channel.player.play(DeviceFileSource(channel.sound.filePath));
      channel.isPlaying = true;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Abspielen: $e');
      return false;
    }
  }

  /// Pausiert einen Sound
  Future<void> pauseSound(String channelId) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    try {
      await channel.player.pause();
      channel.isPlaying = false;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Pausieren: $e');
    }
  }

  /// Stoppt einen Sound (setzt Position zurück)
  Future<void> stopSound(String channelId) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    try {
      await channel.player.stop();
      channel.isPlaying = false;
      channel.currentPosition = Duration.zero;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Stoppen: $e');
    }
  }

  /// Setzt die Lautstärke eines Kanals
  Future<void> setChannelVolume(String channelId, double volume) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    channel.volume = volume.clamp(0.0, 1.0);
    _updateChannelVolume(channel);
    _safeNotifyListeners();
  }

  /// Setzt das Loop-Verhalten eines Kanals
  Future<void> setChannelLooping(String channelId, bool isLooping) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    channel.isLooping = isLooping;
    await channel.player.setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.stop);
    _safeNotifyListeners();
  }

  /// Setzt die Wiedergabegeschwindigkeit eines Kanals (0.5x bis 2.0x)
  Future<void> setChannelSpeed(String channelId, double speed) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    // Speed auf gültigen Bereich begrenzen
    final clampedSpeed = speed.clamp(0.5, 2.0);
    channel.playbackSpeed = clampedSpeed;
    
    try {
      await channel.player.setPlaybackRate(clampedSpeed);
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Setzen der Geschwindigkeit: $e');
    }
  }

  /// Springt zu einer bestimmten Position im Track
  Future<void> seekTo(String channelId, Duration position) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    try {
      await channel.player.seek(position);
      channel.currentPosition = position;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Seek: $e');
    }
  }

  /// Toggle Play/Pause für einen Kanal
  Future<void> togglePlayPause(String channelId) async {
    if (_isDisposed) return;
    
    final channel = _channels[channelId];
    if (channel == null) return;

    if (channel.isPlaying) {
      await pauseSound(channelId);
    } else {
      await playSound(channelId);
    }
  }

  /// Stoppt alle Sounds
  Future<void> stopAll() async {
    if (_isDisposed) return;
    
    // Kopie der Kanäle erstellen um Concurrent Modification zu vermeiden
    final channelsCopy = _channels.values.toList();
    for (final channel in channelsCopy) {
      if (_isDisposed) return;
      try {
        await channel.player.stop();
        channel.isPlaying = false;
        channel.currentPosition = Duration.zero;
      } catch (e) {
        debugPrint('❌ Fehler beim Stoppen: $e');
      }
    }
    _safeNotifyListeners();
  }

  /// Pausiert alle Sounds
  Future<void> pauseAll() async {
    if (_isDisposed) return;
    
    // Kopie der Kanäle erstellen um Concurrent Modification zu vermeiden
    final channelsCopy = _channels.values.toList();
    for (final channel in channelsCopy) {
      if (_isDisposed) return;
      if (channel.isPlaying) {
        try {
          await channel.player.pause();
          channel.isPlaying = false;
        } catch (e) {
          debugPrint('❌ Fehler beim Pausieren: $e');
        }
      }
    }
    _safeNotifyListeners();
  }

  /// Setzt alle pausierten Sounds fort
  Future<void> resumeAll() async {
    if (_isDisposed) return;
    
    // Kopie der Kanäle erstellen um Concurrent Modification zu vermeiden
    final channelsCopy = _channels.values.toList();
    for (final channel in channelsCopy) {
      if (_isDisposed) return;
      try {
        await channel.player.resume();
        channel.isPlaying = true;
      } catch (e) {
        debugPrint('❌ Fehler beim Resume: $e');
      }
    }
    _safeNotifyListeners();
  }

  /// Entfernt alle Sounds aus dem Mixer
  Future<void> clearAll() async {
    if (_isDisposed) return;
    
    // Warten falls gerade eine Operation läuft
    while (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (_isDisposed) return;
    }
    
    _isProcessing = true;
    
    try {
      // Kopie der Kanäle erstellen um Concurrent Modification zu vermeiden
      final channelsCopy = _channels.values.toList();
      for (final channel in channelsCopy) {
        if (_isDisposed) return;
        await channel.dispose();
      }
      _channels.clear();
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim ClearAll: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Aktualisiert die effektive Lautstärke eines Kanals
  void _updateChannelVolume(SoundChannel channel) {
    if (_isDisposed) return;
    
    final effectiveVolume = channel.volume * _masterVolume;
    try {
      channel.player.setVolume(effectiveVolume);
    } catch (e) {
      debugPrint('❌ Fehler beim Setzen der Lautstärke: $e');
    }
  }

  /// Sichere notifyListeners-Methode die prüft ob disposed
  void _safeNotifyListeners() {
    if (_isDisposed) return;
    
    // Scheduler verwenden um Race Conditions zu vermeiden
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  /// Gibt einen Kanal anhand seiner ID zurück
  SoundChannel? getChannel(String channelId) {
    return _channels[channelId];
  }

  /// Prüft ob ein Sound bereits im Mixer ist
  bool hasSound(String soundId) {
    return _channels.containsKey(soundId);
  }

  /// Gibt die Position-Streams für einen Kanal zurück
  Stream<Duration> getPositionStream(String channelId) {
    final channel = _channels[channelId];
    if (channel == null) {
      return const Stream.empty();
    }
    return channel.player.onPositionChanged;
  }

  /// Gibt die Dauer-Streams für einen Kanal zurück
  Stream<Duration?> getDurationStream(String channelId) {
    final channel = _channels[channelId];
    if (channel == null) {
      return const Stream.empty();
    }
    return channel.player.onDurationChanged;
  }

  @override
  void dispose() {
    if (_isDisposed) {
      debugPrint('⚠️ MultiStreamSoundService bereits disposed');
      return;
    }
    
    _isDisposed = true;
    
    // Alle Channels sicher disposen
    final channelsCopy = _channels.values.toList();
    for (final channel in channelsCopy) {
      try {
        channel.dispose();
      } catch (e) {
        debugPrint('❌ Fehler beim Channel-Dispose: $e');
      }
    }
    _channels.clear();
    
    // Singleton-Instanz zurücksetzen
    _instance = null;
    
    super.dispose();
  }
}