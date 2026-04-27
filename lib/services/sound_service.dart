import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sound.dart';

/// Service für Sound-Dateioperationen und Playback
/// Verwaltet das Hochladen, Kopieren und Abspielen von Sound-Dateien
class SoundService {
  /// Unterverzeichnis relativ zu getApplicationDocumentsDirectory()
  static const String _soundsSubDir = 'DungenManager/sounds';
  static AudioPlayer? _audioPlayer;
  
  /// Lädt einen Sound von einer Datei in den App-Speicher hoch.
  ///
  /// Speichert **nur den Dateinamen** (relativ) in [Sound.filePath].
  /// Der absolute Pfad wird zur Laufzeit mit [resolveFilePath] berechnet.
  static Future<Sound> uploadSound(
    String name,
    String filePath,
    SoundType soundType, {
    String description = '',
    String? categoryId,
  }) async {
    final soundsDir = Directory(await getSoundsDirectoryPath());

    // Verzeichnis erstellen, falls es nicht existiert
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }

    // Eindeutigen Dateinamen generieren
    final uuid = const Uuid();
    final fileExtension = _getFileExtension(filePath);
    final uniqueFileName = '${uuid.v4()}$fileExtension';
    final savedAbsolutePath = p.join(soundsDir.path, uniqueFileName);

    // Datei kopieren
    await File(filePath).copy(savedAbsolutePath);

    // Datei-Informationen sammeln
    final fileSize = await File(savedAbsolutePath).length();

    // Sound-Objekt mit relativem Pfad (nur Dateiname) erstellen
    final sound = Sound(
      id: uuid.v4(),
      name: name,
      filePath: uniqueFileName,           // relativ — nur Dateiname
      soundType: soundType,
      description: description,
      isFavorite: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categoryId: categoryId,
      duration: null,
      fileSize: fileSize.toDouble(),
      tags: null,
    );

