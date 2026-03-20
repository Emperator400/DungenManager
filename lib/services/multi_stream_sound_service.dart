import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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

  SoundChannel({
    required this.id,
    required this.sound,
    required this.player,
    this.volume = 1.0,
    this.isLooping = true,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration,
  });
}

/// Multi-Stream Sound Service für gleichzeitige Wiedergabe mehrerer Sounds
/// 
/// Verwaltet mehrere AudioPlayer-Instanzen und ermöglicht:
/// - Gleichzeitige Wiedergabe mehrerer Sounds
/// - Individuelle Lautstärke pro Kanal
/// - Loop-Steuerung pro Kanal
/// - Master-Lautstärke-Steuerung
class MultiStreamSoundService extends ChangeNotifier {
  /// Map von Channel-ID zu SoundChannel
  final Map<String, SoundChannel> _channels = {};
  
  /// Master-Lautstärke (0.0 bis 1.0)
  double _masterVolume = 1.0;
  
  /// Maximale Anzahl gleichzeitiger Sounds
  static const int maxChannels = 8;
  
  /// Getter für aktive Kanäle
  List<SoundChannel> get channels => _channels.values.toList();
  
  /// Getter für Master-Lautstärke
  double get masterVolume => _masterVolume;
  
  /// Anzahl aktiver Kanäle
  int get channelCount => _channels.length;
  
  /// Anzahl spielender Kanäle
  int get playingCount => _channels.values.where((c) => c.isPlaying).length;

  /// Setzt die Master-Lautstärke
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    
    // Alle Kanäle aktualisieren
    for (final channel in _channels.values) {
      _updateChannelVolume(channel);
    }
    
    notifyListeners();
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
    await player.setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.release);

    // Lautstärke setzen
    _updateChannelVolume(channel);

    // Player-Events überwachen
    player.onPlayerStateChanged.listen((state) {
      if (_channels.containsKey(channelId)) {
        _channels[channelId]!.isPlaying = state == PlayerState.playing;
        notifyListeners();
      }
    });

    // Position-Updates überwachen
    player.onPositionChanged.listen((position) {
      if (_channels.containsKey(channelId)) {
        _channels[channelId]!.currentPosition = position;
        notifyListeners();
      }
    });

    // Dauer-Updates überwachen
    player.onDurationChanged.listen((duration) {
      if (_channels.containsKey(channelId)) {
        _channels[channelId]!.totalDuration = duration;
        notifyListeners();
      }
    });

    // Auto-Play
    if (autoPlay) {
      await playSound(channelId);
    }

    notifyListeners();
    return channelId;
  }

  /// Entfernt einen Sound aus dem Mixer
  Future<void> removeSound(String channelId) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    await channel.player.stop();
    await channel.player.dispose();
    _channels.remove(channelId);

    notifyListeners();
  }

  /// Startet die Wiedergabe eines Sounds
  Future<bool> playSound(String channelId) async {
    final channel = _channels[channelId];
    if (channel == null) return false;

    try {
      await channel.player.play(DeviceFileSource(channel.sound.filePath));
      channel.isPlaying = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Abspielen: $e');
      return false;
    }
  }

  /// Pausiert einen Sound
  Future<void> pauseSound(String channelId) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    await channel.player.pause();
    channel.isPlaying = false;
    notifyListeners();
  }

  /// Stoppt einen Sound (setzt Position zurück)
  Future<void> stopSound(String channelId) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    await channel.player.stop();
    channel.isPlaying = false;
    notifyListeners();
  }

  /// Setzt die Lautstärke eines Kanals
  Future<void> setChannelVolume(String channelId, double volume) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    channel.volume = volume.clamp(0.0, 1.0);
    _updateChannelVolume(channel);
    notifyListeners();
  }

  /// Setzt das Loop-Verhalten eines Kanals
  Future<void> setChannelLooping(String channelId, bool isLooping) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    channel.isLooping = isLooping;
    await channel.player.setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.release);
    notifyListeners();
  }

  /// Springt zu einer bestimmten Position im Track
  Future<void> seekTo(String channelId, Duration position) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    await channel.player.seek(position);
    channel.currentPosition = position;
    notifyListeners();
  }

  /// Toggle Play/Pause für einen Kanal
  Future<void> togglePlayPause(String channelId) async {
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
    for (final channel in _channels.values) {
      await channel.player.stop();
      channel.isPlaying = false;
    }
    notifyListeners();
  }

  /// Pausiert alle Sounds
  Future<void> pauseAll() async {
    for (final channel in _channels.values) {
      if (channel.isPlaying) {
        await channel.player.pause();
        channel.isPlaying = false;
      }
    }
    notifyListeners();
  }

  /// Setzt alle pausierten Sounds fort
  Future<void> resumeAll() async {
    for (final channel in _channels.values) {
      await channel.player.resume();
      channel.isPlaying = true;
    }
    notifyListeners();
  }

  /// Entfernt alle Sounds aus dem Mixer
  Future<void> clearAll() async {
    for (final channel in _channels.values) {
      await channel.player.stop();
      await channel.player.dispose();
    }
    _channels.clear();
    notifyListeners();
  }

  /// Aktualisiert die effektive Lautstärke eines Kanals
  void _updateChannelVolume(SoundChannel channel) {
    final effectiveVolume = channel.volume * _masterVolume;
    channel.player.setVolume(effectiveVolume);
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
    clearAll();
    super.dispose();
  }
}