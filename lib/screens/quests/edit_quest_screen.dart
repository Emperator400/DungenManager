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

class _EditQuestScreenState extends State<EditQuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _recommendedLevelController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _recommendedLevelFocusNode = FocusNode();
  final _estimatedDurationFocusNode = FocusNode();

  EditQuestViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = context.read<EditQuestViewModel>();
      _viewModel!.initialize(widget.quest);
      _populateFields();
      
      // Listener hinzufügen, um auf Änderungen am ViewModel zu reagieren
      _viewModel!.addListener(_onViewModelChanged);
    });
  }

  void _onViewModelChanged() {
    // Aktualisiere die Controller nur wenn sich der Quest tatsächlich geändert hat
    // und der Controller gerade nicht fokussiert ist (um Probleme beim Tippen zu vermeiden)
    final quest = _viewModel?.quest;
    if (quest != null && mounted) {
      // Nur aktualisieren, wenn der Controller nicht den Fokus hat
      if (!_titleFocusNode.hasFocus && _titleController.text != quest.title) {
        _titleController.text = quest.title;
      }
      if (!_descriptionFocusNode.hasFocus && _descriptionController.text != quest.description) {
        _descriptionController.text = quest.description;
      }
      if (!_locationFocusNode.hasFocus && _locationController.text != (quest.location ?? '')) {
        _locationController.text = quest.location ?? '';
      }
      if (!_recommendedLevelFocusNode.hasFocus && 
          _recommendedLevelController.text != (quest.recommendedLevel?.toString() ?? '')) {
        _recommendedLevelController.text = quest.recommendedLevel?.toString() ?? '';
      }
      if (!_estimatedDurationFocusNode.hasFocus && 
          _estimatedDurationController.text != (quest.estimatedDurationHours?.toString() ?? '')) {
        _estimatedDurationController.text = quest.estimatedDurationHours?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _recommendedLevelController.dispose();
    _estimatedDurationController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _locationFocusNode.dispose();
    _recommendedLevelFocusNode.dispose();
    _estimatedDurationFocusNode.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DnDTheme.dungeonBlack.withOpacity(0.95),
              DnDTheme.dungeonBlack.withOpacity(0.85),
            ],
          ),
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
            DnDTheme.dungeonBlack.withOpacity(0.95),
            DnDTheme.dungeonBlack.withOpacity(0.85),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: DnDTheme.ancientGold.withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _handleBackNavigation(viewModel),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.quest != null ? 'Quest bearbeiten' : 'Neuer Quest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.quest != null ? 'Details ändern' : 'Erstelle eine neue Quest',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (viewModel.hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: Colors.black87, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Bearbeitet',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            const SizedBox(height: 20),
            _buildQuestDetailsSection(context, viewModel),
            const SizedBox(height: 20),
            _buildRewardsSection(context, viewModel),
            const SizedBox(height: 32),
            _buildActionButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DnDTheme.arcaneBlue, DnDTheme.mysticalPurple],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: DnDTheme.headline2.copyWith(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, EditQuestViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.dungeonBlack.withOpacity(0.85),
            DnDTheme.dungeonBlack.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DnDTheme.arcaneBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.arcaneBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'Grundlegende Informationen'),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            label: 'Quest Titel *',
            hint: 'z.B. Die Rettung vom Drachenhort',
            icon: Icons.title,
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
          _buildTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            label: 'Beschreibung *',
            hint: 'Beschreibe den Quest und seine Ziele...',
            icon: Icons.description,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Beschreibung ist erforderlich';
              }
              return null;
            },
            onChanged: (value) => viewModel.updateDescription(value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _locationController,
            focusNode: _locationFocusNode,
            label: 'Ort',
            hint: 'Wo findet der Quest statt?',
            icon: Icons.place,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.dungeonBlack.withOpacity(0.85),
            DnDTheme.dungeonBlack.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DnDTheme.arcaneBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.arcaneBlue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.tune, 'Quest-Details'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<QuestStatus>(
                  value: viewModel.quest?.status,
                  label: 'Status',
                  icon: Icons.track_changes,
                  items: QuestStatus.values,
                  displayName: _getQuestStatusDisplayName,
                  onChanged: (value) {
                    if (value != null) viewModel.updateStatus(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField<QuestType>(
                  value: viewModel.quest?.questType,
                  label: 'Typ',
                  icon: Icons.category,
                  items: QuestType.values,
                  displayName: _getQuestTypeDisplayName,
                  onChanged: (value) {
                    if (value != null) viewModel.updateQuestType(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<QuestDifficulty>(
                  value: viewModel.quest?.difficulty,
                  label: 'Schwierigkeit',
                  icon: Icons.bar_chart,
                  items: QuestDifficulty.values,
                  displayName: _getQuestDifficultyDisplayName,
                  onChanged: (value) {
                    if (value != null) viewModel.updateDifficulty(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _recommendedLevelController,
                  focusNode: _recommendedLevelFocusNode,
                  label: 'Empfohlenes Level',
                  hint: '1-20',
                  icon: Icons.stars,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final level = int.tryParse(value);
                    if (level != null) viewModel.updateRecommendedLevel(level);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _estimatedDurationController,
            focusNode: _estimatedDurationFocusNode,
            label: 'Geschätzte Dauer (Stunden)',
            hint: 'z.B. 2.5',
            icon: Icons.schedule,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final duration = double.tryParse(value);
              if (duration != null) viewModel.updateEstimatedDuration(duration);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context, EditQuestViewModel viewModel) {
    final rewards = viewModel.quest?.rewards ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.dungeonBlack.withOpacity(0.85),
            DnDTheme.dungeonBlack.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DnDTheme.arcaneBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.arcaneBlue.withOpacity(0.3),
            blurRadius: 12,
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
              _buildSectionHeader(Icons.card_giftcard, 'Belohnungen'),
              ElevatedButton.icon(
                onPressed: () => _showAddRewardDialog(viewModel),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Belohnung'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.ancientGold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (rewards.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DnDTheme.dungeonBlack.withOpacity(0.1),
                    DnDTheme.dungeonBlack.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DnDTheme.arcaneBlue.withOpacity(0.4),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 48,
                    color: DnDTheme.arcaneBlue.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Noch keine Belohnungen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Füge Belohnungen hinzu, um Spieler zu motivieren',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: rewards.map((reward) {
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
        gradient: LinearGradient(
          colors: [
            DnDTheme.dungeonBlack.withOpacity(0.03),
            DnDTheme.dungeonBlack.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DnDTheme.arcaneBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DnDTheme.arcaneBlue, DnDTheme.mysticalPurple],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getRewardIcon(reward),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
              Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (reward.goldAmount != null && reward.goldAmount! > 0)
                      _buildRewardChip(
                        Icons.monetization_on,
                        '${reward.goldAmount} Gold',
                        DnDTheme.ancientGold,
                      ),
                    if (reward.experiencePoints != null && reward.experiencePoints! > 0) ...[
                      const SizedBox(width: 8),
                      _buildRewardChip(
                        Icons.auto_graph,
                        '${reward.experiencePoints} EP',
                        DnDTheme.arcaneBlue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: DnDTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _showDeleteRewardDialog(viewModel, reward),
              icon: Icon(
                Icons.delete_outline,
                color: DnDTheme.errorRed,
                size: 22,
              ),
              tooltip: 'Löschen',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(QuestReward reward) {
    if (reward.goldAmount != null && reward.goldAmount! > 0) {
      return Icons.monetization_on;
    }
    if (reward.experiencePoints != null && reward.experiencePoints! > 0) {
      return Icons.auto_graph;
    }
    return Icons.card_giftcard;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DnDTheme.arcaneBlue.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DnDTheme.arcaneBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DnDTheme.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DnDTheme.errorRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<T> items,
    required String Function(T) displayName,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DnDTheme.arcaneBlue.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DnDTheme.arcaneBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(displayName(item)),
        );
      }).toList(),
      onChanged: onChanged,
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
              gradient: LinearGradient(
                colors: [
                  DnDTheme.errorRed.withOpacity(0.15),
                  DnDTheme.errorRed.withOpacity(0.1),
                ],
              ),
              border: Border.all(color: DnDTheme.errorRed, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: DnDTheme.errorRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(
                      color: DnDTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                  elevation: 4,
                  shadowColor: DnDTheme.successGreen.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (viewModel.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      const Icon(Icons.save, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'SPEICHERN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.isLoading ? null : () => _handleCancel(viewModel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[300],
                  side: BorderSide(color: Colors.grey[600]!, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ABBRECHEN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    side: BorderSide(color: DnDTheme.arcaneBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'DUPLIZIEREN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: viewModel.isLoading ? null : () => _handleDelete(viewModel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DnDTheme.errorRed,
                    side: BorderSide(color: DnDTheme.errorRed, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'LÖSCHEN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
        backgroundColor: Colors.white.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DnDTheme.arcaneBlue, DnDTheme.mysticalPurple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Belohnung hinzufügen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'z.B. Magisches Schwert',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goldController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Gold (optional)',
                hintText: '0',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: xpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Erfahrungspunkte (optional)',
                hintText: '0',
                prefixIcon: const Icon(Icons.auto_graph),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
        backgroundColor: Colors.white.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline, color: DnDTheme.errorRed),
            ),
            const SizedBox(width: 12),
            const Text(
              'Belohnung löschen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Möchten Sie diese Belohnung wirklich löschen?\n\n${reward.name}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeReward(reward);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
    _populateFields();
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
        backgroundColor: Colors.white.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: DnDTheme.ancientGold, size: 28),
            SizedBox(width: 12),
            Text(
              'Ungespeicherte Änderungen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich gehen?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('ABBRECHEN'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.arcaneBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
        backgroundColor: Colors.white.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding:  EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.dangerous, color: DnDTheme.errorRed),
            ),
            const SizedBox(width: 12),
            Text(
              'Löschen bestätigen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Möchten Sie diesen Quest wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }
}