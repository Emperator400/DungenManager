import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/edit_quest_viewmodel.dart';
import '../../models/quest.dart';
import '../../models/quest_reward.dart';
import '../../theme/dnd_theme.dart';

/// Enhanced Quest Edit Screen mit Provider-Pattern und modernem D&D Design
class EditQuestScreen extends StatefulWidget {
  final Quest? quest;

  const EditQuestScreen({
    super.key,
    this.quest,
  });

  @override
  State<EditQuestScreen> createState() => _EditQuestScreenState();
}

/// Widget das den EditQuestViewModel bereitstellt
class _EditQuestScreenWithProvider extends StatelessWidget {
  final Quest? quest;
  final String? campaignId;

  const _EditQuestScreenWithProvider({
    super.key,
    this.quest,
    this.campaignId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditQuestViewModel>(
      create: (_) => EditQuestViewModel(),
      child: Builder(
        builder: (context) {
          // Initialisiere den ViewModel nach der Erstellung
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<EditQuestViewModel>().initialize(quest, campaignId: campaignId);
          });
          
          return EditQuestScreen(quest: quest);
        },
      ),
    );
  }
}

class _EditQuestScreenState extends State<EditQuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _recommendedLevelController = TextEditingController();
  final _estimatedDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditQuestViewModel>().initialize(widget.quest);
      _populateFields();
    });
  }

  void _populateFields() {
    final viewModel = context.read<EditQuestViewModel>();
    final quest = viewModel.quest;
    
    if (quest != null) {
      _titleController.text = quest!.title;
      _descriptionController.text = quest!.description;
      _locationController.text = quest!.location ?? '';
      _recommendedLevelController.text = quest!.recommendedLevel?.toString() ?? '';
      _estimatedDurationController.text = quest!.estimatedDurationHours?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _recommendedLevelController.dispose();
    _estimatedDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(),
        ),
        child: SafeArea(
          child: Consumer<EditQuestViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  _buildHeader(context, viewModel),
                  Expanded(
                    child: _buildForm(context, viewModel),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EditQuestViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.mysticalPurple.withOpacity(0.9),
            DnDTheme.arcaneBlue.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleBackNavigation(viewModel),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              viewModel.quest != null ? 'Quest bearbeiten' : 'Neuer Quest',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (viewModel.hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Nicht gespeichert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, EditQuestViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(context, viewModel),
            const SizedBox(height: 24),
            _buildQuestDetailsSection(context, viewModel),
            const SizedBox(height: 24),
            _buildRewardsSection(context, viewModel),
            const SizedBox(height: 32),
            _buildActionButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, EditQuestViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DnDTheme.ancientGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grundlegende Informationen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Quest Titel *',
              hintText: 'z.B. Die Rettung vom Drachenhort',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Titel ist erforderlich';
              }
              if (value.trim().length < 2) {
                return 'Titel muss mindestens 2 Zeichen lang sein';
              }
              return null;
            },
            onChanged: (value) => viewModel.updateTitle(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Beschreibung *',
              hintText: 'Beschreibe den Quest und seine Ziele...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Beschreibung ist erforderlich';
              }
              return null;
            },
            onChanged: (value) => viewModel.updateDescription(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Ort',
              hintText: 'Wo findet der Quest statt?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
            onChanged: (value) => viewModel.updateLocation(value),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestDetailsSection(BuildContext context, EditQuestViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DnDTheme.ancientGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quest-Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<QuestStatus>(
                  value: viewModel.quest?.status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  items: QuestStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getQuestStatusDisplayName(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.updateStatus(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<QuestType>(
                  value: viewModel.quest?.questType,
                  decoration: InputDecoration(
                    labelText: 'Typ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  items: QuestType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getQuestTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.updateQuestType(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<QuestDifficulty>(
                  value: viewModel.quest?.difficulty,
                  decoration: InputDecoration(
                    labelText: 'Schwierigkeit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  items: QuestDifficulty.values.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(_getQuestDifficultyDisplayName(difficulty)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.updateDifficulty(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _recommendedLevelController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Empfohlenes Level',
                    hintText: '1-20',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  onChanged: (value) {
                    final level = int.tryParse(value);
                    if (level != null) {
                      viewModel.updateRecommendedLevel(level);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _estimatedDurationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Geschätzte Dauer (Stunden)',
              hintText: 'z.B. 2.5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
            onChanged: (value) {
              final duration = double.tryParse(value);
              if (duration != null) {
                viewModel.updateEstimatedDuration(duration);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context, EditQuestViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DnDTheme.ancientGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Belohnungen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddRewardDialog(viewModel),
                icon: const Icon(Icons.add),
                label: const Text('Belohnung hinzufügen'),
                style: TextButton.styleFrom(
                  foregroundColor: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.quest?.rewards.isEmpty == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Text(
                'Noch keine Belohnungen hinzugefügt',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: viewModel.quest!.rewards.map((reward) {
                return _buildRewardCard(viewModel, reward);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(EditQuestViewModel viewModel, QuestReward reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DnDTheme.ancientGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (reward.goldAmount != null && reward.goldAmount! > 0)
                  Text(
                    '${reward.goldAmount} Gold',
                    style: TextStyle(
                      color: DnDTheme.ancientGold,
                      fontSize: 12,
                    ),
                  ),
                if (reward.experiencePoints != null && reward.experiencePoints! > 0)
                  Text(
                    '${reward.experiencePoints} EP',
                    style: TextStyle(
                      color: DnDTheme.arcaneBlue,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDeleteRewardDialog(viewModel, reward),
            icon: Icon(
              Icons.delete_outline,
              color: DnDTheme.errorRed,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EditQuestViewModel viewModel) {
    return Column(
      children: [
        if (viewModel.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: DnDTheme.errorRed.withOpacity(0.1),
              border: Border.all(color: DnDTheme.errorRed),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(
                color: DnDTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: viewModel.isLoading ? null : () => _handleSave(viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SPEICHERN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.isLoading ? null : () => _handleCancel(viewModel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ABBRECHEN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (viewModel.quest != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: viewModel.isLoading ? null : () => _handleDuplicate(viewModel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DnDTheme.arcaneBlue,
                    side: BorderSide(color: DnDTheme.arcaneBlue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'DUPLIZIEREN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: viewModel.isLoading ? null : () => _handleDelete(viewModel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DnDTheme.errorRed,
                    side: BorderSide(color: DnDTheme.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'LÖSCHEN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getQuestStatusDisplayName(QuestStatus status) {
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

  String _getQuestTypeDisplayName(QuestType type) {
    switch (type) {
      case QuestType.main:
        return 'Hauptquest';
      case QuestType.side:
        return 'Nebenquest';
      case QuestType.personal:
        return 'Persönlich';
      case QuestType.faction:
        return 'Fraktions-Quest';
    }
  }

  String _getQuestDifficultyDisplayName(QuestDifficulty difficulty) {
    switch (difficulty) {
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

  void _showAddRewardDialog(EditQuestViewModel viewModel) {
    final descriptionController = TextEditingController();
    final goldController = TextEditingController();
    final xpController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belohnung hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'z.B. Magisches Schwert',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goldController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gold (optional)',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: xpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Erfahrungspunkte (optional)',
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ABBRECHEN'),
          ),
          ElevatedButton(
            onPressed: () {
              final gold = int.tryParse(goldController.text) ?? 0;
              final xp = int.tryParse(xpController.text) ?? 0;
              
              if (descriptionController.text.trim().isNotEmpty || gold > 0 || xp > 0) {
                final reward = QuestReward(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: gold > 0 ? QuestRewardType.gold : QuestRewardType.experience,
                  name: descriptionController.text.trim().isNotEmpty 
                      ? descriptionController.text 
                      : (gold > 0 ? 'Gold Belohnung' : 'EP Belohnung'),
                  description: descriptionController.text.trim().isNotEmpty 
                      ? descriptionController.text 
                      : null,
                  goldAmount: gold > 0 ? gold : null,
                  experiencePoints: xp > 0 ? xp : null,
                );
                viewModel.addReward(reward);
                Navigator.of(context).pop();
              }
            },
            child: const Text('HINZUFÜGEN'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRewardDialog(EditQuestViewModel viewModel, QuestReward reward) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belohnung löschen'),
        content: Text('Möchten Sie diese Belohnung wirklich löschen?\n\n${reward.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeReward(reward);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: DnDTheme.errorRed),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }

  void _handleSave(EditQuestViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await viewModel.saveQuest();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _handleCancel(EditQuestViewModel viewModel) {
    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(viewModel);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleDelete(EditQuestViewModel viewModel) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true) {
      final success = await viewModel.deleteQuest();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _handleDuplicate(EditQuestViewModel viewModel) {
    viewModel.duplicateQuest();
    _populateFields(); // Populate fields with duplicated quest
  }

  void _handleBackNavigation(EditQuestViewModel viewModel) {
    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(viewModel);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog(EditQuestViewModel viewModel) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich gehen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('VERLASSEN'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: const Text(
          'Möchten Sie diesen Quest wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: DnDTheme.errorRed),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }
}