// lib/services/wiki_export_import_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/wiki_entry.dart';
import '../models/wiki_link.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/repositories/wiki_link_model_repository.dart';
import 'exceptions/service_exceptions.dart';

/// Service für Export und Import von Wiki-Einträgen mit Repository-Architektur
/// 
/// Unterstützt Markdown und JSON Format für den Datenaustausch.
/// Verwendet Repository-Architektur und spezifische Exceptions.
class WikiExportImportService {
  static const _uuid = Uuid();
  final WikiEntryModelRepository _wikiRepository;
  final WikiLinkModelRepository _wikiLinkRepository;

  WikiExportImportService({
    WikiEntryModelRepository? wikiRepository,
    WikiLinkModelRepository? wikiLinkRepository,
  })  : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance),
        _wikiLinkRepository = wikiLinkRepository ?? WikiLinkModelRepository(DatabaseConnection.instance);

  /// Exportiert Wiki-Einträge als Markdown
  Future<ServiceResult<String>> exportToMarkdown({
    List<String>? entryIds,
    String? campaignId,
    bool includeMetadata = true,
    bool includeLinks = true,
  }) async {
    return performServiceOperation('exportToMarkdown', () async {
      final entries = await _getEntriesForExport(entryIds: entryIds, campaignId: campaignId);
      
      if (entries.isEmpty) {
        return '# Keine Wiki-Einträge gefunden\n\n';
      }
      
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
          if (entry.tags.isNotEmpty) {
            buffer.writeln('**Tags:** ${entry.tags.join(', ')}');
          }
          if (entry.createdBy != null) {
            buffer.writeln('**Ersteller:** ${entry.createdBy}');
          }
          if (entry.parentId != null) {
            buffer.writeln('**Übergeordnet:** ${entry.parentId}');
          }
          if (entry.isFavorite) {
            buffer.writeln('**⭐ Favorit**');
          }
          buffer.writeln();
        }
        
        // Inhalt
        buffer.writeln(entry.content);
        buffer.writeln();
        
        // Links exportieren
        if (includeLinks) {
          final links = await _getLinksForEntry(entry.id);
          if (links.isNotEmpty) {
            buffer.writeln('## Verknüpfungen');
            for (final link in links) {
              final direction = link.sourceEntryId == entry.id ? '→' : '←';
              final targetId = link.sourceEntryId == entry.id ? link.targetEntryId : link.sourceEntryId;
              buffer.writeln('- $direction [$targetId] (${link.linkType.name})');
            }
            buffer.writeln();
          }
        }
        
        buffer.writeln('---');
        buffer.writeln();
      }
      
      return buffer.toString();
    });
  }

  /// Exportiert Wiki-Einträge als JSON
  Future<ServiceResult<String>> exportToJson({
    List<String>? entryIds,
    String? campaignId,
    bool includeMetadata = true,
    bool includeLinks = true,
  }) async {
    return performServiceOperation('exportToJson', () async {
      final entries = await _getEntriesForExport(entryIds: entryIds, campaignId: campaignId);
      final links = includeLinks ? await _getLinksForEntries(entries.map((e) => e.id).toList()) : <WikiLink>[];
      
      final exportData = {
        'version': '2.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'campaignId': campaignId,
        'count': entries.length,
        'linkCount': links.length,
        'includeMetadata': includeMetadata,
        'entries': entries.map((entry) => entry.toMap()).toList(),
        if (includeLinks) 'links': links.map((link) => link.toMap()).toList(),
      };
      
      return const JsonEncoder.withIndent('  ').convert(exportData);
    });
  }

  /// Importiert Wiki-Einträge aus einer Datei
  Future<ServiceResult<WikiImportResult>> importFromFile({
    bool skipDuplicates = true,
    bool preserveIds = false,
    String? targetCampaignId,
  }) async {
    return performServiceOperation('importFromFile', () async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json', 'md', 'txt'],
          allowMultiple: false,
        );
        
        if (result == null || result.files.isEmpty) {
          throw ValidationException(
            'Keine Datei ausgewählt',
            operation: 'importFromFile',
          );
        }
        
        final file = result.files.first;
        if (file.bytes == null) {
          throw ValidationException(
            'Datei konnte nicht gelesen werden',
            operation: 'importFromFile',
          );
        }
        
        final content = utf8.decode(file.bytes!);
        final extension = file.extension?.toLowerCase() ?? '';
        
        if (extension == 'json') {
          return await _importFromJson(
            content,
            skipDuplicates: skipDuplicates,
            preserveIds: preserveIds,
            targetCampaignId: targetCampaignId,
          );
        } else {
          return await _importFromMarkdown(
            content,
            skipDuplicates: skipDuplicates,
            preserveIds: preserveIds,
            targetCampaignId: targetCampaignId,
          );
        }
      } catch (e) {
        if (e is ServiceException) {
          rethrow;
        }
        throw ValidationException(
          'Fehler beim Datei-Import: $e',
          operation: 'importFromFile',
        );
      }
    });
  }

  /// Importiert Wiki-Einträge aus JSON
  Future<WikiImportResult> _importFromJson(
    String jsonContent, {
    bool skipDuplicates = true,
    bool preserveIds = false,
    String? targetCampaignId,
  }) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
        
      if (!data.containsKey('entries')) {
        throw ValidationException(
          'Ungültiges JSON-Format - "entries" Feld fehlt',
          operation: '_importFromJson',
        );
      }
        
      final version = data['version'] as String? ?? '1.0';
      final entriesList = data['entries'] as List<dynamic>;
      final linksList = data['links'] as List<dynamic>? ?? [];
        
      int importedCount = 0;
      int skippedCount = 0;
      int linkImportedCount = 0;
      final List<String> errors = [];
      final Map<String, String> idMapping = {};
        
      // Einträge importieren
      for (final entryData in entriesList) {
        try {
          var entry = WikiEntry.fromMap(entryData as Map<String, dynamic>);
            
          // ID ggf. überschreiben
          if (!preserveIds) {
            final newId = _uuid.v4();
            idMapping[entry.id] = newId;
            entry = entry.copyWith(id: newId);
          }
            
          // Kampagne-ID überschreiben falls angegeben
          if (targetCampaignId != null) {
            entry = entry.copyWith(campaignId: targetCampaignId);
          }
            
          // Prüfen ob Eintrag bereits existiert
          if (skipDuplicates && await _entryExists(entry)) {
            skippedCount++;
            continue;
          }
            
          final createdEntry = await _wikiRepository.create(entry);
          importedCount++;
          if (!preserveIds && entry.id != createdEntry.id) {
            idMapping[entry.id] = createdEntry.id;
          }
        } catch (e) {
          errors.add('Fehler bei Eintrag-Verarbeitung: $e');
          skippedCount++;
        }
      }
        
      // Links importieren (nur bei Version 2.0+)
      if (version != '1.0' && linksList.isNotEmpty) {
        for (final linkData in linksList) {
          try {
            var link = WikiLink.fromMap(linkData as Map<String, dynamic>);
              
            // IDs ggf. aktualisieren
            if (!preserveIds) {
              final newLinkId = _uuid.v4();
              final newSourceId = idMapping[link.sourceEntryId] ?? link.sourceEntryId;
              final newTargetId = idMapping[link.targetEntryId] ?? link.targetEntryId;
              link = link.copyWith(
                id: newLinkId,
                sourceEntryId: newSourceId,
                targetEntryId: newTargetId,
              );
            }
              
            // WikiLink hat kein campaignId - Parameter ignoriert
              
            // Prüfen ob beide Einträge existieren
            final sourceEntry = await _wikiRepository.findById(link.sourceEntryId);
            final targetEntry = await _wikiRepository.findById(link.targetEntryId);
              
            if (sourceEntry != null && targetEntry != null) {
              await _wikiLinkRepository.create(link);
              linkImportedCount++;
            }
          } catch (e) {
            errors.add('Fehler bei Link-Import: $e');
          }
        }
      }
      
      final message = 'JSON-Import abgeschlossen: $importedCount Einträge, $linkImportedCount Links importiert, $skippedCount übersprungen';
      return WikiImportResult(
        success: true,
        importedCount: importedCount,
        linkImportedCount: linkImportedCount,
        skippedCount: skippedCount,
        message: message,
        errors: errors,
      );
    } catch (e) {
      throw ValidationException(
        'Fehler beim JSON-Import: $e',
        operation: '_importFromJson',
      );
    }
  }

  /// Importiert Wiki-Einträge aus Markdown
  Future<WikiImportResult> _importFromMarkdown(
    String markdownContent, {
    bool skipDuplicates = true,
    bool preserveIds = false,
    String? targetCampaignId,
  }) async {
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
            try {
              await _importSingleEntry(
                currentEntry.copyWith(content: currentContent.join('\n')),
                skipDuplicates: skipDuplicates,
                preserveIds: preserveIds,
                targetCampaignId: targetCampaignId,
              );
              importedCount++;
            } catch (e) {
              errors.add('Fehler bei Eintrag "${currentEntry.title}": $e');
              skippedCount++;
            }
          }
            
          // Neuer Eintrag starten
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
        else if (line.startsWith('**Übergeordnet:') && currentEntry != null) {
          final parentId = line.replaceFirst('**Übergeordnet:', '').trim();
          currentEntry = currentEntry.copyWith(parentId: parentId);
        }
        // Inhalt
        else if (line.isNotEmpty && !line.startsWith('---') && !line.startsWith('##') && currentEntry != null) {
          currentContent.add(line);
        }
      }
        
      // Letzten Eintrag speichern
      if (currentEntry != null && currentContent.isNotEmpty) {
        try {
          await _importSingleEntry(
            currentEntry.copyWith(content: currentContent.join('\n')),
            skipDuplicates: skipDuplicates,
            preserveIds: preserveIds,
            targetCampaignId: targetCampaignId,
          );
          importedCount++;
        } catch (e) {
          errors.add('Fehler bei Eintrag "${currentEntry.title}": $e');
          skippedCount++;
        }
      }
        
      final message = 'Markdown-Import abgeschlossen: $importedCount importiert, $skippedCount übersprungen';
      return WikiImportResult(
        success: true,
        importedCount: importedCount,
        skippedCount: skippedCount,
        message: message,
        errors: errors,
      );
    } catch (e) {
      throw ValidationException(
        'Fehler beim Markdown-Import: $e',
        operation: '_importFromMarkdown',
      );
    }
  }

  /// Importiert einen einzelnen Wiki-Eintrag
  Future<void> _importSingleEntry(
    WikiEntry entry, {
    bool skipDuplicates = true,
    bool preserveIds = false,
    String? targetCampaignId,
  }) async {
    var importEntry = entry;
    
    if (!preserveIds) {
      importEntry = importEntry.copyWith(id: _uuid.v4());
    }
    
    if (targetCampaignId != null) {
      importEntry = importEntry.copyWith(campaignId: targetCampaignId);
    }
    
    if (skipDuplicates && await _entryExists(importEntry)) {
      throw ValidationException(
        'Eintrag existiert bereits',
        operation: '_importSingleEntry',
      );
    }
    
    await _wikiRepository.create(importEntry);
  }

  /// Prüft ob ein Eintrag bereits existiert
  Future<bool> _entryExists(WikiEntry entry) async {
    try {
      final existing = await _wikiRepository.findByTitleAndType(entry.title, entry.entryType);
      if (existing.isEmpty) return false;
      // Prüfe ob ein Eintrag mit gleicher Kampagne existiert
      if (entry.campaignId == null) return false;
      return existing.any((e) => e.campaignId == entry.campaignId);
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Existenzprüfung: $e');
      }
      return false;
    }
  }

  /// Holt Wiki-Einträge für den Export
  Future<List<WikiEntry>> _getEntriesForExport({
    List<String>? entryIds,
    String? campaignId,
  }) async {
    if (entryIds != null && entryIds.isNotEmpty) {
      return await _wikiRepository.findByIds(entryIds);
    } else if (campaignId != null) {
      return await _wikiRepository.findByCampaignId(campaignId);
    } else {
      return await _wikiRepository.getAll();
    }
  }

  /// Holt Links für einen bestimmten Eintrag
  Future<List<WikiLink>> _getLinksForEntry(String entryId) async {
    try {
      return await _wikiLinkRepository.getLinksByEntryId(entryId);
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Abrufen der Links für $entryId: $e');
      }
      return <WikiLink>[];
    }
  }

  /// Holt Links für mehrere Einträge
  Future<List<WikiLink>> _getLinksForEntries(List<String> entryIds) async {
    if (entryIds.isEmpty) return <WikiLink>[];
    
    try {
      return await _wikiLinkRepository.getLinksByEntryIds(entryIds);
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Abrufen der Links: $e');
      }
      return <WikiLink>[];
    }
  }

  /// Validiert Import-Daten vor dem Import
  Future<ServiceResult<bool>> validateImportData(String content, String format) async {
    return performServiceOperation('validateImportData', () async {
      if (content.isEmpty) {
        throw ValidationException(
          'Import-Daten sind leer',
          operation: 'validateImportData',
        );
      }
      
      switch (format.toLowerCase()) {
        case 'json':
          try {
            final data = jsonDecode(content) as Map<String, dynamic>;
            if (!data.containsKey('entries')) {
              throw ValidationException(
                'JSON-Daten enthalten keine "entries"',
                operation: 'validateImportData',
              );
            }
            return true;
          } catch (e) {
            throw ValidationException(
              'Ungültiges JSON-Format: $e',
              operation: 'validateImportData',
            );
          }
        case 'markdown':
        case 'md':
          if (!content.contains('#')) {
            throw ValidationException(
              'Markdown-Daten enthalten keine Überschriften (#)',
              operation: 'validateImportData',
            );
          }
          return true;
        default:
          throw ValidationException(
            'Nicht unterstütztes Format: $format',
            operation: 'validateImportData',
          );
      }
    });
  }

  /// Kopiert den exportierten Inhalt in die Zwischenablage
  Future<ServiceResult<void>> copyToClipboard(String content) async {
    return performServiceOperation('copyToClipboard', () async {
      await Clipboard.setData(ClipboardData(text: content));
    });
  }

  /// Erstellt eine Sicherung aller Wiki-Einträge
  Future<ServiceResult<String>> createBackup({
    String? campaignId,
    bool includeLinks = true,
  }) async {
    return performServiceOperation('createBackup', () async {
      final entries = await _getEntriesForExport(campaignId: campaignId);
      final links = includeLinks ? await _getLinksForEntries(entries.map((e) => e.id).toList()) : <WikiLink>[];
      
      final backup = {
        'backupType': campaignId != null ? 'campaign' : 'full',
        'version': '2.0',
        'createdAt': DateTime.now().toIso8601String(),
        'campaignId': campaignId,
        'entryCount': entries.length,
        'linkCount': links.length,
        'entries': entries.map((entry) => entry.toMap()).toList(),
        if (includeLinks) 'links': links.map((link) => link.toMap()).toList(),
        'metadata': {
          'exportedBy': 'WikiExportImportService',
          'exportVersion': '2.0',
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      };
      
      return const JsonEncoder.withIndent('  ').convert(backup);
    });
  }

  /// Stellt eine Sicherung wieder her
  Future<ServiceResult<WikiImportResult>> restoreFromBackup(
    String backupContent, {
    bool overwriteExisting = false,
    String? targetCampaignId,
  }) async {
    return performServiceOperation('restoreFromBackup', () async {
      try {
        final data = jsonDecode(backupContent) as Map<String, dynamic>;
        
        if (!data.containsKey('backupType')) {
          throw ValidationException(
            'Ungültiges Backup-Format',
            operation: 'restoreFromBackup',
          );
        }
        
        return await _importFromJson(
          backupContent,
          skipDuplicates: !overwriteExisting,
          preserveIds: false,
          targetCampaignId: targetCampaignId,
        );
      } catch (e) {
        throw ValidationException(
          'Fehler bei der Wiederherstellung: $e',
          operation: 'restoreFromBackup',
        );
      }
    });
  }

  // ========== STATISCHE HELPER METHODEN ==========

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

  /// Formatiiert Import-Ergebnisse für Anzeige
  static String formatImportResult(WikiImportResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Wiki-Import Ergebnis:');
    buffer.writeln('Erfolgreich: ${result.success}');
    buffer.writeln('Nachricht: ${result.message}');
    buffer.writeln('Importierte Einträge: ${result.importedCount}');
    if (result.linkImportedCount > 0) {
      buffer.writeln('Importierte Links: ${result.linkImportedCount}');
    }
    buffer.writeln('Übersprungene Einträge: ${result.skippedCount}');
    
    if (result.errors.isNotEmpty) {
      buffer.writeln('\nFehler:');
      for (final error in result.errors.take(10)) { // Nur erste 10 Fehler anzeigen
        buffer.writeln('- $error');
      }
      if (result.errors.length > 10) {
        buffer.writeln('... und ${result.errors.length - 10} weitere Fehler');
      }
    }
    
    return buffer.toString();
  }

  /// Prüft ob ein Dateiformat unterstützt wird
  static bool isFormatSupported(String extension) {
    return ['json', 'md', 'txt'].contains(extension.toLowerCase());
  }

  /// Gibt empfohlene Export-Einstellungen zurück
  static ExportSettings getRecommendedExportSettings(String useCase) {
    return switch (useCase.toLowerCase()) {
      'backup' => ExportSettings(
        format: 'json',
        includeMetadata: true,
        includeLinks: true,
      ),
      'sharing' => ExportSettings(
        format: 'markdown',
        includeMetadata: true,
        includeLinks: false,
      ),
      'archive' => ExportSettings(
        format: 'json',
        includeMetadata: true,
        includeLinks: true,
      ),
      'print' => ExportSettings(
        format: 'markdown',
        includeMetadata: true,
        includeLinks: false,
      ),
      _ => ExportSettings(
        format: 'json',
        includeMetadata: true,
        includeLinks: true,
      ),
    };
  }
}

