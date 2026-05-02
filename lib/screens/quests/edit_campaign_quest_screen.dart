// lib/screens/edit_campaign_quest_screen.dart
import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../models/quest.dart';
import '../../models/campaign_quest.dart';
import '../../theme/app_theme.dart';

class EditCampaignQuestScreen extends StatefulWidget {
  final CampaignQuest campaignQuest;
  final String campaignId;

  const EditCampaignQuestScreen({super.key, required this.campaignQuest, required this.campaignId});

  @override
  State<EditCampaignQuestScreen> createState() => _EditCampaignQuestScreenState();
}

class _EditCampaignQuestScreenState extends State<EditCampaignQuestScreen> {
  late QuestStatus _selectedStatus;
  late TextEditingController _notesController;
  bool _isLoading = false;
  late QuestModelRepository _questRepository;

  @override
  void initState() {
    super.initState();
    _questRepository = QuestModelRepository(DatabaseConnection.instance);
    _selectedStatus = widget.campaignQuest.status;
    _notesController = TextEditingController(text: widget.campaignQuest.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final updatedQuest = widget.campaignQuest.quest.copyWith(
        status: _selectedStatus,
      );

      await _questRepository.update(updatedQuest);

      debugPrint('✅ [EditCampaignQuestScreen] Quest erfolgreich aktualisiert');

      setState(() => _isLoading = false);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('❌ [EditCampaignQuestScreen] Fehler beim Speichern: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: context.appColors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuest() async {
    final C = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bg,
        title: const Text(
          'Quest löschen?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Möchtest du "${widget.campaignQuest.quest.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: C.red.withValues(alpha: 0.5), width: 2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ABBRECHEN',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'LÖSCHEN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await _questRepository.delete(widget.campaignQuest.quest.id.toString());

        debugPrint('✅ [EditCampaignQuestScreen] Quest erfolgreich gelöscht');

        setState(() => _isLoading = false);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        debugPrint('❌ [EditCampaignQuestScreen] Fehler beim Löschen: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Löschen: $e'),
              backgroundColor: context.appColors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final quest = widget.campaignQuest.quest;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, quest),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestInfoSection(quest),
                    const SizedBox(height: 20),
                    _buildStatusSection(),
                    const SizedBox(height: 20),
                    _buildNotesSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Quest quest) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.accent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
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
                  'Quest-Fortschritt verwalten',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestInfoSection(Quest quest) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: C.accent.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: C.accent.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'Quest-Informationen'),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.description, 'Beschreibung', quest.description),
          const SizedBox(height: 16),
          if (quest.goal.isNotEmpty)
            _buildInfoRow(Icons.flag, 'Ziel', quest.goal),
          if (quest.location != null && quest.location!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.place, 'Ort', quest.location!),
          ],
          if (quest.recommendedLevel != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.stars,
              'Empfohlenes Level',
              quest.recommendedLevel.toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final C = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: C.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: C.textSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final C = context.appColors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: C.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: C.amber.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: C.amber.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.track_changes, 'Quest-Status'),
          const SizedBox(height: 20),
          _buildStatusOptions(),
        ],
      ),
    );
  }

  Widget _buildStatusOptions() {
    final C = context.appColors;
    return Column(
      children: QuestStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedStatus = status),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? C.accent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? C.accent : C.textMid.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: isSelected ? C.accent : C.textSoft,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _getQuestStatusDisplayName(status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? C.accent : Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: C.accent, size: 24),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getStatusIcon(QuestStatus status) {
    return switch (status) {
      QuestStatus.active => Icons.play_circle_outline,
      QuestStatus.completed => Icons.check_circle_outline,
      QuestStatus.failed => Icons.cancel,
      QuestStatus.abandoned => Icons.exit_to_app,
      QuestStatus.onHold => Icons.pause_circle_outline,
    };
  }

  String _getQuestStatusDisplayName(QuestStatus status) {
    return switch (status) {
      QuestStatus.active => 'Aktiv',
      QuestStatus.completed => 'Abgeschlossen',
      QuestStatus.failed => 'Fehlgeschlagen',
      QuestStatus.abandoned => 'Aufgegeben',
      QuestStatus.onHold => 'Pausiert',
    };
  }

  Widget _buildNotesSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.note, 'DM-Notizen'),
          const SizedBox(height: 8),
          Text(
            'Verwalte den Fortschritt und Notizen zum Quest hier',
            style: TextStyle(fontSize: 13, color: C.textSoft),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 8,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Schreibe deine Notizen zum Quest-Fortschritt hier...',
              hintStyle: TextStyle(color: C.textSoft),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.textMid.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.accent, width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final C = context.appColors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: C.green.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 2),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _deleteQuest,
            style: OutlinedButton.styleFrom(
              foregroundColor: C.red,
              side: BorderSide(color: C.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                  'QUEST LÖSCHEN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
