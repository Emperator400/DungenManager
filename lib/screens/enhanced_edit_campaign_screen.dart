import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../models/quest.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/core/database_connection.dart';
import '../viewmodels/campaign_viewmodel.dart';
import '../theme/dnd_theme.dart';
import 'enhanced_edit_quest_screen.dart';

/// Enhanced Screen zur Bearbeitung von Campaigns mit CampaignViewModel
class EnhancedEditCampaignScreen extends StatefulWidget {
  final Campaign? campaign;

  const EnhancedEditCampaignScreen({
    Key? key,
    this.campaign,
  }) : super(key: key);

  @override
  State<EnhancedEditCampaignScreen> createState() => _EnhancedEditCampaignScreenState();
}

class _EnhancedEditCampaignScreenState extends State<EnhancedEditCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // temporäre Variablen für die Bearbeitung
  late CampaignStatus _status;
  late CampaignType _type;
  String? _dungeonMasterId;
  late CampaignSettings _settings;
  
  // Quest-Management
  bool _questsExpanded = false;
  List<Quest> _quests = [];
  final QuestModelRepository _questRepository = QuestModelRepository(
    DatabaseConnection.instance,
  );

  @override
  void initState() {
    super.initState();
    
    // Initialisiere temporäre Variablen mit den Werten der Kampagne oder Defaults
    _status = widget.campaign?.status ?? CampaignStatus.planning;
    _type = widget.campaign?.type ?? CampaignType.homebrew;
    _dungeonMasterId = widget.campaign?.dungeonMasterId;
    _settings = widget.campaign?.settings ?? const CampaignSettings();
    
    // Controller mit Kampagnendaten füllen
    if (widget.campaign != null) {
      _titleController.text = widget.campaign!.title;
      _descriptionController.text = widget.campaign!.description;
      // Quests laden
      _loadQuests();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty && 
           _descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _loadQuests() async {
    if (widget.campaign?.id != null) {
      final quests = await _questRepository.findByCampaign(widget.campaign!.id);
      setState(() {
        _quests = quests;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.campaign == null ? 'Neue Kampagne' : 'Kampagne bearbeiten',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        backgroundColor: DnDTheme.dungeonBlack,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DnDTheme.dungeonBlack,
                DnDTheme.stoneGrey.withOpacity(0.3),
              ],
            ),
          ),
        ),
        actions: [
          Consumer<CampaignViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(
                  Icons.save, 
                  color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
                ),
                onPressed: _canSave && !viewModel.isLoading ? _saveCampaign : null,
                tooltip: 'Speichern',
              );
            },
          ),
        ],
      ),
      body: Consumer<CampaignViewModel>(
        builder: (context, viewModel, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fehlermeldung
                  if (viewModel.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.error!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: viewModel.clearError,
                            color: Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),

                  // Grundinformationen
                  _buildSectionCard(
                    title: 'Grundinformationen',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration('Titel', Icons.title),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Titel ist erforderlich';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration('Beschreibung', Icons.description),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Beschreibung ist erforderlich';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusDropdown(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTypeDropdown(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kampagnen-Einstellungen
                  _buildSectionCard(
                    title: 'Kampagnen-Einstellungen',
                    icon: Icons.settings,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSettingsField(
                                label: 'Start-Level',
                                icon: Icons.trending_up,
                                value: _settings.startingLevel,
                                min: 1,
                                max: 20,
                                onChanged: (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(startingLevel: value);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSettingsField(
                                label: 'Max-Level',
                                icon: Icons.trending_up,
                                value: _settings.maxPlayerLevel,
                                min: 1,
                                max: 20,
                                onChanged: (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(maxPlayerLevel: value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _settings.partySize,
                          decoration: _buildInputDecoration('Party-Größe', Icons.group),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(partySize: value);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: Text('Benutzerdefinierte Inhalte zulassen'),
                          subtitle: Text('Spieler können eigene Inhalte erstellen'),
                          value: _settings.allowCustomContent,
                          activeColor: DnDTheme.ancientGold,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(allowCustomContent: value);
                            });
                          },
                        ),
                        SwitchListTile(
                          title: Text('Öffentlich'),
                          subtitle: Text('Kampagne für andere sichtbar'),
                          value: _settings.isPublic,
                          activeColor: DnDTheme.ancientGold,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(isPublic: value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quest-Management (neu)
                  if (widget.campaign != null)
                    _buildQuestsSection(),

                  const SizedBox(height: 16),

                  // Kampagnen-Informationen
                  _buildSectionCard(
                    title: 'Zusätzliche Informationen',
                    icon: Icons.info,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.group, color: DnDTheme.ancientGold),
                            const SizedBox(width: 8),
                            Text(
                              'Spieler: ${widget.campaign?.playerCount ?? 0}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if ((widget.campaign?.playerCount ?? 0) > 0)
                              TextButton.icon(
                                onPressed: () => _showPlayerDialog(),
                                icon: Icon(Icons.edit, size: 16),
                                label: Text('Spieler verwalten'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.description, color: DnDTheme.ancientGold),
                            const SizedBox(width: 8),
                            Text(
                              'Quests: ${_quests.length}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event, color: DnDTheme.ancientGold),
                            const SizedBox(width: 8),
                            Text(
                              'Sessions: ${widget.campaign?.sessionCount ?? 0}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if ((widget.campaign?.sessionCount ?? 0) > 0)
                              TextButton.icon(
                                onPressed: () {
                                  // Navigation zu Sessions (TODO)
                                },
                                icon: Icon(Icons.chevron_right, size: 16),
                                label: Text('Anzeigen'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Aktionen
                  _buildActionButtons(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestsSection() {
    return _buildSectionCard(
      title: 'Quests',
      icon: Icons.assignment,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_quests.length} Quest${_quests.length != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle, color: DnDTheme.ancientGold),
                    onPressed: _createNewQuest,
                    tooltip: 'Neue Quest erstellen',
                  ),
                  IconButton(
                    icon: Icon(
                      _questsExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _questsExpanded = !_questsExpanded;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_questsExpanded) ...[
            const SizedBox(height: 12),
            if (_quests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Noch keine Quests erstellt',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._quests.map((quest) => _buildQuestCard(quest)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestCard(Quest quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        border: Border.all(color: DnDTheme.ancientGold.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildQuestStatusChip(quest.status),
                        const SizedBox(width: 8),
                        _buildQuestTypeChip(quest.questType),
                        const SizedBox(width: 8),
                        _buildQuestDifficultyChip(quest.difficulty),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: Colors.white70),
                    onPressed: () => _editQuest(quest),
                    tooltip: 'Bearbeiten',
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: Colors.white70),
                    onPressed: () => _duplicateQuest(quest),
                    tooltip: 'Duplizieren',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: DnDTheme.errorRed),
                    onPressed: () => _deleteQuest(quest),
                    tooltip: 'Löschen',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestStatusChip(QuestStatus status) {
    Color bgColor;
    String label;
    
    switch (status) {
      case QuestStatus.active:
        bgColor = DnDTheme.successGreen;
        label = 'Aktiv';
        break;
      case QuestStatus.completed:
        bgColor = Colors.blue;
        label = 'Abgeschlossen';
        break;
      case QuestStatus.failed:
        bgColor = DnDTheme.errorRed;
        label = 'Fehlgeschlagen';
        break;
      case QuestStatus.abandoned:
        bgColor = Colors.orange;
        label = 'Aufgegeben';
        break;
      case QuestStatus.onHold:
        bgColor = Colors.grey;
        label = 'Pausiert';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bgColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuestTypeChip(QuestType type) {
    String label;
    
    switch (type) {
      case QuestType.main:
        label = 'Haupt';
        break;
      case QuestType.side:
        label = 'Neben';
        break;
      case QuestType.personal:
        label = 'Persönlich';
        break;
      case QuestType.faction:
        label = 'Fraktion';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DnDTheme.arcaneBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DnDTheme.arcaneBlue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuestDifficultyChip(QuestDifficulty difficulty) {
    Color color;
    String label;
    
    switch (difficulty) {
      case QuestDifficulty.easy:
        color = Colors.green;
        label = 'Leicht';
        break;
      case QuestDifficulty.medium:
        color = Colors.yellow;
        label = 'Mittel';
        break;
      case QuestDifficulty.hard:
        color = Colors.orange;
        label = 'Schwer';
        break;
      case QuestDifficulty.deadly:
        color = DnDTheme.errorRed;
        label = 'Tödlich';
        break;
      case QuestDifficulty.epic:
        color = Colors.purple;
        label = 'Episch';
        break;
      case QuestDifficulty.legendary:
        color = DnDTheme.ancientGold;
        label = 'Legendär';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DnDTheme.ancientGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: DnDTheme.ancientGold, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
      ),
      prefixIcon: Icon(icon, color: DnDTheme.ancientGold),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.ancientGold),
      ),
      filled: true,
      fillColor: DnDTheme.slateGrey,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<CampaignStatus>(
      value: _status,
      decoration: _buildInputDecoration('Status', Icons.flag),
      items: CampaignStatus.values.map((status) {
        final isSelected = _status == status;
        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(_getStatusIcon(status), size: 18),
              const SizedBox(width: 8),
              Text(
                _getLocalizedStatus(status),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (CampaignStatus? value) {
        if (value != null) {
          setState(() {
            _status = value;
          });
        }
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<CampaignType>(
      value: _type,
      decoration: _buildInputDecoration('Typ', Icons.category),
      items: CampaignType.values.map((type) {
        final isSelected = _type == type;
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getTypeIcon(type), size: 18),
              const SizedBox(width: 8),
              Text(
                _getLocalizedType(type),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (CampaignType? value) {
        if (value != null) {
          setState(() {
            _type = value;
          });
        }
      },
    );
  }

  Widget _buildSettingsField({
    required String label,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: DnDTheme.ancientGold,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: DnDTheme.ancientGold,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  label: value.toString(),
                  onChanged: (double newValue) {
                    onChanged(newValue.toInt());
                  },
                ),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getStatusIcon(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.planning:
        return Icons.edit_note;
      case CampaignStatus.active:
        return Icons.play_circle;
      case CampaignStatus.paused:
        return Icons.pause_circle;
      case CampaignStatus.completed:
        return Icons.check_circle;
      case CampaignStatus.cancelled:
        return Icons.cancel;
    }
  }

  IconData _getTypeIcon(CampaignType type) {
    switch (type) {
      case CampaignType.homebrew:
        return Icons.home;
      case CampaignType.module:
        return Icons.book;
      case CampaignType.adventurePath:
        return Icons.map;
      case CampaignType.oneShot:
        return Icons.flash_on;
    }
  }

  Widget _buildActionButtons(CampaignViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('Abbrechen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _canSave && !viewModel.isLoading ? _saveCampaign : null,
            icon: viewModel.isLoading 
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.save),
            label: Text('Speichern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (widget.campaign != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _duplicateCampaign,
              icon: Icon(Icons.copy),
              label: Text('Duplizieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.deepRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  String _getLocalizedStatus(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.planning:
        return 'Planung';
      case CampaignStatus.active:
        return 'Aktiv';
      case CampaignStatus.paused:
        return 'Pausiert';
      case CampaignStatus.completed:
        return 'Abgeschlossen';
      case CampaignStatus.cancelled:
        return 'Abgebrochen';
    }
  }

  String _getLocalizedType(CampaignType type) {
    switch (type) {
      case CampaignType.homebrew:
        return 'Homebrew';
      case CampaignType.module:
        return 'Module';
      case CampaignType.adventurePath:
        return 'Adventure Path';
      case CampaignType.oneShot:
        return 'One-Shot';
    }
  }

  void _showPlayerDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Spieler verwalten'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              Text('Spieler-Management-Funktion wird in zukünftiger Version implementiert.'),
              const SizedBox(height: 20),
              Text(
                'Aktuelle Spieleranzahl: ${widget.campaign?.playerCount ?? 0}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewQuest() async {
    if (widget.campaign?.id == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedEditQuestScreenWithProvider(
          quest: null,
          campaignId: widget.campaign!.id,
        ),
      ),
    );
    
    if (result == true) {
      // Quest wurde erfolgreich erstellt, neu laden
      await _loadQuests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest erfolgreich erstellt'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _editQuest(Quest quest) async {
    if (widget.campaign?.id == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedEditQuestScreenWithProvider(
          quest: quest,
          campaignId: widget.campaign!.id,
        ),
      ),
    );
    
    if (result == true) {
      // Quest wurde erfolgreich bearbeitet, neu laden
      await _loadQuests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest erfolgreich aktualisiert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _duplicateQuest(Quest quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quest duplizieren'),
        content: Text('Möchten Sie "${quest.title}" wirklich duplizieren?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Duplizieren'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && widget.campaign?.id != null) {
      final now = DateTime.now();
      final duplicatedQuest = Quest(
        id: now.millisecondsSinceEpoch,
        title: '${quest.title} (Kopie)',
        description: quest.description,
        status: QuestStatus.active,
        questType: quest.questType,
        difficulty: quest.difficulty,
        createdAt: now,
        updatedAt: now,
        location: quest.location,
        recommendedLevel: quest.recommendedLevel,
        estimatedDurationHours: quest.estimatedDurationHours,
        isFavorite: false,
        campaignId: widget.campaign!.id,
        tags: List<String>.from(quest.tags),
        rewards: List.from(quest.rewards),
        involvedNpcs: List<String>.from(quest.involvedNpcs),
        linkedWikiEntryIds: List<String>.from(quest.linkedWikiEntryIds),
      );
      
      await _questRepository.create(duplicatedQuest);
      await _loadQuests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest erfolgreich dupliziert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuest(Quest quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quest löschen'),
        content: Text('Möchten Sie "${quest.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DnDTheme.errorRed),
            child: Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _questRepository.delete(quest.id.toString());
      await _loadQuests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest erfolgreich gelöscht'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<CampaignViewModel>();
    
    if (widget.campaign == null) {
      // Neue Kampagne erstellen
      await viewModel.createCampaign(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    } else {
      // Bestehende Kampagne aktualisieren
      final updatedCampaign = widget.campaign!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        type: _type,
        dungeonMasterId: _dungeonMasterId,
        settings: _settings,
        updatedAt: DateTime.now(),
      );
      
      await viewModel.updateCampaign(updatedCampaign);
    }
    
    // Wenn erfolgreich, zurückspringen
    if (viewModel.error == null && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _duplicateCampaign() async {
    if (widget.campaign != null) {
      final viewModel = context.read<CampaignViewModel>();
      await viewModel.duplicateCampaign(widget.campaign!);
      
      if (viewModel.error == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kampagne dupliziert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}