/// Ergebnis des Wiki-Import-Vorgangs
class WikiImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int linkImportedCount;
  final int skippedCount;
  final List<String> errors;

  WikiImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.linkImportedCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'WikiImportResult(success: $success, imported: $importedCount, links: $linkImportedCount, skipped: $skippedCount)';
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'importedCount': importedCount,
      'linkImportedCount': linkImportedCount,
      'skippedCount': skippedCount,
      'errors': errors,
    };
  }

  factory WikiImportResult.fromMap(Map<String, dynamic> map) {
    return WikiImportResult(
      success: map['success'] as bool,
      message: map['message'] as String,
      importedCount: map['importedCount'] as int? ?? 0,
      linkImportedCount: map['linkImportedCount'] as int? ?? 0,
      skippedCount: map['skippedCount'] as int? ?? 0,
      errors: (map['errors'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Export-Einstellungen
class ExportSettings {
  final String format;
  final bool includeMetadata;
  final bool includeLinks;

  const ExportSettings({
    required this.format,
    required this.includeMetadata,
    required this.includeLinks,
  });

  @override
  String toString() => 'ExportSettings(format: $format, metadata: $includeMetadata, links: $includeLinks)';

  Map<String, dynamic> toMap() {
    return {
      'format': format,
      'includeMetadata': includeMetadata,
      'includeLinks': includeLinks,
    };
  }

  factory ExportSettings.fromMap(Map<String, dynamic> map) {
    return ExportSettings(
      format: map['format'] as String,
      includeMetadata: map['includeMetadata'] as bool? ?? true,
      includeLinks: map['includeLinks'] as bool? ?? true,
    );
  }
}
