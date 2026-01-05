// lib/services/wiki_auto_link_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wiki_entry.dart';
import '../models/player_character.dart';
import '../models/creature.dart';
import '../models/campaign.dart';
import '../models/wiki_link.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/repositories/wiki_link_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/creature_model_repository.dart';
import 'exceptions/service_exceptions.dart';

/// Service für automatische Verknüpfungen und Smart-Suggestions mit Repository-Architektur
/// 
/// Erstellt automatisch Wiki-Einträge für Charaktere, Kreaturen und Kampagnen.
/// Verwendet Repository-Architektur und spezifische Exceptions.
class WikiAutoLinkService {
  final WikiEntryModelRepository _wikiRepository;
  final WikiLinkModelRepository _wikiLinkRepository;
  final PlayerCharacterModelRepository _playerCharacterRepository;
  final CampaignModelRepository _campaignRepository;
  final CreatureModelRepository _creatureRepository;

  WikiAutoLinkService({
    WikiEntryModelRepository? wikiRepository,
    WikiLinkModelRepository? wikiLinkRepository,
    PlayerCharacterModelRepository? playerCharacterRepository,
    CampaignModelRepository? campaignRepository,
    CreatureModelRepository? creatureRepository,
  })  : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance),
        _wikiLinkRepository = wikiLinkRepository ?? WikiLinkModelRepository(DatabaseConnection.instance),
        _playerCharacterRepository = playerCharacterRepository ?? PlayerCharacterModelRepository(DatabaseConnection.instance),
        _campaignRepository = campaignRepository ?? CampaignModelRepository(DatabaseConnection.instance),
        _creatureRepository = creatureRepository ?? CreatureModelRepository(DatabaseConnection.instance);

  /// Erstellt automatisch Wiki-Einträge für Charaktere und Kreaturen
  Future<ServiceResult<List<WikiEntry>>> createAutoEntriesForCampaign(String campaignId) async {
    return performServiceOperation('createAutoEntriesForCampaign', () async {
      final entries = <WikiEntry>[];
      
      // Charaktere verknüpfen
      List<PlayerCharacter> characters;
      try {
        characters = await _playerCharacterRepository.findByCampaign(campaignId);
      } catch (e) {
        throw DatabaseException(
          'Fehler beim Abrufen der Charaktere: $e',
          operation: 'createAutoEntriesForCampaign',
        );
      }
      
      for (final character in characters) {
        final existingEntry = await _findExistingEntryForCharacter(character);
        if (existingEntry == null) {
          final entry = await _createCharacterWikiEntry(character);
          if (entry != null) entries.add(entry);
        }
      }
      
      // Kreaturen verknüpfen
      List<Creature> creatures;
      try {
        // Creatures sind nicht direkt mit Campaign verknüpft, wir holen alle
        creatures = await _creatureRepository.findAll();
      } catch (e) {
        throw DatabaseException(
          'Fehler beim Abrufen der Kreaturen: $e',
          operation: 'createAutoEntriesForCampaign',
        );
      }
      
      for (final creature in creatures) {
        final existingEntry = await _findExistingEntryForCreature(creature);
        if (existingEntry == null) {
          final entry = await _createCreatureWikiEntry(creature);
          if (entry != null) entries.add(entry);
        }
      }
      
      // Kampagnen-Details verknüpfen
      final campaign = await _campaignRepository.findById(campaignId);
      if (campaign != null) {
        final existingEntry = await _findExistingEntryForCampaign(campaign);
        if (existingEntry == null) {
          final entry = await _createCampaignWikiEntry(campaign);
          if (entry != null) entries.add(entry);
        }
      }
      
      return entries;
    });
  }

  /// Findet bestehenden Wiki-Eintrag für einen Charakter
  Future<WikiEntry?> _findExistingEntryForCharacter(PlayerCharacter character) async {
    try {
      final entries = await _wikiRepository.findByType(WikiEntryType.Person);
      for (final entry in entries) {
        if (entry.title == character.name && entry.campaignId == character.campaignId) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Suche nach Charakter-Eintrag: $e');
      }
      return null;
    }
  }

  /// Findet bestehenden Wiki-Eintrag für eine Kreatur
  Future<WikiEntry?> _findExistingEntryForCreature(Creature creature) async {
    try {
      final entries = await _wikiRepository.findByType(WikiEntryType.Creature);
      for (final entry in entries) {
        if (entry.title == creature.name) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Suche nach Kreatur-Eintrag: $e');
      }
      return null;
    }
  }

  /// Findet bestehenden Wiki-Eintrag für eine Kampagne
  Future<WikiEntry?> _findExistingEntryForCampaign(Campaign campaign) async {
    try {
      final entries = await _wikiRepository.findByType(WikiEntryType.Place);
      for (final entry in entries) {
        if (entry.title == campaign.title) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Suche nach Kampagnen-Eintrag: $e');
      }
      return null;
    }
  }

  /// Erstellt Wiki-Eintrag für einen Charakter
  Future<WikiEntry?> _createCharacterWikiEntry(PlayerCharacter character) async {
    try {
      final content = _generateCharacterContent(character);
      
      final entry = WikiEntry.create(
        title: character.name,
        content: content,
        entryType: WikiEntryType.Person,
        tags: _generateCharacterTags(character),
        campaignId: character.campaignId,
      );
      
      final createdEntry = await _wikiRepository.create(entry);
      
      // Erstelle automatische Verknüpfungen
      await _createAutoLinksForCharacter(createdEntry, character);
      
      return createdEntry;
    } catch (e) {
      throw DatabaseException(
        'Fehler beim Erstellen von Charakter-Wiki: $e',
        operation: '_createCharacterWikiEntry',
      );
    }
  }

  /// Erstellt Wiki-Eintrag für eine Kreatur
  Future<WikiEntry?> _createCreatureWikiEntry(Creature creature) async {
    try {
      final content = _generateCreatureContent(creature);
      
      // Creatures sind nicht direkt mit Campaign verknüpft
      // Wir nehmen die campaignId aus dem Kontext oder lassen sie leer
      final entry = WikiEntry.create(
        title: creature.name,
        content: content,
        entryType: WikiEntryType.Creature,
        tags: _generateCreatureTags(creature),
        campaignId: '', // Keine direkte Campaign-Verknüpfung
      );
      
      final createdEntry = await _wikiRepository.create(entry);
      
      // Erstelle automatische Verknüpfungen
      await _createAutoLinksForCreature(createdEntry, creature);
      
      return createdEntry;
    } catch (e) {
      throw DatabaseException(
        'Fehler beim Erstellen von Kreatur-Wiki: $e',
        operation: '_createCreatureWikiEntry',
      );
    }
  }

  /// Erstellt Wiki-Eintrag für eine Kampagne
  Future<WikiEntry?> _createCampaignWikiEntry(Campaign campaign) async {
    try {
      final content = _generateCampaignContent(campaign);
      
      final entry = WikiEntry.create(
        title: campaign.title,
        content: content,
        entryType: WikiEntryType.Place,
        tags: ['kampagne', 'welt', 'setting', 'hauptort'],
        campaignId: campaign.id,
      );
      
      final createdEntry = await _wikiRepository.create(entry);
      
      // Erstelle automatische Verknüpfungen
      await _createAutoLinksForCampaign(createdEntry, campaign);
      
      return createdEntry;
    } catch (e) {
      throw DatabaseException(
        'Fehler beim Erstellen von Kampagnen-Wiki: $e',
        operation: '_createCampaignWikiEntry',
      );
    }
  }

  /// Generiert Inhalt für Charakter-Wiki-Eintrag
  String _generateCharacterContent(PlayerCharacter character) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${character.name}');
    buffer.writeln();
    
    // Grundinformationen
    buffer.writeln('## Charakterinformationen');
    buffer.writeln('- **Spieler:** ${character.playerName}');
    buffer.writeln('- **Klasse:** ${character.className}');
    buffer.writeln('- **Rasse:** ${character.raceName}');
    buffer.writeln('- **Stufe:** ${character.level}');
    buffer.writeln('- **Rüstungsklasse:** ${character.armorClass}');
    buffer.writeln('- **Trefferpunkte:** ${character.maxHp}');
    buffer.writeln('- **Initiative-Bonus:** ${character.initiativeBonus}');
    buffer.writeln();
    
    // Attribute
    buffer.writeln('## Attribute');
    buffer.writeln('- **Stärke:** ${character.strength}');
    buffer.writeln('- **Geschicklichkeit:** ${character.dexterity}');
    buffer.writeln('- **Konstitution:** ${character.constitution}');
    buffer.writeln('- **Intelligenz:** ${character.intelligence}');
    buffer.writeln('- **Weisheit:** ${character.wisdom}');
    buffer.writeln('- **Charisma:** ${character.charisma}');
    buffer.writeln();
    
    // Zusätzliche Informationen
    if (character.description?.isNotEmpty == true) {
      buffer.writeln('## Beschreibung');
      buffer.writeln(character.description);
      buffer.writeln();
    }
    
    if (character.specialAbilities?.isNotEmpty == true) {
      buffer.writeln('## Spezielle Fähigkeiten');
      buffer.writeln(character.specialAbilities);
      buffer.writeln();
    }
    
    // Automatische Verknüpfungen
    buffer.writeln('---');
    buffer.writeln('*Dieser Eintrag wurde automatisch aus den Charakterdaten generiert.*');
    
    return buffer.toString();
  }

  /// Generiert Inhalt für Kreatur-Wiki-Eintrag
  String _generateCreatureContent(Creature creature) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${creature.name}');
    buffer.writeln();
    
    // Grundinformationen
    buffer.writeln('## Kreatur-Informationen');
    buffer.writeln('- **Rüstungsklasse:** ${creature.armorClass}');
    buffer.writeln('- **Trefferpunkte:** ${creature.maxHp}');
    buffer.writeln('- **Geschwindigkeit:** ${creature.speed}');
    buffer.writeln('- **Initiative-Bonus:** ${creature.initiativeBonus}');
    buffer.writeln();
    
    // Attribute
    buffer.writeln('## Attribute');
    buffer.writeln('- **Stärke:** ${creature.strength}');
    buffer.writeln('- **Geschicklichkeit:** ${creature.dexterity}');
    buffer.writeln('- **Konstitution:** ${creature.constitution}');
    buffer.writeln('- **Intelligenz:** ${creature.intelligence}');
    buffer.writeln('- **Weisheit:** ${creature.wisdom}');
    buffer.writeln('- **Charisma:** ${creature.charisma}');
    buffer.writeln();
    
    // Zusätzliche Informationen
    if (creature.description?.isNotEmpty == true) {
      buffer.writeln('## Beschreibung');
      buffer.writeln(creature.description);
      buffer.writeln();
    }
    
    if (creature.specialAbilities?.isNotEmpty == true) {
      buffer.writeln('## Spezielle Fähigkeiten');
      buffer.writeln(creature.specialAbilities);
      buffer.writeln();
    }
    
    // Typ und Größe
    if (creature.size?.isNotEmpty == true || creature.type?.isNotEmpty == true) {
      buffer.writeln('## Klassifikation');
      if (creature.size?.isNotEmpty == true) {
        buffer.writeln('- **Größe:** ${creature.size}');
      }
      if (creature.type?.isNotEmpty == true) {
        buffer.writeln('- **Typ:** ${creature.type}');
      }
      if (creature.subtype?.isNotEmpty == true) {
        buffer.writeln('- **Subtyp:** ${creature.subtype}');
      }
      if (creature.alignment?.isNotEmpty == true) {
        buffer.writeln('- **Gesinnung:** ${creature.alignment}');
      }
      buffer.writeln();
    }
    
    // Automatische Verknüpfungen
    buffer.writeln('---');
    buffer.writeln('*Dieser Eintrag wurde automatisch aus den Kreaturdaten generiert.*');
    
    return buffer.toString();
  }

  /// Generiert Inhalt für Kampagnen-Wiki-Eintrag
  String _generateCampaignContent(Campaign campaign) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${campaign.title}');
    buffer.writeln();
    
    buffer.writeln('## Kampagnen-Übersicht');
    buffer.writeln(campaign.description);
    buffer.writeln();
    
    buffer.writeln('## Kampagnen-Struktur');
    buffer.writeln('- **Startdatum:** TBD');
    buffer.writeln('- **Spieleranzahl:** TBD');
    buffer.writeln('- **Aktuelles Level:** TBD');
    buffer.writeln('- **Setting:** D&D 5e Fantasy');
    buffer.writeln();
    
    buffer.writeln('## Wichtige Orte');
    buffer.writeln('*Orte werden automatisch verknüpft, sobald Wiki-Einträge erstellt werden.*');
    buffer.writeln();
    
    buffer.writeln('## Wichtige NPCs');
    buffer.writeln('*NPCs werden automatisch verknüpft, sobald Wiki-Einträge erstellt werden.*');
    buffer.writeln();
    
    buffer.writeln('---');
    buffer.writeln('*Dieser Eintrag wurde automatisch aus den Kampagnendaten generiert.*');
    
    return buffer.toString();
  }

  /// Generiert Tags für Charakter
  List<String> _generateCharacterTags(PlayerCharacter character) {
    final tags = <String>[];
    tags.add('charakter');
    tags.add('spieler');
    tags.add(character.className.toLowerCase().replaceAll(' ', '-'));
    tags.add(character.raceName.toLowerCase().replaceAll(' ', '-'));
    if (character.level >= 10) tags.add('high-level');
    
    return tags;
  }

  /// Generiert Tags für Kreatur
  List<String> _generateCreatureTags(Creature creature) {
    final tags = <String>[];
    tags.add('kreatur');
    tags.add('monster');
    
    if (creature.type?.isNotEmpty == true) {
      tags.add(creature.type!.toLowerCase().replaceAll(' ', '-'));
    }
    if (creature.size?.isNotEmpty == true) {
      tags.add('${creature.size!.toLowerCase()}-size');
    }
    if (creature.alignment?.isNotEmpty == true) {
      tags.add(creature.alignment!.toLowerCase().replaceAll(' ', '-'));
    }
    
    return tags;
  }

  /// Erstellt automatische Verknüpfungen für Charakter
  Future<void> _createAutoLinksForCharacter(WikiEntry entry, PlayerCharacter character) async {
    try {
      // Verlinke mit Rasse (falls Wiki-Eintrag existiert)
      if (character.raceName.isNotEmpty) {
        await _createLinkIfExists(entry, character.raceName, WikiLinkType.related);
      }
      
      // Verlinke mit Klasse (falls Wiki-Eintrag existiert)
      if (character.className.isNotEmpty) {
        await _createLinkIfExists(entry, character.className, WikiLinkType.related);
      }
      
      // Verlinke mit Kampagne
      if (character.campaignId.isNotEmpty) {
        final campaign = await _campaignRepository.findById(character.campaignId);
        if (campaign != null) {
          await _createLinkIfExists(entry, campaign.title, WikiLinkType.related);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Auto-Links für Charakter: $e');
      }
    }
  }

  /// Erstellt automatische Verknüpfungen für Kreatur
  Future<void> _createAutoLinksForCreature(WikiEntry entry, Creature creature) async {
    try {
      // Verlinke mit Typ (falls Wiki-Eintrag existiert)
      if (creature.type?.isNotEmpty == true) {
        await _createLinkIfExists(entry, creature.type!, WikiLinkType.related);
      }
      
      // Verlinke mit Subtyp (falls Wiki-Eintrag existiert)
      if (creature.subtype?.isNotEmpty == true) {
        await _createLinkIfExists(entry, creature.subtype!, WikiLinkType.related);
      }
      
      // Verlinke mit Größe
      if (creature.size?.isNotEmpty == true) {
        await _createLinkIfExists(entry, '${creature.size!}-Kreatur', WikiLinkType.related);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Auto-Links für Kreatur: $e');
      }
    }
  }

  /// Erstellt automatische Verknüpfungen für Kampagne
  Future<void> _createAutoLinksForCampaign(WikiEntry entry, Campaign campaign) async {
    try {
      // Verlinke mit wichtigen Orten (falls vorhanden)
      final locations = await _getImportantLocationsForCampaign(campaign.id);
      for (final location in locations) {
        await _createLinkIfExists(entry, location, WikiLinkType.related);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Auto-Links für Kampagne: $e');
      }
    }
  }

  /// Erstellt Verknüpfung falls Ziel-Eintrag existiert
  Future<void> _createLinkIfExists(WikiEntry sourceEntry, String targetTitle, WikiLinkType linkType) async {
    try {
      final targetEntries = await _wikiRepository.findByTitle(targetTitle);
      if (targetEntries != null && targetEntries.isNotEmpty) {
        for (final target in targetEntries) {
          final link = WikiLink(
            sourceEntryId: sourceEntry.id,
            targetEntryId: target.id,
            linkType: linkType,
          );
          
          await _wikiLinkRepository.create(link);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Auto-Link-Erstellung: $e');
      }
    }
  }

  /// Holt wichtige Orte für eine Kampagne
  Future<List<String>> _getImportantLocationsForCampaign(String campaignId) async {
    try {
      // Suche nach allen Wiki-Einträgen vom Typ Place
      final allPlaces = await _wikiRepository.findByType(WikiEntryType.Place);
      
      // Filtere nach Kampagne
      final places = allPlaces.where((place) => place.campaignId == campaignId).toList();
      
      return places.map((place) => place.title).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Orte-Suche: $e');
      }
      return <String>[];
    }
  }

  /// Smart-Suggestions für neue Wiki-Einträge
  Future<ServiceResult<List<WikiSuggestion>>> getSmartSuggestions(String campaignId) async {
    return performServiceOperation('getSmartSuggestions', () async {
      final suggestions = <WikiSuggestion>[];
      
      // Analyse vorhandener Daten
      List<PlayerCharacter> characters;
      try {
        characters = await _playerCharacterRepository.findByCampaign(campaignId);
      } catch (e) {
        throw DatabaseException(
          'Fehler beim Abrufen der Charaktere: $e',
          operation: 'getSmartSuggestions',
        );
      }
      
      final allEntries = await _wikiRepository.findAll();
      final existingTitles = allEntries.map((e) => e.title.toLowerCase()).toSet();
      
      // Vorschläge basierend auf Charakter-Informationen
      for (final character in characters) {
        // Vorschlag für Rasse (falls nicht vorhanden)
        if (character.raceName.isNotEmpty && 
            !existingTitles.contains(character.raceName.toLowerCase())) {
          suggestions.add(WikiSuggestion(
            title: character.raceName,
            type: WikiEntryType.Lore,
            reason: 'Rasse von ${character.name}',
            confidence: 0.8,
            suggestedTags: ['rasse', 'volk', character.raceName.toLowerCase()],
          ));
        }
        
        // Vorschlag für Klasse (falls nicht vorhanden)
        if (character.className.isNotEmpty && 
            !existingTitles.contains(character.className.toLowerCase())) {
          suggestions.add(WikiSuggestion(
            title: character.className,
            type: WikiEntryType.Lore,
            reason: 'Klasse von ${character.name}',
            confidence: 0.7,
            suggestedTags: ['klasse', 'beruf', character.className.toLowerCase()],
          ));
        }
      }
      
      // Sortiere nach Konfidenz
      suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      return suggestions.take(10).toList(); // Top 10 Vorschläge
    });
  }

  /// Aktualisiert alle Auto-Links nach Änderungen
  Future<ServiceResult<void>> updateAutoLinksForCampaign(String campaignId) async {
    return performServiceOperation('updateAutoLinksForCampaign', () async {
      // Lösche alte Auto-Links
      await _deleteAutoLinksForCampaign(campaignId);
      
      // Erstelle neue Auto-Links
      final result = await createAutoEntriesForCampaign(campaignId);
      // Überprüfe ob das Ergebnis einen Fehler enthält
      if (!result.isSuccess) {
        throw DatabaseException(
          'Fehler bei Auto-Links Aktualisierung',
          operation: 'updateAutoLinksForCampaign',
        );
      }
    });
  }

  /// Löscht alle Auto-Links für eine Kampagne
  Future<void> _deleteAutoLinksForCampaign(String campaignId) async {
    try {
      // Hole alle Links
      final allLinks = await _wikiLinkRepository.findAll();
      
      // Filtere nach Kampagne und Auto-Links
      // Da WikiLink keine campaignId hat, müssen wir über die sourceEntry filtern
      final sourceEntries = await _wikiRepository.findByCampaign(campaignId);
      final sourceEntryIds = sourceEntries.map((e) => e.id).toSet();
      
      final linksToDelete = allLinks.where((link) => 
        sourceEntryIds.contains(link.sourceEntryId)
      );
      
      for (final link in linksToDelete) {
        await _wikiLinkRepository.delete(link.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler beim Löschen der Auto-Links: $e');
      }
    }
  }

  /// Prüft ob Auto-Links für eine Kampagne aktuell sind
  Future<ServiceResult<bool>> areAutoLinksUpToDate(String campaignId) async {
    return performServiceOperation('areAutoLinksUpToDate', () async {
      try {
        // Hole alle Einträge für die Kampagne
        final entries = await _wikiRepository.findByCampaign(campaignId);
        
        // Prüfe ob Einträge veraltet sind (älter als 1 Tag = veraltet)
        final cutoffDate = DateTime.now().subtract(const Duration(days: 1));
        final outdatedEntries = entries.where((entry) => 
          entry.createdAt.isBefore(cutoffDate) && 
          entry.tags.contains('auto-generated')
        );
          
        return outdatedEntries.isEmpty;
      } catch (e) {
        throw DatabaseException(
          'Fehler bei Prüfung der Auto-Links: $e',
          operation: 'areAutoLinksUpToDate',
        );
      }
    });
  }

  /// Erstellt fehlende Auto-Links für eine Kampagne
  Future<ServiceResult<int>> createMissingAutoLinks(String campaignId) async {
    return performServiceOperation('createMissingAutoLinks', () async {
      int createdCount = 0;
      
      // Prüfe ob Auto-Links aktuell sind
      final upToDateResult = await areAutoLinksUpToDate(campaignId);
      if (upToDateResult.isSuccess && upToDateResult.data!) {
        return createdCount; // Bereits aktuell
      }
      
      // Erstelle neue Auto-Einträge
      final entriesResult = await createAutoEntriesForCampaign(campaignId);
      if (entriesResult.isSuccess) {
        createdCount = entriesResult.data!.length;
      }
      
      return createdCount;
    });
  }

  // ========== STATISCHE HELPER METHODEN ==========

  /// Formatiert Auto-Link-Statistiken
  static String formatAutoLinkStats(Map<String, dynamic> stats) {
    final buffer = StringBuffer();
    buffer.writeln('Auto-Link Statistiken:');
    buffer.writeln('- Kampagnen mit Auto-Links: ${stats['campaigns_with_links'] ?? 0}');
    buffer.writeln('- Gesamt Auto-Links: ${stats['total_auto_links'] ?? 0}');
    buffer.writeln('- Auto-Einträge erstellt: ${stats['auto_entries_created'] ?? 0}');
    buffer.writeln('- Letzte Aktualisierung: ${stats['last_update'] ?? 'Nie'}');
    
    return buffer.toString();
  }

  /// Gibt empfohlene Auto-Link-Einstellungen zurück
  static Map<String, dynamic> getRecommendedAutoLinkSettings() {
    return {
      'auto_create_entries': true,
      'auto_create_links': true,
      'update_frequency_days': 7,
      'confidence_threshold': 0.6,
      'max_suggestions': 10,
      'link_types_to_create': ['related', 'reference'],
      'skip_existing_entries': true,
    };
  }

  /// Validiert Auto-Link-Konfiguration
  static bool validateAutoLinkConfig(Map<String, dynamic> config) {
    final requiredKeys = ['auto_create_entries', 'auto_create_links', 'update_frequency_days'];
    
    for (final key in requiredKeys) {
      if (!config.containsKey(key)) {
        return false;
      }
    }
    
    final frequency = config['update_frequency_days'] as int?;
    if (frequency == null || frequency < 1 || frequency > 365) {
      return false;
    }
    
    final threshold = config['confidence_threshold'] as double?;
    if (threshold == null || threshold < 0.0 || threshold > 1.0) {
      return false;
    }
    
    return true;
  }
}

/// Suggestion für neuen Wiki-Eintrag
class WikiSuggestion {
  final String title;
  final WikiEntryType type;
  final String reason;
  final double confidence;
  final List<String> suggestedTags;

  WikiSuggestion({
    required this.title,
    required this.type,
    required this.reason,
    required this.confidence,
    required this.suggestedTags,
  });

  @override
  String toString() {
    return 'WikiSuggestion($title, confidence: ${confidence.toStringAsFixed(2)})';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.name,
      'reason': reason,
      'confidence': confidence,
      'suggestedTags': suggestedTags,
    };
  }

  factory WikiSuggestion.fromMap(Map<String, dynamic> map) {
    return WikiSuggestion(
      title: map['title'] as String,
      type: WikiEntryType.values.firstWhere(
        (type) => type.name == map['type'] as String,
        orElse: () => WikiEntryType.Lore,
      ),
      reason: map['reason'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      suggestedTags: (map['suggestedTags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
