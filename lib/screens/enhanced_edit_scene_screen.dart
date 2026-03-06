import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scene.dart';
import '../viewmodels/edit_scene_viewmodel.dart';
import '../theme/dnd_theme.dart';
import 'select_character_for_scene_screen.dart';

/// Enhanced Screen zur Bearbeitung von Scenes mit modernem Design
class EnhancedEditSceneScreen extends StatefulWidget {
  final Scene? scene;

  const EnhancedEditSceneScreen({
    Key? key,
    this.scene,
  }) : super(key: key);

  @override
  State<EnhancedEditSceneScreen> createState() => _EnhancedEditSceneScreenState();
}

class _EnhancedEditSceneScreenState extends State<EnhancedEditSceneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditSceneViewModel>().initialize(widget.scene);
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
      appBar: AppBar(
        title: Text(
          widget.scene == null ? 'Neue Scene' : 'Scene bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<EditSceneViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: viewModel.canSave ? _saveScene : null,
                tooltip: 'Speichern',
              );
            },
          ),
        ],
      ),
      body: Consumer<EditSceneViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator(color: DnDTheme.mysticalPurple));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fehlermeldung
                  if (viewModel.errorMessage != null)
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
                              viewModel.errorMessage!,
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
                        const SizedBox(height: 12),
                        Consumer<EditSceneViewModel>(
                          builder: (context, viewModel, child) {
                            return DropdownButtonFormField<SceneType>(
                              value: viewModel.scene?.sceneType ?? SceneType.Exploration,
                              decoration: _buildInputDecoration('Szenen-Typ', Icons.category),
                              items: SceneType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                );
                              }).toList(),
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

                  const SizedBox(height: 16),

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

                  const SizedBox(height: 16),

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
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Keine Charaktere verknüpft',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ...viewModel.linkedCharacters.map((char) => Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getCharacterColor(char['type']),
                                    child: Icon(
                                      _getCharacterIcon(char['type']),
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(char['name'].toString()),
                                  subtitle: Text(_getCharacterSubtitle(char)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _removeCharacter(char['id'].toString()),
                                  ),
                                ),
                              )),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showCharacterSelector(viewModel),
                              icon: Icon(Icons.add),
                              label: Text('Charakter hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DnDTheme.mysticalPurple,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: DnDTheme.mysticalPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: DnDTheme.mysticalPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildActionButtons(EditSceneViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text('Abbrechen'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.canSave ? _saveScene : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.mysticalPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Speichern',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (viewModel.isEditing)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _duplicateScene,
              icon: Icon(Icons.copy, color: Colors.white),
              label: Text('Duplizieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          content: Text('Scene erfolgreich gespeichert'),
          backgroundColor: Colors.green,
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
        content: Text('Scene dupliziert'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Hilfsmethoden für Charaktere
  Color _getCharacterColor(dynamic type) {
    final typeStr = type.toString();
    switch (typeStr) {
      case 'PC':
        return Colors.green;
      case 'NPC':
        return Colors.blue;
      case 'Monster':
        return Colors.red;
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCharacterForSceneScreen(
          previouslySelectedIds: viewModel.scene?.linkedCharacterIds ?? [],
        ),
      ),
    );

    if (result != null && result is List<String>) {
      viewModel.updateLinkedCharacters(result);
      await viewModel.buildLinkedCharactersList();
    }
  }
}
