import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sound.dart';

/// Service für Sound-Dateioperationen
/// Verwaltet das Hochladen und Kopieren von Sound-Dateien
class SoundService {
  static const String _soundsDirectory = 'sounds';
  
  /// Lädt einen Sound von einer Datei in den App-Speicher hoch
  /// 
  /// Gibt den gespeicherten Sound mit dem Pfad zurück
  static Future<Sound> uploadSound(
    String name,
    String filePath,
    SoundType soundType, {
    String description = '',
    String? categoryId,
  }) async {
    // App-Dokumenten-Verzeichnis holen
    final appDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${appDir.path}/$_soundsDirectory');
    
    // Verzeichnis erstellen, falls es nicht existiert
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }
    
    // Eindeutigen Dateinamen generieren
    final uuid = const Uuid();
    final fileExtension = _getFileExtension(filePath);
    final uniqueFileName = '${uuid.v4()}$fileExtension';
    final savedPath = '${soundsDir.path}/$uniqueFileName';
    
    // Datei kopieren
    await File(filePath).copy(savedPath);
    
    // Datei-Informationen sammeln
    final file = File(savedPath);
    final fileSize = await file.length();
    
    // Sound-Objekt erstellen
    final sound = Sound(
      id: uuid.v4(),
      name: name,
      filePath: savedPath,
      soundType: soundType,
      description: description,
      isFavorite: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categoryId: categoryId,
      duration: null, // TODO: Duration aus Audio-Metadaten lesen
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
  
  /// Löscht eine Sound-Datei aus dem Speicher
  /// 
  /// Gibt true zurück, wenn erfolgreich, sonst false
  static Future<bool> deleteSoundFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Fehler beim Löschen der Sound-Datei: $e');
      return false;
    }
  }
  
  /// Prüft ob eine Sound-Datei existiert
  static Future<bool> soundFileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }
  
  /// Liest den Pfad zum Sounds-Verzeichnis
  static Future<String> getSoundsDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_soundsDirectory';
  }
  
  /// Extrahiert die Dateierweiterung aus einem Dateipfad
  static String _getFileExtension(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < filePath.length - 1) {
      return filePath.substring(dotIndex);
    }
    return '.mp3'; // Standard-Extension
  }
  
  /// Extrahiert den Dateinamen (ohne Extension) aus einem Pfad
  static String _extractFileName(String filePath) {
    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1) {
      return fileName.substring(0, dotIndex);
    }
    return fileName;
  }
  
  /// Validiert ob eine Datei ein unterstütztes Audio-Format ist
  static bool isValidAudioFile(String filePath) {
    final supportedFormats = ['.mp3', '.wav', '.ogg', '.m4a', '.aac'];
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
        print('Alle Sounds wurden gelöscht');
      }
    } catch (e) {
      print('Fehler beim Löschen aller Sounds: $e');
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
      print('Fehler beim Berechnen der Sounds-Größe: $e');
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
}