// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/quest.dart';
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';
import 'exceptions/service_exceptions.dart';

/// Service für die Integration von Quests mit dem Lore Keeper System
/// Ermöglicht es Quests, Informationen aus Wiki-Einträgen zu nutzen
/// und Wiki-Einträge mit Quests zu verknüpfen
class QuestLoreIntegrationService {
  static final QuestLoreIntegrationService _instance = QuestLoreIntegrationService._internal();
  factory QuestLoreIntegrationService() => _instance;
  QuestLoreIntegrationService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Verknüpft einen Wiki-Eintrag mit einer Quest
  Future<Quest> linkWikiEntryToQuest(String questId, String wikiEntryId) async {
    try {
      if (questId.isEmpty) {
        throw ValidationException(
          'Quest ID ist erforderlich',
          operation: 'linkWikiEntryToQuest',
        );
      }
      
      if (wikiEntryId.isEmpty) {
        throw ValidationException(
          'Wiki Entry ID ist erforderlich',
          operation: 'linkWikiEntryToQuest',
        );
      }

      final questMaps = await (await _dbHelper.database).query('quests', where: 'id = ?', whereArgs: [questId]);
      if (questMaps.isEmpty) {
        throw ResourceNotFoundException.forId('Quest', questId, operation: 'linkWikiEntryToQuest');
      }
      
      final quest = Quest.fromMap(questMaps.first);
      final linkedIds = List<String>.from(quest.linkedWikiEntryIds ?? []);
      if (!linkedIds.contains(wikiEntryId)) {
        linkedIds.add(wikiEntryId);
      }
      
      final updatedQuest = quest.copyWith(
        linkedWikiEntryIds: linkedIds,
        updatedAt: DateTime.now(),
      );
      
      await _dbHelper.updateQuest(updatedQuest);
      return updatedQuest;
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'linkWikiEntryToQuest');
    }
  }

  /// Entfernt die Verknüpfung zwischen einem Wiki-Eintrag und einer Quest
  Future<Quest> unlinkWikiEntryFromQuest(String questId, String wikiEntryId) async {
    try {
      if (questId.isEmpty) {
        throw ValidationException(
          'Quest ID ist erforderlich',
          operation: 'unlinkWikiEntryFromQuest',
        );
      }
      
      if (wikiEntryId.isEmpty) {
        throw ValidationException(
          'Wiki Entry ID ist erforderlich',
          operation: 'unlinkWikiEntryFromQuest',
        );
      }

      final questMaps = await (await _dbHelper.database).query('quests', where: 'id = ?', whereArgs: [questId]);
      if (questMaps.isEmpty) {
        throw ResourceNotFoundException.forId('Quest', questId, operation: 'unlinkWikiEntryFromQuest');
      }
      
      final quest = Quest.fromMap(questMaps.first);
      final linkedIds = List<String>.from(quest.linkedWikiEntryIds ?? []);
      linkedIds.remove(wikiEntryId);
      
      final updatedQuest = quest.copyWith(
        linkedWikiEntryIds: linkedIds,
        updatedAt: DateTime.now(),
      );
      
      await _dbHelper.updateQuest(updatedQuest);
      return updatedQuest;
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'unlinkWikiEntryFromQuest');
    }
  }

  /// Gibt alle Wiki-Einträge zurück, die mit einer Quest verknüpft sind
  Future<List<WikiEntry>> getWikiEntriesForQuest(String questId) async {
    try {
      if (questId.isEmpty) {
        throw ValidationException(
          'Quest ID ist erforderlich',
          operation: 'getWikiEntriesForQuest',
        );
      }

      final questMaps = await (await _dbHelper.database).query('quests', where: 'id = ?', whereArgs: [questId]);
      if (questMaps.isEmpty) {
        throw ResourceNotFoundException.forId('Quest', questId, operation: 'getWikiEntriesForQuest');
      }
      
      final quest = Quest.fromMap(questMaps.first);
      if (!quest.hasWikiLinks) return [];

      final wikiEntries = <WikiEntry>[];
      for (final wikiEntryId in quest.linkedWikiEntryIds) {
        final entryMaps = await (await _dbHelper.database).query('wiki_entries', where: 'id = ?', whereArgs: [wikiEntryId]);
        if (entryMaps.isNotEmpty) {
          wikiEntries.add(WikiEntry.fromMap(entryMaps.first));
        }
      }
      return wikiEntries;
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'getWikiEntriesForQuest');
    }
  }

  /// Gibt alle Quests zurück, die mit einem bestimmten Wiki-Eintrag verknüpft sind
  Future<List<Quest>> getQuestsForWikiEntry(String wikiEntryId) async {
    try {
      if (wikiEntryId.isEmpty) {
        throw ValidationException(
          'Wiki Entry ID ist erforderlich',
          operation: 'getQuestsForWikiEntry',
        );
      }

      final allQuestMaps = await (await _dbHelper.database).query('quests');
      final allQuests = allQuestMaps.map((map) => Quest.fromMap(map)).toList();
      return allQuests.where((quest) => 
          quest.linkedWikiEntryIds.contains(wikiEntryId)).toList();
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'getQuestsForWikiEntry');
    }
  }

  /// Sucht nach relevanten Wiki-Einträgen basierend auf Quest-Informationen
  Future<List<WikiEntry>> findRelevantWikiEntries(Quest quest) async {
    try {
      final allWikiMaps = await (await _dbHelper.database).query('wiki_entries');
      final allWikiEntries = allWikiMaps.map((map) => WikiEntry.fromMap(map)).toList();
      final relevantEntries = <WikiEntry>[];
      
      final searchTerms = <String>[];
      
      // Suchbegriffe aus Quest-Informationen extrahieren
      searchTerms.addAll(quest.tags);
      if (quest.hasLocation) {
        searchTerms.add(quest.location!);
      }
      searchTerms.addAll(quest.involvedNpcs);
      
      // Titel und Beschreibung in Wörter aufteilen
      searchTerms.addAll(_extractWords(quest.title));
      searchTerms.addAll(_extractWords(quest.description));
      searchTerms.addAll(_extractWords(quest.goal));
      
      for (final entry in allWikiEntries) {
        if (_isEntryRelevant(entry, searchTerms, quest)) {
          relevantEntries.add(entry);
        }
      }
      
      // Nach Relevanz sortieren
      relevantEntries.sort((a, b) => _calculateRelevanceScore(b, searchTerms, quest)
          .compareTo(_calculateRelevanceScore(a, searchTerms, quest)));
      
      return relevantEntries.take(10).toList(); // Top 10 relevante Einträge
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'findRelevantWikiEntries');
    }
  }

  /// Erstellt automatisch Wiki-Verknüpfungen basierend auf Quest-Kontext
  Future<Quest> suggestWikiLinks(Quest quest) async {
    try {
      final relevantEntries = await findRelevantWikiEntries(quest);
      var updatedQuest = quest;
      
      for (final entry in relevantEntries) {
        if (_shouldAutoLink(entry, quest)) {
          final linkedIds = List<String>.from(updatedQuest.linkedWikiEntryIds ?? []);
          if (!linkedIds.contains(entry.id)) {
            linkedIds.add(entry.id);
          }
          updatedQuest = updatedQuest.copyWith(
            linkedWikiEntryIds: linkedIds,
            updatedAt: DateTime.now(),
          );
        }
      }
      
      if (updatedQuest.linkedWikiEntryIds.length > quest.linkedWikiEntryIds.length) {
        await _dbHelper.updateQuest(updatedQuest);
      }
      
      return updatedQuest;
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'suggestWikiLinks');
    }
  }

  /// Erstellt Wiki-Einträge aus Quest-Informationen (NPCs, Orte, etc.)
  Future<List<WikiEntry>> createWikiEntriesFromQuest(Quest quest) async {
    try {
      final createdEntries = <WikiEntry>[];
      
      // NPCs als Personen-Einträge erstellen
      for (final npcName in quest.involvedNpcs) {
        if (await _shouldCreateNpcEntry(npcName)) {
          final npcEntry = WikiEntry.create(
            title: npcName,
            content: 'NPC aus der Quest: ${quest.title}\n\n${quest.description}',
            entryType: WikiEntryType.Person,
            tags: ['NPC', 'Quest', ...quest.tags],
            createdBy: 'Quest-System',
          );
          
          await _dbHelper.insertWikiEntry(npcEntry);
          createdEntries.add(npcEntry);
        }
      }
      
      // Ort als Orts-Eintrag erstellen
      if (quest.hasLocation && await _shouldCreateLocationEntry(quest.location!)) {
        final locationEntry = WikiEntry.create(
          title: quest.location!,
          content: 'Schauplatz der Quest: ${quest.title}\n\n${quest.goal}',
          entryType: WikiEntryType.Place,
          tags: ['Schauplatz', 'Quest', ...quest.tags],
          createdBy: 'Quest-System',
        );
        
        await _dbHelper.insertWikiEntry(locationEntry);
        createdEntries.add(locationEntry);
      }
      
      // Quest als Lore-Eintrag erstellen
      final questEntry = WikiEntry.create(
        title: quest.title,
        content: '''# ${quest.title}

**Quest-Typ:** ${quest.questTypeDescription}  
**Schwierigkeit:** ${quest.difficultyDescription}  
**Empfohlenes Level:** ${quest.recommendedLevel ?? 'Keine Angabe'}

## Beschreibung
${quest.description}

## Ziel
${quest.goal}

${quest.hasLocation ? '## Ort\n${quest.location}' : ''}

${quest.hasNpcs ? '## Beteiligte NPCs\n${quest.npcsString}' : ''}

${quest.hasRewards ? '## Belohnungen\n${_formatRewardsForWiki(quest)}' : ''}

---
*Automatisch erstellt aus Quest-System*''',
        entryType: WikiEntryType.Lore,
        tags: ['Quest', quest.questTypeDescription, ...quest.tags],
        isMarkdown: true,
        createdBy: 'Quest-System',
      );
      
      await _dbHelper.insertWikiEntry(questEntry);
      createdEntries.add(questEntry);
      
      return createdEntries;
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'createWikiEntriesFromQuest');
    }
  }

  /// Gibt Statistiken über die Quest-Wiki-Integration zurück
  Future<Map<String, dynamic>> getIntegrationStats() async {
    try {
      final allQuestMaps = await (await _dbHelper.database).query('quests');
      final allQuests = allQuestMaps.map((map) => Quest.fromMap(map)).toList();
      final allWikiMaps = await (await _dbHelper.database).query('wiki_entries');
      final allWikiEntries = allWikiMaps.map((map) => WikiEntry.fromMap(map)).toList();
      
      final questsWithWikiLinks = allQuests.where((quest) => quest.hasWikiLinks).length;
      final totalWikiLinks = allQuests.fold(0, (sum, quest) => sum + quest.linkedWikiEntryIds.length);
      
      // Wiki-Einträge nach Typ gruppieren
      final entriesByType = <WikiEntryType, int>{};
      for (final entry in allWikiEntries) {
        entriesByType[entry.entryType] = (entriesByType[entry.entryType] ?? 0) + 1;
      }
      
      return {
        'totalQuests': allQuests.length,
        'questsWithWikiLinks': questsWithWikiLinks,
        'wikiLinkRatio': allQuests.isNotEmpty ? (questsWithWikiLinks / allQuests.length) * 100 : 0,
        'totalWikiLinks': totalWikiLinks,
        'totalWikiEntries': allWikiEntries.length,
        'entriesByType': entriesByType.map((key, value) => MapEntry(key.toString(), value)),
      };
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'getIntegrationStats');
    }
  }

  /// Bereinigt veraltete Verknüpfungen (z.B. zu gelöschten Wiki-Einträgen)
  Future<void> cleanupOrphanedLinks() async {
    try {
      final allQuestMaps = await (await _dbHelper.database).query('quests');
      final allQuests = allQuestMaps.map((map) => Quest.fromMap(map)).toList();
      final allWikiMaps = await (await _dbHelper.database).query('wiki_entries');
      final allWikiEntries = allWikiMaps.map((map) => WikiEntry.fromMap(map)).toList();
      final validWikiIds = allWikiEntries.map((entry) => entry.id).toSet();
      
      for (final quest in allQuests) {
        final validLinks = quest.linkedWikiEntryIds
            .where((wikiId) => validWikiIds.contains(wikiId))
            .toList();
        
        if (validLinks.length != quest.linkedWikiEntryIds.length) {
          final cleanedQuest = quest.copyWith(
            linkedWikiEntryIds: validLinks,
            updatedAt: DateTime.now(),
          );
          
          await _dbHelper.updateQuest(cleanedQuest);
        }
      }
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'cleanupOrphanedLinks');
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Prüft ob ein Eintrag für die Suchbegriffe relevant ist
  bool _isEntryRelevant(WikiEntry entry, List<String> searchTerms, Quest quest) {
    final entryText = '${entry.title} ${entry.content} ${entry.tags.join(' ')}'.toLowerCase();
    
    // Direkte Treffer
    for (final term in searchTerms) {
      if (entryText.contains(term.toLowerCase())) {
        return true;
      }
    }
    
    // Typ-basierte Relevanz
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return quest.hasNpcs && quest.involvedNpcs.any((npc) => 
            entry.title.toLowerCase().contains(npc.toLowerCase()));
      case WikiEntryType.Place:
        return quest.hasLocation && 
            entry.title.toLowerCase().contains(quest.location!.toLowerCase());
      case WikiEntryType.Faction:
        return quest.tags.any((tag) => 
            entry.title.toLowerCase().contains(tag.toLowerCase()));
      case WikiEntryType.Lore:
        return entry.title.toLowerCase().contains(quest.title.toLowerCase()) ||
               entry.tags.contains('Quest');
      default:
        return false;
    }
  }

  /// Berechnet einen Relevanz-Score für die Sortierung
  double _calculateRelevanceScore(WikiEntry entry, List<String> searchTerms, Quest quest) {
    double score = 0.0;
    final entryText = '${entry.title} ${entry.content} ${entry.tags.join(' ')}'.toLowerCase();
    
    for (final term in searchTerms) {
      final termLower = term.toLowerCase();
      if (entry.title.toLowerCase() == termLower) {
        score += 10.0; // Exakte Titel-Übereinstimmung
      } else if (entry.title.toLowerCase().contains(termLower)) {
        score += 5.0; // Titel enthält Begriff
      }
      if (entryText.contains(termLower)) {
        score += 2.0; // Inhalt enthält Begriff
      }
    }
    
    // Typ-Bonus
    switch (entry.entryType) {
      case WikiEntryType.Person:
        if (quest.hasNpcs) score += 3.0;
        break;
      case WikiEntryType.Place:
        if (quest.hasLocation) score += 3.0;
        break;
      case WikiEntryType.Faction:
        if (quest.tags.isNotEmpty) score += 2.0;
        break;
      case WikiEntryType.Lore:
        score += 1.0;
        break;
      default:
        break;
    }
    
    return score;
  }

  /// Extrahiert Wörter aus einem Text für die Suche
  List<String> _extractWords(String text) => text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 2) // Nur Wörter mit mehr als 2 Buchstaben
        .toSet()
        .toList();

  /// Prüft ob automatisch verknüpft werden sollte
  bool _shouldAutoLink(WikiEntry entry, Quest quest) {
    // Nur bei hoher Relevanz automatisch verknüpfen
    return _calculateRelevanceScore(entry, _extractWords(quest.title + ' ' + quest.description), quest) > 8.0;
  }

  /// Prüft ob ein NPC-Eintrag erstellt werden sollte
  Future<bool> _shouldCreateNpcEntry(String npcName) async {
    // Prüfen ob bereits ein Eintrag existiert
    final existingMaps = await (await _dbHelper.database).query('wiki_entries');
    final existingEntries = existingMaps.map((map) => WikiEntry.fromMap(map)).toList();
    return !existingEntries.any((entry) => 
        entry.entryType == WikiEntryType.Person && 
        entry.title.toLowerCase() == npcName.toLowerCase());
  }

  /// Prüft ob ein Orts-Eintrag erstellt werden sollte
  Future<bool> _shouldCreateLocationEntry(String locationName) async {
    final existingMaps = await (await _dbHelper.database).query('wiki_entries');
    final existingEntries = existingMaps.map((map) => WikiEntry.fromMap(map)).toList();
    return !existingEntries.any((entry) => 
        entry.entryType == WikiEntryType.Place && 
        entry.title.toLowerCase() == locationName.toLowerCase());
  }

  /// Formatiert Belohnungen für Wiki-Anzeige
  String _formatRewardsForWiki(Quest quest) {
    if (!quest.hasRewards) return 'Keine Belohnungen';
    
    final formattedRewards = <String>[];
    for (final reward in quest.rewards) {
      String rewardText = '- ${reward.name}';
      if (reward.quantity != null && reward.quantity! > 1) {
        rewardText += ' (${reward.quantity})';
      }
      formattedRewards.add(rewardText);
    }
    
    return formattedRewards.join('\n');
  }
}
