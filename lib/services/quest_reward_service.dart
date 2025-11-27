// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/quest.dart';
import '../models/quest_reward.dart';
import '../models/player_character.dart';
import '../models/inventory_item.dart';
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';
import 'exceptions/service_exceptions.dart';

/// Service für die Verwaltung und Verteilung von Quest-Belohnungen
/// Unterstützt verschiedene Belohnungsarten und die automatische Verteilung an Spieler
class QuestRewardService {
  // Constructor-Abschnitt - Muss zuerst stehen (sort_constructors_first)
  final DatabaseHelper _dbHelper;

  QuestRewardService({
    DatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Verteilt alle Belohnungen einer Quest an einen bestimmten Spieler
  Future<Map<String, dynamic>> distributeRewardsToPlayer(String questId, String playerId) async {
    try {
      // Hole Quest und Spieler
      final allQuests = await _dbHelper.getAllQuests();
      final quest = allQuests.cast<Quest?>().firstWhere(
        (q) => q?.id == questId,
        orElse: () => null,
      );
      
      final allPlayers = await _dbHelper.getPlayerCharactersForCampaign(playerId);
      final player = allPlayers.cast<PlayerCharacter?>().firstWhere(
        (p) => p?.id == playerId,
        orElse: () => null,
      );
      
      if (quest == null) {
        throw ResourceNotFoundException.forId(
          'Quest',
          questId,
          operation: 'distributeRewardsToPlayer',
        );
      }
      if (player == null) {
        throw ResourceNotFoundException.forId(
          'PlayerCharacter',
          playerId,
          operation: 'distributeRewardsToPlayer',
        );
      }

      final distributionResult = <String, dynamic>{
        'questId': questId,
        'playerId': playerId,
        'questTitle': quest.title,
        'distributedRewards': <Map<String, dynamic>>[],
        'errors': <String>[],
        'timestamp': DateTime.now().toIso8601String(),
      };

      for (final reward in quest.rewards) {
        try {
          final result = await _distributeSingleReward(reward, player, quest);
          distributionResult['distributedRewards'].add(result);
        } catch (e) {
          distributionResult['errors'].add('Fehler bei "${reward.name}": $e');
        }
      }

      // Gold dem Spieler hinzufügen
      final totalGold = quest.totalGoldAmount;
      if (totalGold > 0) {
        await _addGoldToPlayer(player, totalGold);
        distributionResult['distributedRewards'].add({
          'type': 'gold',
          'amount': totalGold,
          'description': '$totalGold Goldstücke',
          'success': true,
        });
      }

      // Erfahrungspunkte dem Spieler hinzufügen
      final totalXP = quest.totalXP;
      if (totalXP > 0) {
        await _addXPToPlayer(player, totalXP);
        distributionResult['distributedRewards'].add({
          'type': 'experience',
          'amount': totalXP,
          'description': '$totalXP Erfahrungspunkte',
          'success': true,
        });
      }

      return distributionResult;
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw BusinessException(
        'Fehler bei der Belohnungsverteilung: $e',
        operation: 'distributeRewardsToPlayer',
        originalError: e,
      );
    }
  }

  /// Verteilt eine einzelne Belohnung an einen Spieler
  Future<Map<String, dynamic>> _distributeSingleReward(QuestReward reward, PlayerCharacter player, Quest quest) async {
    switch (reward.type) {
      case QuestRewardType.item:
        return await _distributeItemReward(reward, player);
      case QuestRewardType.gold:
        return {
          'type': 'gold',
          'rewardId': reward.id,
          'name': reward.name,
          'amount': reward.goldAmount ?? 0,
          'description': '${reward.goldAmount ?? 0} Goldstücke',
          'success': true,
        };
      case QuestRewardType.experience:
        return {
          'type': 'experience',
          'rewardId': reward.id,
          'name': reward.name,
          'amount': reward.experiencePoints ?? 0,
          'description': '${reward.experiencePoints ?? 0} Erfahrungspunkte',
          'success': true,
        };
      case QuestRewardType.wikiEntry:
        return await _distributeWikiEntryReward(reward, player, quest);
      case QuestRewardType.custom:
        return {
          'type': 'custom',
          'rewardId': reward.id,
          'name': reward.name,
          'description': reward.description ?? reward.name,
          'quantity': reward.quantity ?? 1,
          'success': true,
        };
    }
  }

  /// Verteilt eine Item-Belohnung an einen Spieler
  Future<Map<String, dynamic>> _distributeItemReward(QuestReward reward, PlayerCharacter player) async {
    if (reward.itemId == null) {
      throw Exception('Item-Belohnung hat keine gültige Item-ID');
    }

    final item = await _dbHelper.getItemById(reward.itemId!);
    if (item == null) {
      throw Exception('Item nicht gefunden: ${reward.itemId}');
    }

    // InventoryItem erstellen und zum Spieler-Inventar hinzufügen
    final inventoryItem = InventoryItem(
      id: '', // Wird von Datenbank generiert
      ownerId: player.id,
      itemId: item.id,
      quantity: reward.quantity ?? 1,
      isEquipped: false,
    );

    await _dbHelper.insertInventoryItem(inventoryItem);

    return {
      'type': 'item',
      'rewardId': reward.id,
      'itemId': item.id,
      'itemName': item.name,
      'quantity': reward.quantity ?? 1,
      'description': '${reward.quantity ?? 1}x ${item.name}',
      'success': true,
    };
  }

  /// Verteilt eine Wiki-Eintrag-Belohnung an einen Spieler
  Future<Map<String, dynamic>> _distributeWikiEntryReward(QuestReward reward, PlayerCharacter player, Quest quest) async {
    if (reward.wikiEntryId == null) {
      throw Exception('Wiki-Eintrag-Belohnung hat keine gültige Wiki-Eintrag-ID');
    }

    final allWikiEntries = await _dbHelper.getAllWikiEntries();
    final wikiEntry = allWikiEntries.cast<WikiEntry?>().firstWhere(
      (entry) => entry?.id == reward.wikiEntryId,
      orElse: () => null,
    );
    if (wikiEntry == null) {
      throw Exception('Wiki-Eintrag nicht gefunden: ${reward.wikiEntryId}');
    }

    // Wiki-Einträge können "belohnt" werden, indem sie dem Spieler zugänglich gemacht werden
    // Dies könnte durch eine spezielle "Wissen"-Eigenschaft des Spielers implementiert werden
    // Für jetzt erstellen wir eine Verknüpfung zwischen Spieler und Wiki-Eintrag
    
    // In einer erweiterten Implementierung könnte man hier eine PlayerWikiEntry-Tabelle haben
    return {
      'type': 'wikiEntry',
      'rewardId': reward.id,
      'wikiEntryId': wikiEntry.id,
      'wikiEntryTitle': wikiEntry.title,
      'description': 'Zugriff auf Wiki-Eintrag: ${wikiEntry.title}',
      'success': true,
    };
  }

  /// Fügt Gold zum Spieler hinzu
  Future<void> _addGoldToPlayer(PlayerCharacter player, int amount) async {
    // Annahme: PlayerCharacter hat eine gold-Eigenschaft oder Money-System
    // Dies müsste im PlayerCharacter-Modell implementiert werden
    // Für jetzt zeigen wir die Logik
    
    // In einer echten Implementierung:
    // final updatedPlayer = player.copyWith(gold: player.gold + amount);
    // await _dbHelper.updatePlayerCharacter(updatedPlayer);
    
    print('Spieler ${player.name} erhält $amount Gold');
  }

  /// Fügt Erfahrungspunkte zum Spieler hinzu
  Future<void> _addXPToPlayer(PlayerCharacter player, int amount) async {
    // Annahme: PlayerCharacter hat Erfahrungspunkte-System
    // Dies müsste im PlayerCharacter-Modell implementiert werden
    
    // In einer echten Implementierung:
    // final updatedPlayer = player.addExperience(amount);
    // await _dbHelper.updatePlayerCharacter(updatedPlayer);
    
    print('Spieler ${player.name} erhält $amount Erfahrungspunkte');
  }

  /// Berechnet die Gesamtwerte aller Belohnungen einer Quest
  Map<String, dynamic> calculateRewardSummary(Quest quest) {
    final summary = <String, dynamic>{
      'totalItems': 0,
      'totalGold': quest.totalGoldAmount,
      'totalXP': quest.totalXP,
      'uniqueItemTypes': <String>{},
      'rewardCount': quest.rewards.length,
    };

    for (final reward in quest.rewards) {
      switch (reward.type) {
        case QuestRewardType.item:
          summary['totalItems'] += reward.quantity ?? 1;
          if (reward.itemId != null) {
            summary['uniqueItemTypes'].add(reward.itemId!);
          }
          break;
        case QuestRewardType.gold:
          // Wird bereits in totalGold berücksichtigt
          break;
        case QuestRewardType.experience:
          // Wird bereits in totalXP berücksichtigt
          break;
        case QuestRewardType.wikiEntry:
          summary['totalWikiEntries'] = (summary['totalWikiEntries'] ?? 0) + 1;
          break;
        case QuestRewardType.custom:
          summary['totalCustom'] = (summary['totalCustom'] ?? 0) + 1;
          break;
      }
    }

    return summary;
  }

  /// Prüft ob alle Belohnungen einer Quest verteilt werden können
  Future<Map<String, dynamic>> validateRewards(String questId) async {
    final allQuests = await _dbHelper.getAllQuests();
    final quest = allQuests.cast<Quest?>().firstWhere(
      (q) => q?.id == questId,
      orElse: () => null,
    );
    if (quest == null) {
      return {
        'valid': false,
        'error': 'Quest nicht gefunden',
        'issues': <String>[],
      };
    }

    final issues = <String>[];
    
    for (final reward in quest.rewards) {
      switch (reward.type) {
        case QuestRewardType.item:
          if (reward.itemId == null) {
            issues.add('Item-Belohnung "${reward.name}" hat keine Item-ID');
          } else {
            final item = await _dbHelper.getItemById(reward.itemId!);
            if (item == null) {
              issues.add('Item für Belohnung "${reward.name}" nicht gefunden: ${reward.itemId}');
            }
          }
          break;
        case QuestRewardType.wikiEntry:
          if (reward.wikiEntryId == null) {
            issues.add('Wiki-Eintrag-Belohnung "${reward.name}" hat keine Wiki-Eintrag-ID');
          } else {
            final allWikiEntries = await _dbHelper.getAllWikiEntries();
            final wikiEntry = allWikiEntries.cast<WikiEntry?>().firstWhere(
              (entry) => entry?.id == reward.wikiEntryId,
              orElse: () => null,
            );
            if (wikiEntry == null) {
              issues.add('Wiki-Eintrag für Belohnung "${reward.name}" nicht gefunden: ${reward.wikiEntryId}');
            }
          }
          break;
        case QuestRewardType.gold:
          if (reward.goldAmount == null || reward.goldAmount! <= 0) {
            issues.add('Gold-Belohnung "${reward.name}" hat keinen gültigen Betrag');
          }
          break;
        case QuestRewardType.experience:
          if (reward.experiencePoints == null || reward.experiencePoints! <= 0) {
            issues.add('Erfahrungs-Belohnung "${reward.name}" hat keinen gültigen Betrag');
          }
          break;
        case QuestRewardType.custom:
          // Custom-Belohnungen sind immer gültig
          break;
      }
    }

    return {
      'valid': issues.isEmpty,
      'questId': questId,
      'questTitle': quest.title,
      'issues': issues,
      'totalRewards': quest.rewards.length,
    };
  }

  /// Gibt eine Vorschau aller Belohnungen zurück
  Future<List<Map<String, dynamic>>> getRewardPreview(String questId) async {
    final allQuests = await _dbHelper.getAllQuests();
    final quest = allQuests.cast<Quest?>().firstWhere(
      (q) => q?.id == questId,
      orElse: () => null,
    );
    if (quest == null) return [];

    final preview = <Map<String, dynamic>>[];
    
    for (final reward in quest.rewards) {
      final rewardPreview = <String, dynamic>{
        'id': reward.id,
        'type': reward.type.toString(),
        'name': reward.name,
        'description': reward.description,
        'quantity': reward.quantity,
      };

      switch (reward.type) {
        case QuestRewardType.item:
          if (reward.itemId != null) {
            final item = await _dbHelper.getItemById(reward.itemId!);
            rewardPreview['item'] = item?.toMap();
          }
          break;
        case QuestRewardType.wikiEntry:
          if (reward.wikiEntryId != null) {
            final allWikiEntries = await _dbHelper.getAllWikiEntries();
            final wikiEntry = allWikiEntries.cast<WikiEntry?>().firstWhere(
              (entry) => entry?.id == reward.wikiEntryId,
              orElse: () => null,
            );
            rewardPreview['wikiEntry'] = wikiEntry?.toMap();
          }
          break;
        case QuestRewardType.gold:
          rewardPreview['amount'] = reward.goldAmount;
          break;
        case QuestRewardType.experience:
          rewardPreview['amount'] = reward.experiencePoints;
          break;
        case QuestRewardType.custom:
          rewardPreview['isCustom'] = true;
          break;
      }

      preview.add(rewardPreview);
    }

    return preview;
  }

  /// Gibt Statistiken über Belohnungsverteilungen zurück
  Future<Map<String, dynamic>> getRewardStatistics() async {
    // In einer vollständigen Implementierung würde man hier
    // eine Tabelle für Belohnungsverteilungen haben
    // Für jetzt geben wir Platzhalter-Daten zurück
    
    return {
      'totalDistributedRewards': 0,
      'totalGoldDistributed': 0,
      'totalXPDistributed': 0,
      'totalItemsDistributed': 0,
      'mostCommonRewards': <String>[],
      'recentDistributions': <Map<String, dynamic>>[],
    };
  }

  /// Storniert eine Belohnungsverteilung (falls etwas schiefgelaufen ist)
  Future<bool> rollbackRewardDistribution(String questId, String playerId) async {
    // In einer vollständigen Implementierung würde man hier
    // die Belohnungsverteilung rückgängig machen
    // Dies wäre komplex, da es den Spieler-Zustand wiederherstellen müsste
    
    print('Rollback der Belohnungsverteilung für Quest $questId und Spieler $playerId');
    return true; // Platzhalter
  }
}
