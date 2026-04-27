import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/sound.dart';
import 'sound_service.dart';

/// Repräsentiert einen aktiven Sound-Kanal im Mixer
class SoundChannel {
  final String id;
  final Sound sound;
  final AudioPlayer player;
  double volume;
  bool isLooping;
  bool isPlaying;
  double playbackSpeed;
  Duration currentPosition;
  Duration? totalDuration;

  // Zeitstempel des letzten play()-Aufrufs — schützt vor spurious stop-Events
  // die auf Windows kurz nach dem Start aus Worker-Threads ankommen können.
  DateTime? _lastPlayStarted;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  SoundChannel({
    required this.id,
    required this.sound,
    required this.player,
    this.volume = 0.8,
    this.isLooping = true,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.currentPosition = Duration.zero,
    this.totalDuration,
  });

  void setSubscriptions({
    StreamSubscription<PlayerState>? state,
    StreamSubscription<Duration>? position,
    StreamSubscription<Duration>? duration,
  }) {
    _stateSub = state;
    _positionSub = position;
    _durationSub = duration;
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _stateSub = null;
    _positionSub = null;
    _durationSub = null;
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      debugPrint('SoundChannel.dispose: $e');
    }
  }
}

/// Multi-Stream Sound Service — verwaltet mehrere gleichzeitig spielende Sounds.
///
/// Wird über [ChangeNotifierProvider] registriert ODER lokal in einem Widget
/// instanziiert. Mehrere gleichzeitige Instanzen sind möglich.
class MultiStreamSoundService extends ChangeNotifier {
  final Map<String, SoundChannel> _channels = {};
  double _masterVolume = 1.0;
  bool _disposed = false;

  static const int maxChannels = 8;

  // Throttle für Position-Updates (max 1×/500 ms pro Channel)
  final Map<String, DateTime> _lastPositionUpdate = {};

  List<SoundChannel> get channels => List.unmodifiable(_channels.values.toList());
  double get masterVolume => _masterVolume;
  int get channelCount => _channels.length;
  int get playingCount => _channels.values.where((c) => c.isPlaying).length;

  bool hasSound(String soundId) => _channels.containsKey(soundId);
  SoundChannel? getChannel(String channelId) => _channels[channelId];

  // ---------------------------------------------------------------------------
  // Sounds hinzufügen / entfernen
  // ---------------------------------------------------------------------------

  /// Fügt einen Sound zum Mixer hinzu.
  ///
  /// Gibt die Channel-ID zurück, oder null bei Fehler.
  Future<String?> addSound(
    Sound sound, {
    double volume = 0.8,
    bool isLooping = true,
    bool autoPlay = true,
  }) async {
    if (_disposed) return null;
    if (_channels.length >= maxChannels) {
      debugPrint('MultiStreamSoundService: max channels ($maxChannels) reached');
      return null;
    }
    // Duplikat vermeiden
    if (_channels.containsKey(sound.id)) {
      return sound.id;
    }

    debugPrint('🎵 [Mixer] addSound "${sound.name}" (id=${sound.id}) — gespeicherter Pfad: "${sound.filePath}"');

    final String resolvedPath;
    try {
      resolvedPath = await SoundService.resolveFilePath(sound.filePath);
    } catch (e) {
      debugPrint('❌ [Mixer] resolveFilePath fehlgeschlagen für "${sound.filePath}": $e');
      return null;
    }

    debugPrint('🔍 [Mixer] Aufgelöster Pfad: "$resolvedPath"');

    if (!await File(resolvedPath).exists()) {
      debugPrint('❌ [Mixer] Datei nicht gefunden: "$resolvedPath" (Original: "${sound.filePath}")');
      return null;
    }

    debugPrint('✅ [Mixer] Datei vorhanden, starte Player für "${sound.name}"');

    final player = AudioPlayer();
    final channelId = sound.id;

    final resolvedSound = sound.filePath == resolvedPath
        ? sound
        : sound.copyWith(filePath: resolvedPath);

    final channel = SoundChannel(
      id: channelId,
      sound: resolvedSound,
      player: player,
      volume: volume.clamp(0.0, 1.0),
      isLooping: isLooping,
    );

    _channels[channelId] = channel;

    try {
      await player.setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.stop);
      await player.setVolume((volume * _masterVolume).clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('MultiStreamSoundService.addSound: player setup failed: $e');
    }

    // Stream-Subscriptions
    channel.setSubscriptions(
      state: player.onPlayerStateChanged.listen(
        (state) {
          if (_disposed || !_channels.containsKey(channelId)) return;
          final ch = _channels[channelId]!;

          // Windows-Workaround: Nach play() können innerhalb von ~800 ms
          // spurious stop/completed-Events aus MF-Worker-Threads ankommen.
          // Diese würden isPlaying fälschlicherweise auf false setzen.
          if (state != PlayerState.playing) {
            final lastPlay = ch._lastPlayStarted;
            if (lastPlay != null &&
                DateTime.now().difference(lastPlay).inMilliseconds < 800) {
              debugPrint(
                '⚠️ [Mixer] Ignoriere frühes ${state.name}-Event für '
                '"${ch.sound.name}" (${DateTime.now().difference(lastPlay).inMilliseconds}ms nach play)',
              );
              return;
            }
          }

          ch.isPlaying = state == PlayerState.playing;
          _notify();
        },
        onError: (e) => debugPrint('player state error: $e'),
      ),
      position: player.onPositionChanged.listen(
        (pos) {
          if (_disposed || !_channels.containsKey(channelId)) return;
          final now = DateTime.now();
          final last = _lastPositionUpdate[channelId];
          if (last != null && now.difference(last).inMilliseconds < 500) return;
          _lastPositionUpdate[channelId] = now;
          _channels[channelId]!.currentPosition = pos;
          _notify();
        },
        onError: (e) => debugPrint('player position error: $e'),
      ),
      duration: player.onDurationChanged.listen(
        (dur) {
          if (_disposed || !_channels.containsKey(channelId)) return;
          _channels[channelId]!.totalDuration = dur;
          _notify();
        },
        onError: (e) => debugPrint('player duration error: $e'),
      ),
    );

    if (autoPlay) {
      await _doPlay(channel);
    }

    _notify();
    return channelId;
  }

