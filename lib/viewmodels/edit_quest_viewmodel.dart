import 'package:flutter/foundation.dart';
import '../models/quest.dart';
import '../models/quest_reward.dart';
import '../services/uuid_service.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für das Editieren von Quests mit neuer Repository-Architektur
/// 
/// HINWEIS: Verwendet jetzt das neue QuestModelRepository
class EditQuestViewModel extends ChangeNotifier {
  final UuidService _uuidService = UuidService();
  final QuestModelRepository _questRepository;

  /// 
  /// HINWEIS: Verwendet jetzt das neue QuestModelRepository
  /// 
  EditQuestViewModel({QuestModelRepository? questRepository})
      : _questRepository = questRepository ?? QuestModelRepository(DatabaseConnection.instance);
  
  // State variables
  Quest? _quest;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getters
  Quest? get quest => _quest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isValid => _quest?.title.trim().isNotEmpty == true && _quest!.title.trim().length >= 2;

  /// Initialisiert das ViewModel mit einem existierenden Quest oder erstellt einen neuen
  void initialize(Quest? quest) {
    _quest = quest ?? Quest.create(
      title: '',
      description: '',
    );
    _hasUnsavedChanges = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Aktualisiert den Titel des Quests
  void updateTitle(String title) {
    if (_quest != null && _quest!.title != title) {
      _quest = _quest!.copyWith(title: title, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die Beschreibung des Quests
  void updateDescription(String description) {
    if (_quest != null && _quest!.description != description) {
      _quest = _quest!.copyWith(description: description, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert den Status des Quests
  void updateStatus(QuestStatus status) {
    if (_quest != null && _quest!.status != status) {
      _quest = _quest!.copyWith(status: status, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die Schwierigkeit des Quests
  void updateDifficulty(QuestDifficulty difficulty) {
    if (_quest != null && _quest!.difficulty != difficulty) {
      _quest = _quest!.copyWith(difficulty: difficulty, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert den Quest-Typ
  void updateQuestType(QuestType questType) {
    if (_quest != null && _quest!.questType != questType) {
      _quest = _quest!.copyWith(questType: questType, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die Location des Quests
  void updateLocation(String location) {
    if (_quest != null && _quest!.location != location) {
      _quest = _quest!.copyWith(location: location, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert das empfohlene Level
  void updateRecommendedLevel(int level) {
    if (_quest != null && _quest!.recommendedLevel != level) {
      _quest = _quest!.copyWith(recommendedLevel: level, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die geschätzte Dauer
  void updateEstimatedDuration(double hours) {
    if (_quest != null && _quest!.estimatedDurationHours != hours) {
      _quest = _quest!.copyWith(estimatedDurationHours: hours, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert den Favoriten-Status
  void updateFavorite(bool isFavorite) {
    if (_quest != null && _quest!.isFavorite != isFavorite) {
      _quest = _quest!.copyWith(isFavorite: isFavorite, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die Tags
  void updateTags(List<String> tags) {
    if (_quest != null && _quest!.tags != tags) {
      _quest = _quest!.copyWith(tags: tags, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die beteiligten NPCs
  void updateInvolvedNpcs(List<String> npcs) {
    if (_quest != null && _quest!.involvedNpcs != npcs) {
      _quest = _quest!.copyWith(involvedNpcs: npcs, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert die verlinkten Wiki-Einträge
  void updateLinkedWikiEntries(List<String> wikiEntryIds) {
    if (_quest != null && _quest!.linkedWikiEntryIds != wikiEntryIds) {
      _quest = _quest!.copyWith(linkedWikiEntryIds: wikiEntryIds, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Fügt eine Belohnung hinzu
  void addReward(QuestReward reward) {
    if (_quest != null) {
      final currentRewards = List<QuestReward>.from(_quest!.rewards);
      currentRewards.add(reward);
      _quest = _quest!.copyWith(rewards: currentRewards, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Entfernt eine Belohnung
  void removeReward(QuestReward reward) {
    if (_quest != null) {
      final currentRewards = List<QuestReward>.from(_quest!.rewards);
      currentRewards.remove(reward);
      _quest = _quest!.copyWith(rewards: currentRewards, updatedAt: DateTime.now());
      _markAsChanged();
    }
  }

  /// Aktualisiert eine bestehende Belohnung
  void updateReward(QuestReward oldReward, QuestReward newReward) {
    if (_quest != null) {
      final currentRewards = List<QuestReward>.from(_quest!.rewards);
      final index = currentRewards.indexOf(oldReward);
      if (index != -1) {
        currentRewards[index] = newReward;
        _quest = _quest!.copyWith(rewards: currentRewards, updatedAt: DateTime.now());
        _markAsChanged();
      }
    }
  }

  /// Speichert den Quest über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue QuestModelRepository
  Future<bool> saveQuest() async {
    if (!isValid) {
      _errorMessage = 'Bitte füllen Sie alle Pflichtfelder aus';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      if (_quest!.id.toString().startsWith('new_')) {
        // Create new quest
        final savedQuest = await _questRepository.create(_quest!);
        if (savedQuest != null) {
          _quest = savedQuest;
        }
      } else {
        // Update existing quest
        final updatedQuest = await _questRepository.update(_quest!);
        if (updatedQuest != null) {
          _quest = updatedQuest;
        }
      }
      
      _hasUnsavedChanges = false;
      _setLoading(false);
      
      return true;
    } catch (e) {
      _errorMessage = 'Fehler beim Speichern: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Löscht den Quest über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue QuestModelRepository
  Future<bool> deleteQuest() async {
    if (_quest?.id.toString().startsWith('new_') == true) {
      _errorMessage = 'Quest kann nicht gelöscht werden: Nicht gespeichert';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _questRepository.delete(_quest!.id.toString());
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Fehler beim Löschen: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Setzt die Formular-Daten zurück
  void resetForm() {
    _quest = Quest.create(
      title: '',
      description: '',
    );
    _hasUnsavedChanges = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setzt das Formular auf die ursprünglichen Werte zurück
  void undoChanges() {
    initialize(null); // Reset to original or new quest
  }

  /// Dupliziert den aktuellen Quest
  void duplicateQuest() {
    if (_quest != null) {
      final now = DateTime.now();
      final duplicatedQuest = Quest(
        id: _uuidService.generateId().hashCode.abs(),
        title: '${_quest!.title} (Kopie)',
        description: _quest!.description,
        status: QuestStatus.active,
        questType: _quest!.questType,
        difficulty: _quest!.difficulty,
        createdAt: now,
        updatedAt: now,
        location: _quest!.location,
        recommendedLevel: _quest!.recommendedLevel,
        estimatedDurationHours: _quest!.estimatedDurationHours,
        isFavorite: false,
        tags: List<String>.from(_quest!.tags),
        rewards: List<QuestReward>.from(_quest!.rewards),
        involvedNpcs: List<String>.from(_quest!.involvedNpcs),
        linkedWikiEntryIds: List<String>.from(_quest!.linkedWikiEntryIds),
      );
      _quest = duplicatedQuest;
      _markAsChanged();
    }
  }

  /// Markiert den Quest als geändert
  void _markAsChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Setzt den Ladezustand
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Löscht die Fehlermeldung
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
