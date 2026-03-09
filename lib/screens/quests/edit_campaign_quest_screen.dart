// lib/screens/edit_campaign_quest_screen.dart
import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../models/quest.dart';
import '../../models/campaign_quest.dart';
import '../../theme/dnd_theme.dart';

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

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    
    try {
      // Aktualisiere den Quest mit dem neuen Status und den Notizen
      // Die Notizen werden als Quest-Beschreibung aktualisiert
      final updatedQuest = widget.campaignQuest.quest.copyWith(
        status: _selectedStatus,
        // Wir fügen die Notizen zur Beschreibung hinzu oder speichern sie separat
      );
      
      await _questRepository.update(updatedQuest);
      
      print('✅ [EditCampaignQuestScreen] Quest erfolgreich aktualisiert');
      
      setState(() => _isLoading = false);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      print('❌ [EditCampaignQuestScreen] Fehler beim Speichern: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.dungeonBlack,
        title: const Text(
          'Quest löschen?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Möchtest du "${widget.campaignQuest.quest.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DnDTheme.errorRed.withOpacity(0.5), width: 2),
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
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'LÖSCHEN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await _questRepository.delete(widget.campaignQuest.quest.id.toString());
        
        print('✅ [EditCampaignQuestScreen] Quest erfolgreich gelöscht');
        
        setState(() => _isLoading = false);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        print('❌ [EditCampaignQuestScreen] Fehler beim Löschen: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Löschen: $e'),
              backgroundColor: DnDTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.campaignQuest.quest;
    
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.mysticalPurple,
            DnDTheme.arcaneBlue,
          ],
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
                    color: Colors.white.withOpacity(0.8),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
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
          color: DnDTheme.ancientGold.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.ancientGold.withOpacity(0.2),
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
    return Column(
      children: QuestStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedStatus = status;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [DnDTheme.arcaneBlue.withOpacity(0.3), DnDTheme.mysticalPurple.withOpacity(0.3)]
                      : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? DnDTheme.arcaneBlue : Colors.grey[600]!.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: isSelected ? DnDTheme.arcaneBlue : Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _getQuestStatusDisplayName(status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? DnDTheme.arcaneBlue : Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: DnDTheme.arcaneBlue,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getStatusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return Icons.play_circle_outline;
      case QuestStatus.completed:
        return Icons.check_circle_outline;
      case QuestStatus.failed:
        return Icons.cancel;
      case QuestStatus.abandoned:
        return Icons.exit_to_app;
      case QuestStatus.onHold:
        return Icons.pause_circle_outline;
    }
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

  Widget _buildNotesSection() {
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
          color: DnDTheme.mysticalPurple.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.mysticalPurple.withOpacity(0.2),
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 8,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Schreibe deine Notizen zum Quest-Fortschritt hier...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[600]!.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DnDTheme.arcaneBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
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
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white70, width: 2),
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _deleteQuest,
            style: OutlinedButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
              side: BorderSide(color: DnDTheme.errorRed, width: 2),
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
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