  /// Entfernt einen Sound aus dem Mixer und stoppt ihn.
  Future<void> removeSound(String channelId) async {
    if (_disposed) return;
    final channel = _channels.remove(channelId);
    _lastPositionUpdate.remove(channelId);
    if (channel != null) {
      await channel.dispose();
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Steuerung einzelner Kanäle
  // ---------------------------------------------------------------------------

  Future<void> playSound(String channelId) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    await _doPlay(ch);
  }

  Future<void> pauseSound(String channelId) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    try {
      await ch.player.pause();
      ch.isPlaying = false;
      _notify();
    } catch (e) {
      debugPrint('pauseSound: $e');
    }
  }

  Future<void> stopSound(String channelId) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    try {
      await ch.player.stop();
      ch.isPlaying = false;
      ch.currentPosition = Duration.zero;
      _notify();
    } catch (e) {
      debugPrint('stopSound: $e');
    }
  }

  Future<void> togglePlayPause(String channelId) async {
    final ch = _channels[channelId];
    if (ch == null) return;
    if (ch.isPlaying) {
      await pauseSound(channelId);
    } else {
      await playSound(channelId);
    }
  }

  Future<void> setChannelVolume(String channelId, double volume) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    ch.volume = volume.clamp(0.0, 1.0);
    try {
      await ch.player.setVolume((ch.volume * _masterVolume).clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('setChannelVolume: $e');
    }
    _notify();
  }

  Future<void> setChannelSpeed(String channelId, double speed) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    ch.playbackSpeed = speed.clamp(0.25, 4.0);
    try {
      await ch.player.setPlaybackRate(ch.playbackSpeed);
    } catch (e) {
      debugPrint('setChannelSpeed: $e');
    }
    _notify();
  }

  Future<void> setChannelLooping(String channelId, bool isLooping) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    ch.isLooping = isLooping;
    try {
      await ch.player.setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.stop);
    } catch (e) {
      debugPrint('setChannelLooping: $e');
    }
    _notify();
  }

  Future<void> seekTo(String channelId, Duration position) async {
    if (_disposed) return;
    final ch = _channels[channelId];
    if (ch == null) return;
    try {
      await ch.player.seek(position);
      ch.currentPosition = position;
      _notify();
    } catch (e) {
      debugPrint('seekTo: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Globale Steuerung
  // ---------------------------------------------------------------------------

  void setMasterVolume(double volume) {
    if (_disposed) return;
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final ch in _channels.values) {
      try {
        ch.player.setVolume((ch.volume * _masterVolume).clamp(0.0, 1.0));
      } catch (_) {}
    }
    _notify();
  }

  Future<void> stopAll() async {
    if (_disposed) return;
    for (final ch in List.of(_channels.values)) {
      try {
        await ch.player.stop();
        ch.isPlaying = false;
        ch.currentPosition = Duration.zero;
      } catch (_) {}
    }
    _notify();
  }

  Future<void> pauseAll() async {
    if (_disposed) return;
    for (final ch in List.of(_channels.values)) {
      if (!ch.isPlaying) continue;
      try {
        await ch.player.pause();
        ch.isPlaying = false;
      } catch (_) {}
    }
    _notify();
  }

  Future<void> resumeAll() async {
    if (_disposed) return;
    for (final ch in List.of(_channels.values)) {
      try {
        await ch.player.resume();
        ch.isPlaying = true;
      } catch (_) {}
    }
    _notify();
  }

  Future<void> clearAll() async {
    if (_disposed) return;
    final copy = List.of(_channels.values);
    _channels.clear();
    _lastPositionUpdate.clear();
    for (final ch in copy) {
      await ch.dispose();
    }
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Intern
  // ---------------------------------------------------------------------------

  Future<void> _doPlay(SoundChannel ch) async {
    try {
      ch._lastPlayStarted = DateTime.now();
      await ch.player.play(DeviceFileSource(ch.sound.filePath));
      // Manuell setzen — auf Windows kann das playing-Event aus dem falschen
      // Thread kommen und dropped werden; wir vertrauen der play()-Rückkehr.
      if (!_disposed && _channels.containsKey(ch.id)) {
        _channels[ch.id]!.isPlaying = true;
      }
      _notify();
    } catch (e) {
      debugPrint('❌ [Mixer] _doPlay "${ch.sound.name}": $e');
    }
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final copy = List.of(_channels.values);
    _channels.clear();
    _lastPositionUpdate.clear();
    for (final ch in copy) {
      ch.dispose();
    }
    super.dispose();
  }
}
