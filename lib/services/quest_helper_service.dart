import '../models/quest.dart';
import '../models/quest_reward.dart' as qr;
import '../theme/dnd_theme.dart';
import 'package:flutter/material.dart';

/// Service für Quest-spezifische Helper-Methoden und Business-Logik
class QuestHelperService {
  /// Prüft ob die Quest ein bestimmtes Tag hat
  static bool hasTag(Quest quest, String tag) {
    return quest.tags.contains(tag);
  }

  /// Fügt einen Tag hinzu (ohne Duplikate)
  static Quest addTag(Quest quest, String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty || quest.tags.contains(trimmedTag)) return quest;
    
    final newTags = List<String>.from(quest.tags)..add(trimmedTag);
    return quest.copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  /// Entfernt einen Tag
  static Quest removeTag(Quest quest, String tag) {
    final newTags = quest.tags.where((t) => t != tag).toList();
    if (newTags.length == quest.tags.length) return quest; // Tag nicht gefunden
    
    return quest.copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  /// Fügt eine detaillierte Belohnung hinzu
  static Quest addReward(Quest quest, qr.QuestReward reward) {
    if (quest.rewards.any((r) => r.id == reward.id)) return quest;
    
    final newRewards = List<qr.QuestReward>.from(quest.rewards)..add(reward);
    return quest.copyWith(
      rewards: newRewards,
      updatedAt: DateTime.now(),
    );
  }

  /// Entfernt eine Belohnung
  static Quest removeReward(Quest quest, String rewardId) {
    final newRewards = quest.rewards.where((r) => r.id != rewardId).toList();
    if (newRewards.length == quest.rewards.length) return quest; // Belohnung nicht gefunden
    
    return quest.copyWith(
      rewards: newRewards,
      updatedAt: DateTime.now(),
    );
  }

  /// Fügt einen Wiki-Eintrag-Link hinzu
  static Quest addWikiEntryLink(Quest quest, String wikiEntryId) {
    final trimmedId = wikiEntryId.trim();
    if (trimmedId.isEmpty || quest.linkedWikiEntryIds.contains(trimmedId)) return quest;
    
    final newLinks = List<String>.from(quest.linkedWikiEntryIds)..add(trimmedId);
    return quest.copyWith(
      linkedWikiEntryIds: newLinks,
      updatedAt: DateTime.now(),
    );
  }

  /// Entfernt einen Wiki-Eintrag-Link
  static Quest removeWikiEntryLink(Quest quest, String wikiEntryId) {
    final newLinks = quest.linkedWikiEntryIds.where((id) => id != wikiEntryId).toList();
    if (newLinks.length == quest.linkedWikiEntryIds.length) return quest; // Link nicht gefunden
    
    return quest.copyWith(
      linkedWikiEntryIds: newLinks,
      updatedAt: DateTime.now(),
    );
  }

  /// Fügt einen NPC hinzu
  static Quest addNpc(Quest quest, String npc) {
    final trimmedNpc = npc.trim();
    if (trimmedNpc.isEmpty || quest.involvedNpcs.contains(trimmedNpc)) return quest;
    
    final newNpcs = List<String>.from(quest.involvedNpcs)..add(trimmedNpc);
    return quest.copyWith(
      involvedNpcs: newNpcs,
      updatedAt: DateTime.now(),
    );
  }

  /// Entfernt einen NPC
  static Quest removeNpc(Quest quest, String npc) {
    final newNpcs = quest.involvedNpcs.where((n) => n != npc).toList();
    if (newNpcs.length == quest.involvedNpcs.length) return quest; // NPC nicht gefunden
    
    return quest.copyWith(
      involvedNpcs: newNpcs,
      updatedAt: DateTime.now(),
    );
  }

  /// Setzt den Favoriten-Status
  static Quest setFavorite(Quest quest, bool favorite) {
    if (quest.isFavorite == favorite) return quest; // Keine Änderung
    
    return quest.copyWith(
      isFavorite: favorite,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle Favoriten-Status
  static Quest toggleFavorite(Quest quest) {
    return setFavorite(quest, !quest.isFavorite);
  }

  /// Prüft ob die Quest für ein bestimmtes Level geeignet ist
  static bool isSuitableForLevel(Quest quest, int partyLevel, {int tolerance = 2}) {
    if (quest.recommendedLevel == null) return true; // Keine Empfehlung = immer geeignet
    
    return (partyLevel >= (quest.recommendedLevel! - tolerance) && 
            partyLevel <= (quest.recommendedLevel! + tolerance));
  }

  /// Gibt eine lesbare Beschreibung der Schwierigkeit zurück
  static String getDifficultyDescription(Quest quest) {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return 'Leicht';
      case QuestDifficulty.medium:
        return 'Mittel';
      case QuestDifficulty.hard:
        return 'Schwer';
      case QuestDifficulty.deadly:
        return 'Tödlich';
      case QuestDifficulty.epic:
        return 'Episch';
      case QuestDifficulty.legendary:
        return 'Legendär';
    }
  }

  /// Gibt eine lesbare Beschreibung des Quest-Typs zurück
  static String getQuestTypeDescription(Quest quest) {
    switch (quest.questType) {
      case QuestType.main:
        return 'Hauptquest';
      case QuestType.side:
        return 'Sidequest';
      case QuestType.personal:
        return 'Persönlich';
      case QuestType.faction:
        return 'Fraktion';
    }
  }

  /// Gibt den Display-Namen für Quest-Typ zurück
  static String getQuestTypeDisplayName(Quest quest) {
    switch (quest.questType) {
      case QuestType.main:
        return 'Hauptquest';
      case QuestType.side:
        return 'Sidequest';
      case QuestType.personal:
        return 'Persönlich';
      case QuestType.faction:
        return 'Fraktion';
    }
  }

  /// Gibt den Display-Namen für Schwierigkeit zurück
  static String getDifficultyDisplayName(Quest quest) {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return 'Leicht';
      case QuestDifficulty.medium:
        return 'Mittel';
      case QuestDifficulty.hard:
        return 'Schwer';
      case QuestDifficulty.deadly:
        return 'Tödlich';
      case QuestDifficulty.epic:
        return 'Episch';
      case QuestDifficulty.legendary:
        return 'Legendär';
    }
  }

  /// Formatiert NPC-Liste als String
  static String getNpcsString(Quest quest) {
    return quest.involvedNpcs.join(', ');
  }

  /// Formatiert Tag-Liste als String
  static String getTagsString(Quest quest) {
    return quest.tags.join(', ');
  }

  /// Filtert Gold-Belohnungen
  static List<qr.QuestReward> getGoldRewards(Quest quest) {
    return quest.rewards.cast<qr.QuestReward>().where((r) => r.type == qr.QuestRewardType.gold).toList();
  }

  /// Filtert Item-Belohnungen
  static List<qr.QuestReward> getItemRewards(Quest quest) {
    return quest.rewards.cast<qr.QuestReward>().where((r) => r.type == qr.QuestRewardType.item).toList();
  }

  /// Filtert XP-Belohnungen
  static List<qr.QuestReward> getXpRewards(Quest quest) {
    return quest.rewards.cast<qr.QuestReward>().where((r) => r.type == qr.QuestRewardType.experience).toList();
  }

  /// Filtert Wiki-Eintrag-Belohnungen
  static List<qr.QuestReward> getWikiEntryRewards(Quest quest) {
    return quest.rewards.cast<qr.QuestReward>().where((r) => r.type == qr.QuestRewardType.wikiEntry).toList();
  }

  /// Berechnet Gesamtgold-Betrag
  static int getTotalGoldAmount(Quest quest) {
    return getGoldRewards(quest).fold(0, (sum, reward) => sum + (reward.goldAmount?.toInt() ?? 0));
  }

  /// Berechnet Gesamt-XP
  static int getTotalXP(Quest quest) {
    return getXpRewards(quest).fold(0, (sum, reward) => sum + (reward.experiencePoints?.toInt() ?? 0));
  }

  /// Erstellt eine neue Quest mit Basis-Daten
  static Quest createQuest({
    required String title,
    String? description,
    QuestType questType = QuestType.side,
    QuestDifficulty difficulty = QuestDifficulty.medium,
    String? location,
    int? recommendedLevel,
    double? estimatedDurationHours,
    String? campaignId,
    List<String> tags = const [],
    List<qr.QuestReward> rewards = const [],
    List<String> involvedNpcs = const [],
    List<String> linkedWikiEntryIds = const [],
    bool isFavorite = false,
  }) {
    return Quest.create(
      title: title,
      description: description ?? '',
      questType: questType,
      difficulty: difficulty,
      location: location,
      recommendedLevel: recommendedLevel,
      estimatedDurationHours: estimatedDurationHours,
      campaignId: campaignId,
      tags: tags,
      rewards: rewards,
      involvedNpcs: involvedNpcs,
      linkedWikiEntryIds: linkedWikiEntryIds,
      isFavorite: isFavorite,
    );
  }

  /// Validiert eine Quest
  static bool isValidQuest(Quest quest) {
    return quest.title.trim().isNotEmpty && 
           quest.title.length >= 3 && 
           quest.title.length <= 100;
  }

  /// Gibt die Farbe für die Schwierigkeit zurück
  static Color getDifficultyColor(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return DnDTheme.successGreen;
      case QuestDifficulty.medium:
        return DnDTheme.ancientGold;
      case QuestDifficulty.hard:
        return DnDTheme.arcaneBlue;
      case QuestDifficulty.deadly:
        return DnDTheme.errorRed;
      case QuestDifficulty.epic:
        return DnDTheme.mysticalPurple;
      case QuestDifficulty.legendary:
        return DnDTheme.mysticalPurple;
    }
  }

  /// Prüft ob die Quest wichtige Metadaten hat
  static bool getHasTags(Quest quest) => quest.tags.isNotEmpty;
  static bool getHasRewards(Quest quest) => quest.rewards.isNotEmpty;
  static bool getHasLocation(Quest quest) => quest.location != null && quest.location!.isNotEmpty;
  static bool getHasNpcs(Quest quest) => quest.involvedNpcs.isNotEmpty;
  static bool getHasLevelRecommendation(Quest quest) => quest.recommendedLevel != null;
  static bool getHasDurationEstimate(Quest quest) => quest.estimatedDurationHours != null;
  static bool getHasWikiLinks(Quest quest) => quest.linkedWikiEntryIds.isNotEmpty;
  static bool getIsCampaignSpecific(Quest quest) => quest.campaignId != null;
}
