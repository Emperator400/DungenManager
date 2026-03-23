import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scene.dart';
import '../../models/quest.dart';
import '../../models/sound.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/edit_scene_viewmodel.dart';
import '../../theme/dnd_theme.dart';
import '../../services/sound_service.dart';
import '../characters/select_character_screen.dart';

/// Enhanced Screen zur Bearbeitung von Scenes mit D&D Theme
class EditSceneScreen extends StatefulWidget {
  final Scene? scene;
  final String? sessionId; // Für neue Scenes

  const EditSceneScreen({
    Key? key,
    this.scene,
    this.sessionId,
  }) : super(key: key);

  @override
  State<EditSceneScreen> createState() => _EditSceneScreenState();
}

class _EditSceneScreenState extends State<EditSceneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _volume = 1.0;
  bool _isPlaying = false;
  String? _currentPlayingSoundId;

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewModel();
    });
  }

  Future<void> _initializeViewModel() async {
    // Prüfe ob Widget noch gemounted ist
    if (!mounted) return;
    
    final viewModel = context.read<EditSceneViewModel>();
    
    // Initialisiere zuerst die Scene
    await viewModel.initialize(
      widget.scene,
      sessionId: widget.sessionId,
    );
    
    if (!mounted) return;
    _controllersFromViewModel();
    
    // Lade verfügbare Daten
    await viewModel.loadAvailableQuests();
    if (!mounted) return;
    
    await viewModel.loadAvailableSounds();
    if (!mounted) return;
    
    await viewModel.loadAvailableWikiEntries();
    if (!mounted) return;
    
    // Jetzt baue die verknüpften Listen auf (nachdem die Scene initialisiert ist)
    await viewModel.buildLinkedCharactersList();
    if (!mounted) return;
    
    await viewModel.buildLinkedQuestsList();
    if (!mounted) return;
    
    await viewModel.buildLinkedSoundsList();
    if (!mounted) return;
    
    await viewModel.buildLinkedWikiEntriesList();
  }

  @override
  void dispose() {
    // Sound stoppen bevor Widget disposed wird
    SoundService.stopSound();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _controllersFromViewModel() {
    final viewModel = context.read<EditSceneViewModel>();
    final scene = viewModel.scene;
    
    if (scene != null) {
      _nameController.text = scene!.name;
      _descriptionController.text = scene!.description;
    }
  }

  void _updateViewModel() {
    final viewModel = context.read<EditSceneViewModel>();
    
    viewModel.updateName(_nameController.text);
    viewModel.updateDescription(_descriptionController.text);
    // Location und Notes werden im Moment nicht unterstützt
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: _buildAppBar(),
      body: Consumer<EditSceneViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: DnDTheme.ancientGold,
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fehlermeldung
                  if (viewModel.errorMessage != null)
                    _buildErrorWidget(viewModel.errorMessage!, viewModel),

                  // Grundinformationen
                  _buildSectionCard(
                    title: 'Grundinformationen',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration('Name', Icons.title),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name ist erforderlich';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: DnDTheme.md),
                        Consumer<EditSceneViewModel>(
                          builder: (context, viewModel, child) {
                            return DropdownButtonFormField<SceneType>(
                              value: viewModel.scene?.sceneType ?? SceneType.Exploration,
                              decoration: _buildInputDecoration('Szenen-Typ', Icons.category),
                              items: SceneType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.name,
                                    style: DnDTheme.bodyText1.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                              dropdownColor: DnDTheme.stoneGrey,
                              onChanged: (SceneType? value) {
                                if (value != null) {
                                  viewModel.updateSceneType(value);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DnDTheme.md),

                  // Beschreibung
                  _buildSectionCard(
                    title: 'Beschreibung',
                    icon: Icons.description,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: _buildInputDecoration('Beschreibung', Icons.article),
                      maxLines: 5,
                      onChanged: (_) => _updateViewModel(),
                    ),
                  ),

                  const SizedBox(height: DnDTheme.md),

                  // Charaktere
                  Consumer<EditSceneViewModel>(
                    builder: (context, viewModel, child) {
                      return _buildSectionCard(
                        title: 'Charaktere (${viewModel.linkedCharacters.length})',
                        icon: Icons.people,
                        child: Column(
                          children: [
                            if (viewModel.linkedCharacters.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(DnDTheme.md),
                                child: Text(
                                  'Keine Charaktere verknüpft',
                                  style: DnDTheme.bodyText2.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            else
                              ...viewModel.linkedCharacters.map((char) => 
                                _buildCharacterCard(char)
                              ),
                            const SizedBox(height: DnDTheme.md),
                            ElevatedButton.icon(
                              onPressed: () => _showCharacterSelector(viewModel),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Charakter hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DnDTheme.arcaneBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: DnDTheme.md),

                  // Quests
                  Consumer<EditSceneViewModel>(
                    builder: (context, viewModel, child) {
                      return _buildSectionCard(
                        title: 'Quests (${viewModel.linkedQuests.length})',
                        icon: Icons.flag,
                        child: Column(
                          children: [
                            if (viewModel.linkedQuests.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(DnDTheme.md),
                                child: Text(
                                  'Keine Quests verknüpft',
                                  style: DnDTheme.bodyText2.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            else
                              ...viewModel.linkedQuests.map((quest) => 
                                _buildQuestCard(quest)
                              ),
                            const SizedBox(height: DnDTheme.md),
                            ElevatedButton.icon(
                              onPressed: () => _showQuestSelector(viewModel),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Quest hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DnDTheme.ancientGold,
                                foregroundColor: DnDTheme.dungeonBlack,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: DnDTheme.md),

                  // Sounds - Vollständige Playback-Sektion
                  Consumer<EditSceneViewModel>(
                    builder: (context, viewModel, child) {
                      return _buildSectionCard(
                        title: 'Sounds (${viewModel.linkedSounds.length})',
                        icon: Icons.music_note,
                        child: Column(
                          children: [
                            if (viewModel.linkedSounds.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(DnDTheme.md),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.music_note_outlined,
                                        size: 48,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(height: DnDTheme.md),
                                      Text(
                                        'Keine Sounds verknüpft',
                                        style: DnDTheme.bodyText1.copyWith(
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...viewModel.linkedSounds.map((sound) => 
                                _buildSoundCard(sound)
                              ),
                            const SizedBox(height: DnDTheme.lg),
                            // Button zum Hinzufügen (immer sichtbar)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showSoundSelector(viewModel),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Sound hinzufügen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DnDTheme.successGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: DnDTheme.md,
                                    horizontal: DnDTheme.lg,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: DnDTheme.md),

                  // Combat-Sektion (nur wenn SceneType.Combat)
                  Consumer<EditSceneViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.scene?.sceneType != SceneType.Combat) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildCombatSection(viewModel);
                    },
                  ),

                  const SizedBox(height: DnDTheme.md),

                  // Wiki-Einträge
                  Consumer<EditSceneViewModel>(
                    builder: (context, viewModel, child) {
                      return _buildSectionCard(
                        title: 'Wiki-Einträge (${viewModel.linkedWikiEntries.length})',
                        icon: Icons.book,
                        child: Column(
                          children: [
                            if (viewModel.linkedWikiEntries.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(DnDTheme.md),
                                child: Text(
                                  'Keine Wiki-Einträge verknüpft',
                                  style: DnDTheme.bodyText2.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            else
                              ...viewModel.linkedWikiEntries.map((wikiEntry) => 
                                _buildWikiEntryCard(wikiEntry)
                              ),
                            const SizedBox(height: DnDTheme.md),
                            ElevatedButton.icon(
                              onPressed: () => _showWikiEntrySelector(viewModel),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Wiki-Eintrag hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DnDTheme.mysticalPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: DnDTheme.lg),

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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.scene == null ? 'Neue Scene' : 'Scene bearbeiten',
        style: DnDTheme.headline2.copyWith(
          color: Colors.white,
        ),
      ),
      backgroundColor: DnDTheme.stoneGrey,
      foregroundColor: Colors.white,
      elevation: 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: DnDTheme.stoneGrey,
            endColor: DnDTheme.slateGrey,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Consumer<EditSceneViewModel>(
          builder: (context, viewModel, child) {
            return Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.ancientGold,
                width: 2,
              ),
              child: IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: viewModel.canSave ? _saveScene : null,
                tooltip: 'Speichern',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String errorMessage, EditSceneViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.errorRed.withValues(alpha: 0.2),
          endColor: DnDTheme.errorRed.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.errorRed,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: DnDTheme.errorRed, size: 20),
          const SizedBox(width: DnDTheme.sm),
          Expanded(
            child: Text(
              errorMessage,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: viewModel.clearError,
            color: DnDTheme.errorRed,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: DnDTheme.arcaneBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DnDTheme.sm),
            decoration: BoxDecoration(
              gradient: DnDTheme.getMysticalGradient(
                startColor: DnDTheme.arcaneBlue.withValues(alpha: 0.8),
                endColor: DnDTheme.arcaneBlue.withValues(alpha: 0.4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DnDTheme.radiusMedium),
                topRight: Radius.circular(DnDTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: DnDTheme.arcaneBlue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: DnDTheme.sm),
                Text(
                  title,
                  style: DnDTheme.headline3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(DnDTheme.md),
            child: child,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: DnDTheme.bodyText2.copyWith(
        color: DnDTheme.ancientGold,
      ),
      prefixIcon: Icon(icon, color: DnDTheme.ancientGold),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        borderSide: const BorderSide(color: DnDTheme.arcaneBlue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        borderSide: BorderSide(
          color: DnDTheme.arcaneBlue.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        borderSide: const BorderSide(color: DnDTheme.ancientGold, width: 2),
      ),
      filled: true,
      fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
    );
  }

  Widget _buildCharacterCard(Map<String, dynamic> char) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: _getCharacterColor(char['type']).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Character Icon
          Container(
            decoration: BoxDecoration(
              color: _getCharacterColor(char['type']).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getCharacterColor(char['type']),
                width: 2,
              ),
            ),
            child: Icon(
              _getCharacterIcon(char['type']),
              color: _getCharacterColor(char['type']),
              size: 20,
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          // Character Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  char['name'].toString(),
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getCharacterSubtitle(char),
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Remove Button
          GestureDetector(
            onTap: () => _removeCharacter(char['id'].toString()),
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.xs),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DnDTheme.errorRed,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.close,
                color: DnDTheme.errorRed,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EditSceneViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
              side: const BorderSide(
                color: DnDTheme.arcaneBlue,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              ),
            ),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.arcaneBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: DnDTheme.md),
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.canSave ? _saveScene : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
              padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              ),
              elevation: 4,
            ),
            child: Text(
              'Speichern',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.dungeonBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: DnDTheme.md),
        if (viewModel.isEditing)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _duplicateScene,
              icon: Icon(Icons.copy, color: DnDTheme.dungeonBlack, size: 16),
              label: Text('Duplizieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.mysticalPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                ),
                elevation: 4,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _saveScene() async {
    final viewModel = context.read<EditSceneViewModel>();
    
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.saveScene();
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Scene erfolgreich gespeichert',
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: DnDTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _duplicateScene() async {
    final viewModel = context.read<EditSceneViewModel>();
    await viewModel.duplicateScene();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.content_copy, color: Colors.white),
            const SizedBox(width: DnDTheme.sm),
            Text(
              'Scene dupliziert',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        ),
      ),
    );
  }

  // Hilfsmethoden für Charaktere
  Color _getCharacterColor(dynamic type) {
    final typeStr = type.toString();
    switch (typeStr) {
      case 'PC':
        return DnDTheme.successGreen;
      case 'NPC':
        return DnDTheme.arcaneBlue;
      case 'Monster':
        return DnDTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getCharacterIcon(dynamic type) {
    final typeStr = type.toString();
    switch (typeStr) {
      case 'PC':
        return Icons.person;
      case 'NPC':
        return Icons.person_outline;
      case 'Monster':
        return Icons.pets;
      default:
        return Icons.help;
    }
  }

  String _getCharacterSubtitle(Map<String, dynamic> char) {
    final type = char['type']?.toString() ?? '';
    if (type == 'PC') {
      return 'Level ${char['level'] ?? '?'}';
    } else if (char['challengeRating'] != null) {
      return 'CR ${char['challengeRating']}';
    } else {
      return type;
    }
  }

  void _removeCharacter(String characterId) {
    final viewModel = context.read<EditSceneViewModel>();
    viewModel.removeCharacter(characterId);
  }

  Future<void> _showCharacterSelector(EditSceneViewModel viewModel) async {
    final selectedIds = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCharacterForSceneScreen(
          previouslySelectedIds: viewModel.scene?.linkedCharacterIds ?? [],
        ),
      ),
    );

    if (selectedIds != null) {
      viewModel.updateLinkedCharacters(selectedIds);
      viewModel.buildLinkedCharactersList();
      await viewModel.loadAvailableQuests();
      viewModel.buildLinkedQuestsList();
    }
  }

  // ===== QUEST METHODEN =====

  Widget _buildQuestCard(Quest quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: _getQuestStatusColor(quest.status).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Quest Icon
          Container(
            decoration: BoxDecoration(
              color: _getQuestStatusColor(quest.status).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getQuestStatusColor(quest.status),
                width: 2,
              ),
            ),
            child: Icon(
              _getQuestStatusIcon(quest.status),
              color: _getQuestStatusColor(quest.status),
              size: 20,
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          // Quest Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (quest.location != null && quest.location!.isNotEmpty)
                  Text(
                    'Ort: ${quest.location}',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DnDTheme.xs, vertical: 2),
            decoration: BoxDecoration(
              color: _getQuestStatusColor(quest.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              border: Border.all(
                color: _getQuestStatusColor(quest.status),
                width: 1,
              ),
            ),
            child: Text(
              _getQuestStatusText(quest.status),
              style: DnDTheme.bodyText2.copyWith(
                color: _getQuestStatusColor(quest.status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          // Remove Button
          GestureDetector(
            onTap: () => _removeQuest(quest.id),
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.xs),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DnDTheme.errorRed,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.close,
                color: DnDTheme.errorRed,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeQuest(int questId) {
    final viewModel = context.read<EditSceneViewModel>();
    viewModel.removeQuest(questId.toString());
  }

  Future<void> _showQuestSelector(EditSceneViewModel viewModel) async {
    // Zeige einen einfachen Dialog zur Quest-Auswahl
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Quest hinzufügen',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: viewModel.availableQuests.isEmpty
              ? Center(
                  child: Text(
                    'Keine Quests verfügbar',
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewModel.availableQuests.length,
                  itemBuilder: (context, index) {
                    final quest = viewModel.availableQuests[index];
                    final isLinked = viewModel.scene?.linkedQuestIds.contains(quest.id) ?? false;
                    return ListTile(
                      title: Text(
                        quest.title,
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      subtitle: quest.location != null && quest.location!.isNotEmpty
                          ? Text(
                              'Ort: ${quest.location}',
                              style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                            )
                          : null,
                      trailing: isLinked
                          ? Icon(Icons.check_circle, color: DnDTheme.successGreen)
                          : Icon(Icons.add_circle_outline, color: Colors.white54),
                      onTap: isLinked
                          ? null
                          : () {
                              Navigator.pop(context);
                              viewModel.addQuest(quest.id.toString());
                            },
                      enabled: !isLinked,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Schließen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
            ),
          ),
        ],
      ),
    );
  }

  // Hilfsmethoden für Quests
  Color _getQuestStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return Colors.grey;
      case QuestStatus.onHold:
        return DnDTheme.arcaneBlue;
      case QuestStatus.completed:
        return DnDTheme.successGreen;
      case QuestStatus.failed:
        return DnDTheme.errorRed;
      case QuestStatus.abandoned:
        return Colors.orange;
    }
  }

  IconData _getQuestStatusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return Icons.flag_outlined;
      case QuestStatus.onHold:
        return Icons.play_arrow;
      case QuestStatus.completed:
        return Icons.check_circle;
      case QuestStatus.failed:
        return Icons.cancel;
      case QuestStatus.abandoned:
        return Icons.remove_circle;
    }
  }

  String _getQuestStatusText(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return 'Aktiv';
      case QuestStatus.onHold:
        return 'In Arbeit';
      case QuestStatus.completed:
        return 'Abgeschlossen';
      case QuestStatus.failed:
        return 'Fehlgeschlagen';
      case QuestStatus.abandoned:
        return 'Aufgegeben';
    }
  }

  // ===== WIKI ENTRY METHODEN =====

  // Hilfsmethoden für Wiki-Einträge (muss vor Verwendung deklariert werden)
  Color _getWikiEntryTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return DnDTheme.successGreen;
      case WikiEntryType.Place:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Lore:
        return DnDTheme.ancientGold;
      case WikiEntryType.Faction:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Magic:
        return Colors.purple;
      case WikiEntryType.History:
        return Colors.orange;
      case WikiEntryType.Item:
        return DnDTheme.infoBlue;
      case WikiEntryType.Quest:
        return DnDTheme.successGreen;
      case WikiEntryType.Creature:
        return DnDTheme.errorRed;
    }
  }

  IconData _getWikiEntryTypeIcon(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.place;
      case WikiEntryType.Lore:
        return Icons.book;
      case WikiEntryType.Faction:
        return Icons.groups;
      case WikiEntryType.Magic:
        return Icons.auto_awesome;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.flag;
      case WikiEntryType.Creature:
        return Icons.pets;
    }
  }

  // Wiki-Entry UI Methoden
  Widget _buildWikiEntryCard(WikiEntry wikiEntry) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: _getWikiEntryTypeColor(wikiEntry.entryType).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // WikiEntry Icon
          Container(
            decoration: BoxDecoration(
              color: _getWikiEntryTypeColor(wikiEntry.entryType).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getWikiEntryTypeColor(wikiEntry.entryType),
                width: 2,
              ),
            ),
            child: Icon(
              _getWikiEntryTypeIcon(wikiEntry.entryType),
              color: _getWikiEntryTypeColor(wikiEntry.entryType),
              size: 20,
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          // WikiEntry Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wikiEntry.title,
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  wikiEntry.entryType.name,
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          // Remove Button
          GestureDetector(
            onTap: () => _removeWikiEntry(wikiEntry.id),
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.xs),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DnDTheme.errorRed,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.close,
                color: DnDTheme.errorRed,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeWikiEntry(String wikiId) {
    final viewModel = context.read<EditSceneViewModel>();
    viewModel.removeWikiEntry(wikiId);
  }

  Future<void> _showWikiEntrySelector(EditSceneViewModel viewModel) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Wiki-Eintrag hinzufügen',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.mysticalPurple),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: viewModel.availableWikiEntries.isEmpty
              ? Center(
                  child: Text(
                    'Keine Wiki-Einträge verfügbar',
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewModel.availableWikiEntries.length,
                  itemBuilder: (context, index) {
                    final wikiEntry = viewModel.availableWikiEntries[index];
                    final isLinked = viewModel.scene?.linkedWikiEntryIds.contains(wikiEntry.id) ?? false;
                    return ListTile(
                      title: Text(
                        wikiEntry.title,
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        wikiEntry.entryType.name,
                        style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                      ),
                      trailing: isLinked
                          ? Icon(Icons.check_circle, color: DnDTheme.successGreen)
                          : Icon(Icons.add_circle_outline, color: Colors.white54),
                      onTap: isLinked
                          ? null
                          : () {
                              Navigator.pop(context);
                              viewModel.addWikiEntry(wikiEntry.id);
                            },
                      enabled: !isLinked,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Schließen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
            ),
          ),
        ],
      ),
    );
  }

  // ===== SOUND METHODEN =====

  Widget _buildSoundCard(Sound sound) {
    final isCurrentlyPlaying = _currentPlayingSoundId == sound.id && _isPlaying;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: isCurrentlyPlaying 
            ? DnDTheme.ancientGold.withValues(alpha: 0.8)
            : DnDTheme.successGreen.withValues(alpha: 0.5),
          width: isCurrentlyPlaying ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Obere Reihe: Sound-Info und Buttons
          Row(
            children: [
              // Sound Icon
              Container(
                decoration: BoxDecoration(
                  color: isCurrentlyPlaying 
                    ? DnDTheme.ancientGold.withValues(alpha: 0.2)
                    : DnDTheme.successGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentlyPlaying 
                      ? DnDTheme.ancientGold
                      : DnDTheme.successGreen,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCurrentlyPlaying ? Icons.volume_up : Icons.music_note,
                  color: isCurrentlyPlaying 
                    ? DnDTheme.ancientGold
                    : DnDTheme.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: DnDTheme.sm),
              // Sound Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.name,
                      style: DnDTheme.bodyText1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sound.categoryId != null && sound.categoryId!.isNotEmpty)
                      Text(
                        sound.categoryId!,
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Sound Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: DnDTheme.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: DnDTheme.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  border: Border.all(
                    color: DnDTheme.successGreen,
                    width: 1,
                  ),
                ),
                child: Text(
                  sound.soundType.name,
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.successGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DnDTheme.xs),
              // Play/Pause Toggle
              GestureDetector(
                onTap: () => _togglePlayPause(sound.id, sound.filePath),
                child: Container(
                  padding: const EdgeInsets.all(DnDTheme.xs),
                  decoration: BoxDecoration(
                    color: isCurrentlyPlaying
                      ? DnDTheme.ancientGold.withValues(alpha: 0.2)
                      : DnDTheme.successGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrentlyPlaying
                        ? DnDTheme.ancientGold
                        : DnDTheme.successGreen,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                    color: isCurrentlyPlaying
                      ? DnDTheme.ancientGold
                      : DnDTheme.successGreen,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: DnDTheme.xs),
              // Stop Button (nur wenn aktiv)
              if (isCurrentlyPlaying) ...[
                GestureDetector(
                  onTap: () => _stopSound(),
                  child: Container(
                    padding: const EdgeInsets.all(DnDTheme.xs),
                    decoration: BoxDecoration(
                      color: DnDTheme.errorRed.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DnDTheme.errorRed,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.stop,
                      color: DnDTheme.errorRed,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: DnDTheme.xs),
              ],
              // Remove Button
              GestureDetector(
                onTap: () => _removeSound(sound.id),
                child: Container(
                  padding: const EdgeInsets.all(DnDTheme.xs),
                  decoration: BoxDecoration(
                    color: DnDTheme.errorRed.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DnDTheme.errorRed,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: DnDTheme.errorRed,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          // Untere Reihe: Lautstärkeregler (nur wenn aktiv)
          if (isCurrentlyPlaying) ...[
            const SizedBox(height: DnDTheme.sm),
            Row(
              children: [
                Icon(
                  Icons.volume_down,
                  color: DnDTheme.ancientGold,
                  size: 16,
                ),
                const SizedBox(width: DnDTheme.sm),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: DnDTheme.ancientGold,
                      inactiveTrackColor: DnDTheme.successGreen.withValues(alpha: 0.3),
                      thumbColor: DnDTheme.ancientGold,
                      overlayColor: DnDTheme.ancientGold.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                        });
                        _updateVolume();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: DnDTheme.sm),
                Icon(
                  Icons.volume_up,
                  color: DnDTheme.ancientGold,
                  size: 16,
                ),
                const SizedBox(width: DnDTheme.sm),
                Text(
                  '${(_volume * 100).toInt()}%',
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _removeSound(String soundId) {
    final viewModel = context.read<EditSceneViewModel>();
    viewModel.removeSound(soundId);
  }

  Future<void> _playSound(String filePath) async {
    final success = await SoundService.playSound(filePath);
    if (success) {
      setState(() {
        _isPlaying = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Fehler beim Abspielen des Sounds',
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: DnDTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _togglePlayPause(String soundId, String filePath) async {
    if (_currentPlayingSoundId == soundId && _isPlaying) {
      // Pause
      await SoundService.pauseSound();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Play (neuer Sound oder nach Pause)
      if (_currentPlayingSoundId != soundId) {
        // Anderer Sound: zuerst stoppen
        await SoundService.stopSound();
        await _playSound(filePath);
        setState(() {
          _currentPlayingSoundId = soundId;
          _isPlaying = true;
          _volume = 1.0; // Lautstärke zurücksetzen
        });
        await SoundService.setVolume(_volume);
      } else {
        // Nach Pause weiterspielen
        await _playSound(filePath);
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  Future<void> _stopSound() async {
    await SoundService.stopSound();
    setState(() {
      _isPlaying = false;
      _currentPlayingSoundId = null;
    });
  }

  Future<void> _updateVolume() async {
    await SoundService.setVolume(_volume);
  }

  // ===== COMBAT SECTION =====

  Widget _buildCombatSection(EditSceneViewModel viewModel) {
    final hasEncounter = viewModel.hasLinkedEncounter;
    
    return _buildSectionCard(
      title: 'Kampf-Planung',
      icon: Icons.gavel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info-Text
          Container(
            padding: const EdgeInsets.all(DnDTheme.sm),
            decoration: BoxDecoration(
              color: DnDTheme.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              border: Border.all(
                color: DnDTheme.errorRed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: DnDTheme.errorRed, size: 20),
                const SizedBox(width: DnDTheme.sm),
                Expanded(
                  child: Text(
                    'Diese Szene ist als Kampfszene markiert. '
                    'Du kannst einen Encounter planen, der während der Session gestartet werden kann.',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DnDTheme.md),
          
          // Encounter Status
          if (hasEncounter) ...[
            Container(
              padding: const EdgeInsets.all(DnDTheme.md),
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: DnDTheme.successGreen.withValues(alpha: 0.2),
                  endColor: DnDTheme.successGreen.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                border: Border.all(
                  color: DnDTheme.successGreen,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: DnDTheme.successGreen, size: 24),
                  const SizedBox(width: DnDTheme.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encounter geplant',
                          style: DnDTheme.bodyText1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          viewModel.linkedEncounter?.title ?? 'Unbenannter Encounter',
                          style: DnDTheme.bodyText2.copyWith(
                            color: DnDTheme.ancientGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildEncounterStatusBadge(
                              icon: Icons.people,
                              label: '${viewModel.linkedEncounter?.participantIds.length ?? 0} Teilnehmer',
                              color: DnDTheme.arcaneBlue,
                            ),
                            const SizedBox(width: 8),
                            _buildEncounterStatusBadge(
                              icon: _getEncounterStatusIcon(viewModel.linkedEncounter?.status?.toString() ?? 'preparation'),
                              label: _getEncounterStatusText(viewModel.linkedEncounter?.status?.toString() ?? 'preparation'),
                              color: _getEncounterStatusColor(viewModel.linkedEncounter?.status?.toString() ?? 'preparation'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Encounter entfernen
                  IconButton(
                    onPressed: () => _deleteEncounter(viewModel),
                    icon: Icon(Icons.delete, color: DnDTheme.errorRed),
                    tooltip: 'Encounter löschen',
                  ),
                ],
              ),
            ),
          ] else ...[
            // Button zum Encounter planen
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _planEncounter(viewModel),
                icon: const Icon(Icons.gavel, size: 20),
                label: const Text('Encounter planen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.errorRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: DnDTheme.md,
                    horizontal: DnDTheme.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: DnDTheme.md),
          
          // Teilnehmer-Info
          if (viewModel.linkedCharacters.isNotEmpty) ...[
            Text(
              'Verfügbare Teilnehmer:',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Wrap(
              spacing: DnDTheme.xs,
              runSpacing: DnDTheme.xs,
              children: viewModel.linkedCharacters.map((char) => 
                Chip(
                  label: Text(
                    char['name'].toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: _getCharacterColor(char['type']).withValues(alpha: 0.3),
                  side: BorderSide(
                    color: _getCharacterColor(char['type']),
                  ),
                  avatar: Icon(
                    _getCharacterIcon(char['type']),
                    color: _getCharacterColor(char['type']),
                    size: 16,
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _removeEncounter(EditSceneViewModel viewModel) {
    viewModel.updateLinkedEncounter(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Encounter von Szene entfernt'),
        backgroundColor: DnDTheme.successGreen,
      ),
    );
  }

  /// Löscht den Encounter vollständig aus der Datenbank
  void _deleteEncounter(EditSceneViewModel viewModel) async {
    // Bestätigungsdialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.warning, color: DnDTheme.errorRed),
            const SizedBox(width: DnDTheme.sm),
            Text(
              'Encounter löschen?',
              style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
            ),
          ],
        ),
        content: Text(
          'Möchtest du den Encounter "${viewModel.linkedEncounter?.title ?? "Unbenannt"}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.deleteLinkedEncounter();
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Encounter erfolgreich gelöscht'),
              ],
            ),
            backgroundColor: DnDTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Baut ein Status-Badge für den Encounter
  Widget _buildEncounterStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: DnDTheme.bodyText2.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Gibt das Icon für den Encounter-Status zurück
  IconData _getEncounterStatusIcon(String status) {
    switch (status) {
      case 'preparation':
        return Icons.schedule;
      case 'active':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'paused':
        return Icons.pause_circle;
      default:
        return Icons.help_outline;
    }
  }

  /// Gibt den Text für den Encounter-Status zurück
  String _getEncounterStatusText(String status) {
    switch (status) {
      case 'preparation':
        return 'Vorbereitung';
      case 'active':
        return 'Aktiv';
      case 'completed':
        return 'Abgeschlossen';
      case 'paused':
        return 'Pausiert';
      default:
        return 'Unbekannt';
    }
  }

  /// Gibt die Farbe für den Encounter-Status zurück
  Color _getEncounterStatusColor(String status) {
    switch (status) {
      case 'preparation':
        return DnDTheme.arcaneBlue;
      case 'active':
        return DnDTheme.errorRed;
      case 'completed':
        return DnDTheme.successGreen;
      case 'paused':
        return DnDTheme.ancientGold;
      default:
        return Colors.grey;
    }
  }

  void _planEncounter(EditSceneViewModel viewModel) async {
    // Prüfe ob Widget noch gemounted ist
    if (!mounted) return;
    
    // Navigiere zum Encounter Setup Screen
    // Da wir keine Campaign und Scene direkt haben, nutzen wir einen Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.gavel, color: DnDTheme.errorRed),
            const SizedBox(width: DnDTheme.sm),
            Text(
              'Encounter planen',
              style: DnDTheme.headline3.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du einen Encounter für diese Szene planen?',
              style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Hinweis: Speichere die Szene zuerst, bevor du den Encounter planst.',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              // Prüfe ob Widget noch gemounted ist
              if (!mounted) return;
              
              // Erst speichern falls nötig
              if (viewModel.hasUnsavedChanges || !viewModel.isEditing) {
                final saved = await viewModel.saveScene();
                if (!mounted) return;
                if (!saved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Speichern der Szene'),
                      backgroundColor: DnDTheme.errorRed,
                    ),
                  );
                  return;
                }
              }
              
              // Encounter-Dialog zeigen
              _showEncounterTitleDialog(viewModel);
            },
            icon: Icon(Icons.gavel),
            label: Text('Encounter erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEncounterTitleDialog(EditSceneViewModel viewModel) {
    // Standard-Titel ist der Szenenname (wie vom Nutzer gewünscht)
    final sceneName = viewModel.scene?.name ?? 'Kampf';
    final titleController = TextEditingController(
      text: sceneName,  // Standardwert = Szenenname
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.gavel, color: DnDTheme.errorRed),
            const SizedBox(width: DnDTheme.sm),
            Text(
              'Encounter erstellen',
              style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gib einen Namen für den Encounter ein oder verwende den Szenennamen:',
              style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: DnDTheme.md),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Encounter-Name (optional)',
                labelStyle: TextStyle(color: DnDTheme.ancientGold),
                hintText: 'Leer lassen für Szenennamen',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: DnDTheme.ancientGold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              'Hinweis: Wenn das Feld leer ist, wird "${sceneName}" verwendet.',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: DnDTheme.mysticalPurple),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // ScaffoldMessenger VOR dem Dialog-Schließen speichern
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              Navigator.pop(context);
              
              // Prüfe ob Widget noch gemounted ist
              if (!mounted) return;
              
              // Echten Encounter in der Datenbank erstellen
              final customTitle = titleController.text.trim();
              final encounter = await viewModel.createEncounterForScene(
                customTitle: customTitle.isEmpty ? null : customTitle,
              );
              
              // Prüfe erneut ob Widget noch gemounted ist
              if (!mounted) return;
              
              if (encounter != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Encounter "${encounter.title}" erfolgreich erstellt!',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: DnDTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage ?? 'Fehler beim Erstellen des Encounters',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: DnDTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
            ),
            icon: Icon(Icons.gavel),
            label: Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSoundSelector(EditSceneViewModel viewModel) async {
    // Zeige einen einfachen Dialog zur Sound-Auswahl
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Sound hinzufügen',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.successGreen),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: viewModel.availableSounds.isEmpty
              ? Center(
                  child: Text(
                    'Keine Sounds verfügbar',
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewModel.availableSounds.length,
                  itemBuilder: (context, index) {
                    final sound = viewModel.availableSounds[index];
                    final isLinked = viewModel.scene?.linkedSoundIds.contains(sound.id) ?? false;
                    return ListTile(
                      title: Text(
                        sound.name,
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      subtitle: sound.categoryId != null && sound.categoryId!.isNotEmpty
                          ? Text(
                              sound.categoryId!,
                              style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                            )
                          : null,
                      trailing: isLinked
                          ? Icon(Icons.check_circle, color: DnDTheme.successGreen)
                          : Icon(Icons.add_circle_outline, color: Colors.white54),
                      onTap: isLinked
                          ? null
                          : () {
                              Navigator.pop(context);
                              viewModel.addSound(sound.id);
                            },
                      enabled: !isLinked,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Schließen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
            ),
          ),
        ],
      ),
    );
  }
}
