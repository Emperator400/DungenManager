import 'quest.dart';
import '../utils/model_parsing_helper.dart';

/// CampaignQuest-Model für D&D Kampagnen
/// 
/// Repräsentiert eine Quest, die zu einer bestimmten Kampagne gehört
/// mit kampagnenspezifischen Status und Notizen.
class CampaignQuest {
  final String campaignId;
  final Quest quest;
  final QuestStatus status;
  final String? notes;

  const CampaignQuest({
    required this.campaignId,
    required this.quest,
    required this.status,
    this.notes,
  });

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory CampaignQuest.fromMap(Map<String, dynamic> questMap, Map<String, dynamic> campaignQuestMap) {
    try {
      return CampaignQuest(
        campaignId: ModelParsingHelper.safeString(campaignQuestMap, 'campaignId', ''),
        quest: Quest.fromMap(questMap),
        status: QuestStatus.values.firstWhere(
          (e) => e.toString() == 'QuestStatus.${ModelParsingHelper.safeString(campaignQuestMap, 'status', 'active')}',
          orElse: () => QuestStatus.active,
        ),
        notes: ModelParsingHelper.safeStringOrNull(campaignQuestMap, 'notes', null),
      );
    } catch (e) {
      print('Fehler beim Parsen der CampaignQuest: $e');
      // Fallback zu minimal gültiger CampaignQuest
      return CampaignQuest(
        campaignId: ModelParsingHelper.safeString(campaignQuestMap, 'campaignId', ''),
        quest: Quest.fromMap(questMap),
        status: QuestStatus.active,
      );
    }
  }

  /// CopyWith-Methode für unveränderliche Updates
  CampaignQuest copyWith({
    String? campaignId,
    Quest? quest,
    QuestStatus? status,
    String? notes,
  }) {
    return CampaignQuest(
      campaignId: campaignId ?? this.campaignId,
      quest: quest ?? this.quest,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignQuest && 
           other.campaignId == campaignId && 
           other.quest.id == quest.id;
  }

  @override
  int get hashCode => Object.hash(campaignId, quest.id);

  @override
  String toString() {
    return 'CampaignQuest(campaignId: $campaignId, questId: ${quest.id}, status: $status)';
  }

  // ========== COMPATIBILITY GETTERS ==========
  // für Abwärtskompatibilität mit bestehendem Code

  /// Prüft ob Notizen vorhanden sind
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  /// Prüft ob die Quest aktiv ist
  bool get isActive => status == QuestStatus.active;

  /// Prüft ob die Quest abgeschlossen ist
  bool get isCompleted => status == QuestStatus.completed;

  /// Prüft ob die Quest fehlgeschlagen ist
  bool get isFailed => status == QuestStatus.failed;

  /// Prüft ob die Quest pausiert ist
  bool get isOnHold => status == QuestStatus.onHold;

  /// Prüft ob die Quest aufgegeben wurde
  bool get isAbandoned => status == QuestStatus.abandoned;

  /// Lokalisierte Beschreibung für Status
  String get statusDescription {
    switch (status) {
      case QuestStatus.active:
        return 'Aktiv';
      case QuestStatus.completed:
        return 'Abgeschlossen';
      case QuestStatus.failed:
        return 'Fehlgeschlagen';
      case QuestStatus.abandoned:
        return 'Aufgegeben';
      case QuestStatus.onHold:
        return 'Pausiert';
    }
  }

  // ========== DATABASE COMPATIBILITY METHODS ==========
  // Für die Kompatibilität mit DatabaseHelper

  /// Konvertiert zu einer Map für die Datenbank
  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'questId': quest.id.toString(),
      'status': status.name,
      'notes': notes,
    };
  }

  /// Factory für Datenbank-Map (einfache Version für DatabaseHelper)
  factory CampaignQuest.fromDbMap(Map<String, dynamic> map) {
    // Wir benötigen auch die Quest-Daten, aber diese kommen separat
    // Für die Datenbank-CRUD Operationen verwenden wir eine placeholder Quest
    final questIdValue = map['questId'];
    final int questId;
    if (questIdValue is String) {
      questId = int.tryParse(questIdValue) ?? 0;
    } else if (questIdValue is int) {
      questId = questIdValue;
    } else {
      questId = 0;
    }

    final placeholderQuest = Quest(
      id: questId,
      title: 'Loading...',
      description: 'Loading quest data...',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questType: QuestType.side,
      difficulty: QuestDifficulty.medium,
      tags: const [],
      rewards: const [],
      involvedNpcs: const [],
      linkedWikiEntryIds: const [],
    );

    final campaignIdValue = map['campaignId'];
    final String campaignId;
    if (campaignIdValue is String) {
      campaignId = campaignIdValue;
    } else {
      campaignId = campaignIdValue?.toString() ?? '';
    }

    return CampaignQuest(
      campaignId: campaignId,
      quest: placeholderQuest,
      status: QuestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuestStatus.active,
      ),
      notes: map['notes']?.toString(),
    );
  }

  /// Getter für questId für Kompatibilität
  String get questId => quest.id.toString();
}
