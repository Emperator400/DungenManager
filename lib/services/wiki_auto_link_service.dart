// Dart Core

// Eigene Projekte
import '../models/wiki_entry.dart';
import '../models/player_character.dart';
import '../models/creature.dart';
import '../models/campaign.dart';
import '../models/wiki_link.dart';
import '../database/database_helper.dart';
import '../services/wiki_link_service.dart';

/// Service für automatische Verknüpfungen und Smart-Suggestions
class WikiAutoLinkService {
  static final WikiAutoLinkService _instance = WikiAutoLinkService._internal();
  factory WikiAutoLinkService() => _instance;
  WikiAutoLinkService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final WikiLinkService _wikiLinkService = WikiLinkService();

  /// Erstellt automatisch Wiki-Einträge für Charaktere und Kreaturen
  Future<List<WikiEntry>> createAutoEntriesForCampaign(String campaignId) async {
    final entries = <WikiEntry>[];
    
    // Charaktere verknüpfen
    final characters = await _dbHelper.getPlayerCharactersForCampaign(campaignId);
    for (final character in characters) {
      final existingEntry = await _findExistingEntryForCharacter(character);
      if (existingEntry == null) {
        final entry = await _createCharacterWikiEntry(character);
        if (entry != null) entries.add(entry);
      }
    }
    
    // Kreaturen verknüpfen (falls welche existieren)
    final creatures = await _getCreaturesForCampaign(campaignId);
    for (final creature in creatures) {
      final existingEntry = await _findExistingEntryForCreature(creature);
      if (existingEntry == null) {
        final entry = await _createCreatureWikiEntry(creature);
        if (entry != null) entries.add(entry);
      }
    }
    
    // Kampagnen-Details verknüpfen
    final campaigns = await _dbHelper.getAllCampaigns();
    final campaign = campaigns.firstWhere(
      (c) => c.id == campaignId,
      orElse: () => Campaign(
        id: '', 
        title: '', 
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (campaign.id.isNotEmpty) {
      final existingEntry = await _findExistingEntryForCampaign(campaign);
      if (existingEntry == null) {
        final entry = await _createCampaignWikiEntry(campaign);
        if (entry != null) entries.add(entry);
      }
    }
    
    return entries;
  }

  /// Findet bestehenden Wiki-Eintrag für einen Charakter
  Future<WikiEntry?> _findExistingEntryForCharacter(PlayerCharacter character) async {
    final allEntries = await _dbHelper.getAllWikiEntries();
    
    for (final entry in allEntries) {
      if (entry.entryType == WikiEntryType.Person && 
          entry.title.toLowerCase() == character.name.toLowerCase()) {
        return entry;
      }
    }
    
    return null;
  }

  /// Findet bestehenden Wiki-Eintrag für eine Kreatur
  Future<WikiEntry?> _findExistingEntryForCreature(Creature creature) async {
    final allEntries = await _dbHelper.getAllWikiEntries();
    
    for (final entry in allEntries) {
      if (entry.entryType == WikiEntryType.Creature && 
          entry.title.toLowerCase() == creature.name.toLowerCase()) {
        return entry;
      }
    }
    
    return null;
  }

  /// Findet bestehenden Wiki-Eintrag für eine Kampagne
  Future<WikiEntry?> _findExistingEntryForCampaign(Campaign campaign) async {
    final allEntries = await _dbHelper.getAllWikiEntries();
    
    for (final entry in allEntries) {
      if (entry.entryType == WikiEntryType.Place && 
          entry.title.toLowerCase() == campaign.title.toLowerCase()) {
        return entry;
      }
    }
    
    return null;
  }

  /// Erstellt Wiki-Eintrag für einen Charakter
  Future<WikiEntry?> _createCharacterWikiEntry(PlayerCharacter character) async {
    final content = _generateCharacterContent(character);
    
      final entry = WikiEntry(
      id: '', // Wird von Datenbank generiert
      title: character.name,
      content: content,
      entryType: WikiEntryType.Person,
      tags: _generateCharacterTags(character),
      campaignId: character.campaignId,
      imageUrl: character.imagePath,
      createdBy: 'System Auto-Link',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: const [],
      isMarkdown: true,
      isFavorite: false,
    );
    
    try {
      final id = await _dbHelper.insertWikiEntry(entry);
      final createdEntry = entry.copyWith(id: id.toString());
      
      // Erstelle automatische Verknüpfungen
      await _createAutoLinksForCharacter(createdEntry, character);
      
      return createdEntry;
    } catch (e) {
      print('Fehler beim Erstellen von Charakter-Wiki: $e');
      return null;
    }
  }

  /// Erstellt Wiki-Eintrag für eine Kreatur
  Future<WikiEntry?> _createCreatureWikiEntry(Creature creature) async {
    final content = _generateCreatureContent(creature);
    
    final entry = WikiEntry(
      id: '', // Wird von Datenbank generiert
      title: creature.name,
      content: content,
      entryType: WikiEntryType.Creature,
      tags: _generateCreatureTags(creature),
      createdBy: 'System Auto-Link',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: const [],
      isMarkdown: true,
      isFavorite: false,
    );
    
    try {
      final id = await _dbHelper.insertWikiEntry(entry);
      final createdEntry = entry.copyWith(id: id.toString());
      
      // Erstelle automatische Verknüpfungen
      await _createAutoLinksForCreature(createdEntry, creature);
      
      return createdEntry;
    } catch (e) {
      print('Fehler beim Erstellen von Kreatur-Wiki: $e');
      return null;
    }
  }

  /// Erstellt Wiki-Eintrag für eine Kampagne
  Future<WikiEntry?> _createCampaignWikiEntry(Campaign campaign) async {
    final content = _generateCampaignContent(campaign);
    
    final entry = WikiEntry(
      id: '', // Wird von Datenbank generiert
      title: campaign.title,
      content: content,
      entryType: WikiEntryType.Place,
      tags: ['kampagne', 'welt', 'setting', 'hauptort'],
      createdBy: 'System Auto-Link',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: const [],
      isMarkdown: true,
      isFavorite: false,
    );
    
    try {
      final id = await _dbHelper.insertWikiEntry(entry);
      final createdEntry = entry.copyWith(id: id.toString());
      
      // Erstelle automatische Verknüpfungen
      await _createAutoLinksForCampaign(createdEntry, campaign);
      
      return createdEntry;
    } catch (e) {
      print('Fehler beim Erstellen von Kampagnen-Wiki: $e');
      return null;
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
      final campaigns = await _dbHelper.getAllCampaigns();
      final campaign = campaigns.firstWhere(
        (c) => c.id == character.campaignId,
        orElse: () => Campaign(
          id: '', 
          title: '', 
          description: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (campaign.id.isNotEmpty) {
        await _createLinkIfExists(entry, campaign.title, WikiLinkType.related);
      }
    }
  }

  /// Erstellt automatische Verknüpfungen für Kreatur
  Future<void> _createAutoLinksForCreature(WikiEntry entry, Creature creature) async {
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
  }

  /// Erstellt automatische Verknüpfungen für Kampagne
  Future<void> _createAutoLinksForCampaign(WikiEntry entry, Campaign campaign) async {
    // Verlinke mit wichtigen Orten (falls vorhanden)
    final locations = await _getImportantLocationsForCampaign(campaign.id);
    for (final location in locations) {
      await _createLinkIfExists(entry, location, WikiLinkType.related);
    }
  }

  /// Erstellt Verknüpfung falls Ziel-Eintrag existiert
  Future<void> _createLinkIfExists(WikiEntry sourceEntry, String targetTitle, WikiLinkType linkType) async {
    final allEntries = await _dbHelper.getAllWikiEntries();
    final targetEntry = allEntries.firstWhere(
      (entry) => entry.title.toLowerCase() == targetTitle.toLowerCase(),
      orElse: () => WikiEntry(
        id: '', 
        title: '', 
        content: '', 
        entryType: WikiEntryType.Lore,
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: const [],
        isMarkdown: true,
        isFavorite: false,
      ),
    );
    
    if (targetEntry.id.isNotEmpty) {
      await WikiLinkService.createManualLink(
        sourceEntryId: sourceEntry.id,
        targetEntryId: targetEntry.id,
        linkType: linkType,
        createdBy: 'System Auto-Link',
      );
    }
  }

  /// Holt Kreaturen für eine Kampagne (falls vorhanden)
  Future<List<Creature>> _getCreaturesForCampaign(String campaignId) async {
    // TODO: Implementiere Campaign-spezifische Kreaturen
    // Aktuell geben wir leere Liste zurück
    return [];
  }

  /// Holt wichtige Orte für eine Kampagne
  Future<List<String>> _getImportantLocationsForCampaign(String campaignId) async {
    // TODO: Implementiere Campaign-spezifische Orte
    // Könnte aus Wiki-Einträgen vom Typ 'Place' extrahiert werden
    return [];
  }

  /// Smart-Suggestions für neue Wiki-Einträge
  Future<List<WikiSuggestion>> getSmartSuggestions(String campaignId) async {
    final suggestions = <WikiSuggestion>[];
    
    // Analyse vorhandener Daten
    final characters = await _dbHelper.getPlayerCharactersForCampaign(campaignId);
    final allEntries = await _dbHelper.getAllWikiEntries();
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
  }

  /// Aktualisiert alle Auto-Links nach Änderungen
  Future<void> updateAutoLinksForCampaign(String campaignId) async {
    // Lösche alte Auto-Links
    await _deleteAutoLinksForCampaign(campaignId);
    
    // Erstelle neue Auto-Links
    await createAutoEntriesForCampaign(campaignId);
  }

  /// Löscht alle Auto-Links für eine Kampagne
  Future<void> _deleteAutoLinksForCampaign(String campaignId) async {
    final allEntries = await _dbHelper.getAllWikiEntries();
    final campaignEntries = allEntries.where((e) => e.campaignId == campaignId);
    
    for (final entry in campaignEntries) {
      final links = await WikiLinkService.getOutgoingLinks(entry.id);
      for (final link in links) {
        if (link.createdBy == 'System Auto-Link') {
          await WikiLinkService.deleteLink(link.id);
        }
      }
    }
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
}
