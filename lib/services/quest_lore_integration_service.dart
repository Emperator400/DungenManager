import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/models/wiki_entry.dart';
import 'package:dungen_manager/services/quest_library_service.dart';
import 'package:dungen_manager/services/wiki_link_service.dart';

/// Service to handle interactions between Quests and Wiki Entries (Lore).
class QuestLoreIntegrationService {
  final QuestLibraryService _questService;
  final WikiLinkService _wikiLinkService;

  /// Private constructor for dependency injection
  QuestLoreIntegrationService._({
    required QuestLibraryService questService,
    required WikiLinkService wikiLinkService,
  })  : _questService = questService,
        _wikiLinkService = wikiLinkService;

  /// Factory constructor to create a new instance with dependency injection
  factory QuestLoreIntegrationService({
    required QuestLibraryService questService,
    required WikiLinkService wikiLinkService,
  }) {
    return QuestLoreIntegrationService._(
      questService: questService,
      wikiLinkService: wikiLinkService,
    );
  }

  /// Creates a new Quest from a Wiki Entry
  /// Copies the title and content from the wiki entry to create a quest
  Future<Quest> createQuestFromWikiEntry(WikiEntry entry) async {
    final quest = Quest.create(
      title: entry.title,
      description: entry.content,
      status: QuestStatus.active,
      questType: QuestType.side,
      difficulty: QuestDifficulty.medium,
      linkedWikiEntryIds: [entry.id],
    );
    
    // In a real implementation, this would save the quest:
    // final result = await _questService.createQuest(quest);
    // if (result.isSuccess) {
    //   return result.data;
    // } else {
    //   throw Exception('Failed to create quest: ${result.errorMessage}');
    // }
    
    return quest;
  }

  /// Links a quest to a wiki entry by creating a wiki link
  Future<void> linkQuestToWikiEntry(String questId, String wikiEntryId) async {
    // In a real implementation, this would create link:
    // final result = await _wikiLinkService.createLink(questId, wikiEntryId);
    // if (!result.isSuccess) {
    //   throw Exception('Failed to create link: ${result.errorMessage}');
    // }
    
    throw UnimplementedError('linkQuestToWikiEntry implementation pending - requires WikiLinkService integration');
  }

  /// Unlinks a quest from a wiki entry by removing the wiki link
  Future<void> unlinkQuestFromWikiEntry(String questId, String wikiEntryId) async {
    // In a real implementation, this would delete the link:
    // final result = await _wikiLinkService.deleteLink(questId, wikiEntryId);
    // if (!result.isSuccess) {
    //   throw Exception('Failed to delete link: ${result.errorMessage}');
    // }
    
    throw UnimplementedError('unlinkQuestFromWikiEntry implementation pending - requires WikiLinkService integration');
  }
}
