import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scene.dart';
import '../../viewmodels/edit_scene_viewmodel.dart';
import '../../theme/dnd_theme.dart';
// import 'select_character_for_scene_screen.dart'; // Datei existiert nicht noch

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

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditSceneViewModel>().initialize(
        widget.scene,
        sessionId: widget.sessionId,
      );
      _controllersFromViewModel();
    });
  }

  @override
  void dispose() {
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

  Future<void> _removeCharacter(String characterId) async {
    final viewModel = context.read<EditSceneViewModel>();
    await viewModel.removeCharacter(characterId);
  }

  Future<void> _showCharacterSelector(EditSceneViewModel viewModel) async {
    // TODO: SelectCharacterForSceneScreen implementieren
    // Diese Funktion wird in Zukunft verfügbar sein
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            const SizedBox(width: DnDTheme.sm),
            Text(
              'Charakterauswahl wird in Zukunft verfügbar sein',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: DnDTheme.arcaneBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        ),
      ),
    );
  }
}