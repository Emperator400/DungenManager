// Dart Core
import 'dart:convert';

// Flutter Packages
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

// Eigene Projekte
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';

/// Service für Export und Import von Wiki-Einträgen
/// Unterstützt Markdown und JSON Formate
class WikiExportImportService {
  static const _uuid = Uuid();
  static DatabaseHelper get _db => DatabaseHelper.instance;

  /// Exportiert Wiki-Einträge als Markdown
  /// Wenn [entryIds] angegeben ist, werden nur diese Einträge exportiert
  /// Wenn [campaignId] angegeben ist, werden nur Einträge dieser Kampagne exportiert
  static Future<String> exportToMarkdown({
    List<String>? entryIds,
    String? campaignId,
    bool includeMetadata = true,
  }) async {
    final entries = await _getEntriesForExport(entryIds: entryIds, campaignId: campaignId);
    
    if (entries.isEmpty) return '# Keine Wiki-Einträge gefunden\n\n';
    
    final buffer = StringBuffer();
    
    // Header mit Metadaten
    if (includeMetadata) {
      buffer.writeln('# Wiki Export');
      buffer.writeln();
      buffer.writeln('**Exportiert am:** ${DateTime.now().toIso8601String()}');
      buffer.writeln('**Anzahl Einträge:** ${entries.length}');
      if (campaignId != null) {
        buffer.writeln('**Kampagne:** $campaignId');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Einträge exportieren
    for (final entry in entries) {
      buffer.writeln('# ${entry.title}');
      buffer.writeln();
      
      if (includeMetadata) {
        buffer.writeln('**Typ:** ${_getEntryTypeDisplayName(entry.entryType)}');
        if (entry.hasTags) {
          buffer.writeln('**Tags:** ${entry.tags.join(', ')}');
        }
        if (entry.createdBy != null) {
          buffer.writeln('**Ersteller:** ${entry.createdBy}');
        }
        if (entry.isFavorite) {
          buffer.writeln('**⭐ Favorit**');
        }
        buffer.writeln();
      }
      
      // Inhalt
      buffer.writeln(entry.content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Exportiert Wiki-Einträge als JSON
  static Future<String> exportToJson({
    List<String>? entryIds,
    String? campaignId,
    bool includeMetadata = true,
  }) async {
    final entries = await _getEntriesForExport(entryIds: entryIds, campaignId: campaignId);
    
    final exportData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'campaignId': campaignId,
      'count': entries.length,
      'entries': entries.map((entry) => entry.toMap()).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Importiert Wiki-Einträge aus einer Datei
  static Future<WikiImportResult> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'md', 'txt'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return WikiImportResult(success: false, message: 'Keine Datei ausgewählt');
      }
      
      final file = result.files.first;
      if (file.bytes == null) {
        return WikiImportResult(success: false, message: 'Datei konnte nicht gelesen werden');
      }
      
      final content = utf8.decode(file.bytes!);
      final extension = file.extension?.toLowerCase() ?? '';
      
      if (extension == 'json') {
        return await _importFromJson(content);
      } else {
        return await _importFromMarkdown(content);
      }
    } catch (e) {
      return WikiImportResult(
        success: false,
        message: 'Fehler beim Import: $e',
      );
    }
  }

  /// Importiert Wiki-Einträge aus JSON
  static Future<WikiImportResult> _importFromJson(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      if (!data.containsKey('entries')) {
        return WikiImportResult(success: false, message: 'Ungültiges JSON-Format');
      }
      
      final entriesList = data['entries'] as List<dynamic>;
      final db = await _db.database;
      int importedCount = 0;
      int skippedCount = 0;
      final List<String> errors = [];
      
      await db.transaction((txn) async {
        for (final entryData in entriesList) {
          try {
            final entry = WikiEntry.fromMap(entryData as Map<String, dynamic>);
            
            // Prüfen ob Eintrag bereits existiert
            final existing = await txn.query(
              'wiki_entries',
              where: 'title = ? AND entry_type = ?',
              whereArgs: [entry.title, entry.entryType.name],
            );
            
            if (existing.isEmpty) {
              await txn.insert('wiki_entries', entry.toMap());
              importedCount++;
            } else {
              skippedCount++;
            }
          } catch (e) {
            errors.add('Fehler bei Eintrag: $e');
            skippedCount++;
          }
        }
      });
      
      return WikiImportResult(
        success: true,
        importedCount: importedCount,
        skippedCount: skippedCount,
        message: 'Import abgeschlossen: $importedCount importiert, $skippedCount übersprungen',
        errors: errors,
      );
    } catch (e) {
      return WikiImportResult(
        success: false,
        message: 'Fehler beim JSON-Import: $e',
      );
    }
  }

  /// Importiert Wiki-Einträge aus Markdown
  static Future<WikiImportResult> _importFromMarkdown(String markdownContent) async {
    try {
      final lines = markdownContent.split('\n');
      int importedCount = 0;
      int skippedCount = 0;
      final List<String> errors = [];
      
      WikiEntry? currentEntry;
      final List<String> currentContent = [];
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        // Neuer Eintrag beginnt
        if (line.startsWith('# ') && !line.startsWith('##')) {
          // Vorherigen Eintrag speichern
          if (currentEntry != null && currentContent.isNotEmpty) {
            final entry = currentEntry.copyWith(
              content: currentContent.join('\n\n'),
            );
            
            try {
              await _importSingleEntry(entry);
              importedCount++;
            } catch (e) {
              errors.add('Fehler bei Eintrag "${entry.title}": $e');
              skippedCount++;
            }
          }
          
          // Neuen Eintrag starten
          final title = line.substring(2).trim();
          currentEntry = WikiEntry.create(
            title: title,
            content: '',
            entryType: WikiEntryType.Lore, // Default
          );
          currentContent.clear();
        }
        // Metadaten erkennen
        else if (line.startsWith('**Typ:**') && currentEntry != null) {
          final typeStr = line.replaceFirst('**Typ:**', '').trim();
          final entryType = _parseEntryType(typeStr) ?? WikiEntryType.Lore;
          currentEntry = currentEntry.copyWith(entryType: entryType);
        }
        else if (line.startsWith('**Tags:**') && currentEntry != null) {
          final tagsStr = line.replaceFirst('**Tags:**', '').trim();
          final tags = tagsStr.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
          currentEntry = currentEntry.copyWith(tags: tags);
        }
        else if (line.startsWith('**Ersteller:**') && currentEntry != null) {
          final creator = line.replaceFirst('**Ersteller:**', '').trim();
          currentEntry = currentEntry.copyWith(createdBy: creator);
        }
        // Inhalt
        else if (line.isNotEmpty && !line.startsWith('---') && currentEntry != null) {
          currentContent.add(line);
        }
      }
      
      // Letzten Eintrag speichern
      if (currentEntry != null && currentContent.isNotEmpty) {
        final entry = currentEntry.copyWith(
          content: currentContent.join('\n\n'),
        );
        
        try {
          await _importSingleEntry(entry);
          importedCount++;
        } catch (e) {
          errors.add('Fehler bei Eintrag "${entry.title}": $e');
          skippedCount++;
        }
      }
      
      return WikiImportResult(
        success: true,
        importedCount: importedCount,
        skippedCount: skippedCount,
        message: 'Import abgeschlossen: $importedCount importiert, $skippedCount übersprungen',
        errors: errors,
      );
    } catch (e) {
      return WikiImportResult(
        success: false,
        message: 'Fehler beim Markdown-Import: $e',
      );
    }
  }

  /// Importiert einen einzelnen Wiki-Eintrag
  static Future<void> _importSingleEntry(WikiEntry entry) async {
    final db = await _db.database;
    
    // Prüfen ob Eintrag bereits existiert
    final existing = await db.query(
      'wiki_entries',
      where: 'title = ? AND entry_type = ?',
      whereArgs: [entry.title, entry.entryType.name],
    );
    
    if (existing.isEmpty) {
      await db.insert('wiki_entries', entry.toMap());
    }
  }

  /// Holt Wiki-Einträge für den Export
  static Future<List<WikiEntry>> _getEntriesForExport({
    List<String>? entryIds,
    String? campaignId,
  }) async {
    if (entryIds != null && entryIds.isNotEmpty) {
      // Manuelle Abfrage da Methode nicht existiert
      final db = await _db.database;
      final placeholders = List.filled(entryIds.length, '?').join(',');
      final maps = await db.query(
        'wiki_entries',
        where: 'id IN ($placeholders)',
        whereArgs: entryIds,
        orderBy: 'title ASC',
      );
      return maps.map((map) => WikiEntry.fromMap(map)).toList();
    } else if (campaignId != null) {
      // Manuelle Abfrage da Methode nicht existiert
      final db = await _db.database;
      final maps = await db.query(
        'wiki_entries',
        where: 'campaign_id = ?',
        whereArgs: [campaignId],
        orderBy: 'title ASC',
      );
      return maps.map((map) => WikiEntry.fromMap(map)).toList();
    } else {
      return await _db.getAllWikiEntries();
    }
  }

  /// Wandelt einen String in WikiEntryType um
  static WikiEntryType? _parseEntryType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'person':
        return WikiEntryType.Person;
      case 'place':
      case 'ort':
        return WikiEntryType.Place;
      case 'lore':
        return WikiEntryType.Lore;
      case 'faction':
      case 'fraktion':
        return WikiEntryType.Faction;
      case 'magic':
      case 'magie':
        return WikiEntryType.Magic;
      case 'history':
      case 'geschichte':
        return WikiEntryType.History;
      case 'item':
      case 'gegenstand':
        return WikiEntryType.Item;
      case 'quest':
      case 'aufgabe':
        return WikiEntryType.Quest;
      case 'creature':
      case 'kreatur':
        return WikiEntryType.Creature;
      default:
        return null;
    }
  }

  /// Gibt den Display-Namen für einen WikiEntryType zurück
  static String _getEntryTypeDisplayName(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return 'Person';
      case WikiEntryType.Place:
        return 'Ort';
      case WikiEntryType.Lore:
        return 'Lore';
      case WikiEntryType.Faction:
        return 'Fraktion';
      case WikiEntryType.Magic:
        return 'Magie';
      case WikiEntryType.History:
        return 'Geschichte';
      case WikiEntryType.Item:
        return 'Gegenstand';
      case WikiEntryType.Quest:
        return 'Aufgabe';
      case WikiEntryType.Creature:
        return 'Kreatur';
    }
  }

  /// Kopiert den exportierten Inhalt in die Zwischenablage
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }
}

/// Ergebnis des Wiki-Import-Vorgangs
class WikiImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  WikiImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
  });
}