    return sound;
  }
  
  /// Lädt eine Sound-Datei hoch und gibt den Sound zurück
  /// 
  /// Bequeme Methode, die einen Sound direkt erstellt
  static Future<Sound> uploadAndCreateSound(
    String filePath,
    SoundType soundType, {
    String? customName,
    String description = '',
    String? categoryId,
  }) async {
    // Name aus Dateiname extrahieren, falls kein customName angegeben
    String name = customName ?? _extractFileName(filePath);
    
    return uploadSound(
      name,
      filePath,
      soundType,
      description: description,
      categoryId: categoryId,
    );
  }
  
  /// Löst einen relativen oder absoluten Dateipfad zu einem absoluten Pfad auf.
  ///
  /// Strategien (in Reihenfolge):
  /// 1. Absoluter Pfad + Datei existiert → unveränderter Pfad
  /// 2. Absoluter Pfad + Datei fehlt → suche Datei per Basename im Sounds-Verzeichnis
  /// 3. Relativer Pfad → `{soundsDir}/{fileName}`
  ///
  /// Gibt immer einen String zurück. Ob die Datei tatsächlich existiert, bleibt
  /// Verantwortung des Aufrufers.
  static Future<String> resolveFilePath(String fileNameOrPath) async {
    if (p.isAbsolute(fileNameOrPath)) {
      if (await File(fileNameOrPath).exists()) return fileNameOrPath;
      // Stale absolute path — try to find the file by its basename
      final soundsDir = await getSoundsDirectoryPath();
      final candidate = p.join(soundsDir, p.basename(fileNameOrPath));
      if (await File(candidate).exists()) {
        debugPrint('🔧 Sound-Pfad repariert: $fileNameOrPath → $candidate');
        return candidate;
      }
      return fileNameOrPath; // Weiterhin ungültig — Aufrufer bekommt klaren Fehler
    }
    // Relative path
    final soundsDir = await getSoundsDirectoryPath();
    return p.join(soundsDir, fileNameOrPath);
  }

  /// Löscht eine Sound-Datei aus dem Speicher
  ///
  /// Gibt true zurück, wenn erfolgreich, sonst false
  static Future<bool> deleteSoundFile(String fileNameOrPath) async {
    try {
      final absolutePath = await resolveFilePath(fileNameOrPath);
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Fehler beim Löschen der Sound-Datei: $e');
      return false;
    }
  }

  /// Prüft ob eine Sound-Datei existiert
  static Future<bool> soundFileExists(String fileNameOrPath) async {
    final absolutePath = await resolveFilePath(fileNameOrPath);
    return File(absolutePath).exists();
  }

  /// Gibt den absoluten Pfad zum Sounds-Verzeichnis zurück
  static Future<String> getSoundsDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'DungenManager', 'sounds');
  }
  
  /// Extrahiert die Dateierweiterung aus einem Dateipfad (inkl. Punkt)
  static String _getFileExtension(String filePath) {
    final ext = p.extension(filePath);
    return ext.isNotEmpty ? ext : '.mp3';
  }

  /// Extrahiert den Dateinamen (ohne Extension) aus einem Pfad
  static String _extractFileName(String filePath) {
    return p.basenameWithoutExtension(filePath);
  }

  /// Validiert ob eine Datei ein unterstütztes Audio-Format ist
  static bool isValidAudioFile(String filePath) {
    const supportedFormats = {'.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac'};
    final extension = _getFileExtension(filePath).toLowerCase();
    return supportedFormats.contains(extension);
  }
  
  /// Löscht alle Sounds aus dem Speicher
  /// 
  /// ACHTUNG: Dies löscht ALLE Sound-Dateien!
  static Future<void> deleteAllSounds() async {
    try {
      final soundsDirPath = await getSoundsDirectoryPath();
      final soundsDir = Directory(soundsDirPath);
      
      if (await soundsDir.exists()) {
        await soundsDir.delete(recursive: true);
        debugPrint('Alle Sounds wurden gelöscht');
      }
    } catch (e) {
      debugPrint('Fehler beim Löschen aller Sounds: $e');
    }
  }
  
  /// Berechnet die Gesamtgröße aller Sound-Dateien
  static Future<int> getTotalSoundsSize() async {
    try {
      final soundsDirPath = await getSoundsDirectoryPath();
      final soundsDir = Directory(soundsDirPath);
      
      if (!await soundsDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in soundsDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Fehler beim Berechnen der Sounds-Größe: $e');
      return 0;
    }
  }
  
  /// Formatiert eine Dateigröße in lesbares Format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }
  
  // ===== AUDIO PLAYBACK METHODEN =====
  
  /// Initialisiert den AudioPlayer (wird beim ersten Aufruf automatisch ausgeführt)
  static AudioPlayer _getAudioPlayer() {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }
  
  /// Spielt einen Sound ab (akzeptiert relativen oder absoluten Pfad)
  ///
  /// Gibt true zurück, wenn erfolgreich gestartet, sonst false
  static Future<bool> playSound(String fileNameOrPath) async {
    try {
      final player = _getAudioPlayer();

      final absolutePath = await resolveFilePath(fileNameOrPath);
      if (!await File(absolutePath).exists()) {
        debugPrint('Sound-Datei existiert nicht: $absolutePath');
        return false;
      }

      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(DeviceFileSource(absolutePath));
      debugPrint('✅ Sound wird abgespielt: $absolutePath');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Abspielen des Sounds: $e');
      return false;
    }
  }
  
  /// Stoppt den aktuell abgespielten Sound
  static Future<void> stopSound() async {
    try {
      final player = _getAudioPlayer();
      await player.stop();
      debugPrint('⏹️ Sound gestoppt');
    } catch (e) {
      debugPrint('❌ Fehler beim Stoppen des Sounds: $e');
    }
  }
  
  /// Pausiert den aktuell abgespielten Sound
  static Future<void> pauseSound() async {
    try {
      final player = _getAudioPlayer();
      await player.pause();
      debugPrint('⏸️ Sound pausiert');
    } catch (e) {
      debugPrint('❌ Fehler beim Pausieren des Sounds: $e');
    }
  }
  
  /// Setzt die Lautstärke des AudioPlayers
  static Future<void> setVolume(double volume) async {
    try {
      if (volume < 0.0 || volume > 1.0) {
        debugPrint('⚠️ Lautstärke muss zwischen 0.0 und 1.0 sein');
        return;
      }
      
      final player = _getAudioPlayer();
      await player.setVolume(volume);
      debugPrint('🔊 Lautstärke gesetzt auf: $volume');
    } catch (e) {
      debugPrint('❌ Fehler beim Setzen der Lautstärke: $e');
    }
  }
  
  /// Gibt den aktuellen Playback-Status zurück
  /// 
  /// true = Sound wird abgespielt, false = Sound ist pausiert oder gestoppt
  static Future<bool> isPlaying() async {
    try {
      final player = _getAudioPlayer();
      return player.state == PlayerState.playing;
    } catch (e) {
      debugPrint('❌ Fehler beim Prüfen des Playback-Status: $e');
      return false;
    }
  }
  
  /// Gibt den aktuellen Player-Stream zurück (für UI-Updates)
  static Stream<Duration> getPositionStream() {
    final player = _getAudioPlayer();
    return player.onPositionChanged;
  }
  
  /// Gibt die Dauer des aktuell abgespielten Sounds zurück
  static Stream<Duration?> getDurationStream() {
    final player = _getAudioPlayer();
    return player.onDurationChanged;
  }
  
  /// Setzt die Position des aktuell abgespielten Sounds
  static Future<void> seekTo(Duration position) async {
    try {
      final player = _getAudioPlayer();
      await player.seek(position);
      debugPrint('⏩ Zur Position gesprungen: $position');
    } catch (e) {
      debugPrint('❌ Fehler beim Springen zur Position: $e');
    }
  }
  
  /// Gibt den AudioPlayer frei (sollte aufgerufen werden, wenn nicht mehr benötigt)
  static Future<void> dispose() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        debugPrint('🗑️ AudioPlayer freigegeben');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Freigeben des AudioPlayers: $e');
    }
  }
}
