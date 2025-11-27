import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/creature.dart';
import '../viewmodels/edit_creature_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Screen zur Bearbeitung von Creatures mit modernem Design
class EnhancedEditCreatureScreen extends StatefulWidget {
  final Creature? creature;

  const EnhancedEditCreatureScreen({
    Key? key,
    this.creature,
  }) : super(key: key);

  @override
  State<EnhancedEditCreatureScreen> createState() => _EnhancedEditCreatureScreenState();
}

class _EnhancedEditCreatureScreenState extends State<EnhancedEditCreatureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _subtypeController = TextEditingController();
  final _alignmentController = TextEditingController();
  final _specialAbilitiesController = TextEditingController();
  final _legendaryActionsController = TextEditingController();
  final _attacksController = TextEditingController();
  final _speedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditCreatureViewModel>().initialize(widget.creature);
      _controllersFromViewModel();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _subtypeController.dispose();
    _alignmentController.dispose();
    _specialAbilitiesController.dispose();
    _legendaryActionsController.dispose();
    _attacksController.dispose();
    _speedController.dispose();
    super.dispose();
  }

  void _controllersFromViewModel() {
    final viewModel = context.read<EditCreatureViewModel>();
    final creature = viewModel.creature;
    
    if (creature != null) {
      _nameController.text = creature!.name;
      _descriptionController.text = creature!.description ?? '';
      _typeController.text = creature!.type ?? '';
      _subtypeController.text = creature!.subtype ?? '';
      _alignmentController.text = creature!.alignment ?? '';
      _specialAbilitiesController.text = creature!.specialAbilities ?? '';
      _legendaryActionsController.text = creature!.legendaryActions ?? '';
      _attacksController.text = creature!.attacks;
      _speedController.text = creature!.speed;
    }
  }

  void _updateViewModel() {
    final viewModel = context.read<EditCreatureViewModel>();
    
    viewModel.updateName(_nameController.text);
    viewModel.updateDescription(_descriptionController.text);
    viewModel.updateType(_typeController.text.isEmpty ? null : _typeController.text);
    viewModel.updateSubtype(_subtypeController.text.isEmpty ? null : _subtypeController.text);
    viewModel.updateAlignment(_alignmentController.text.isEmpty ? null : _alignmentController.text);
    viewModel.updateSpecialAbilities(_specialAbilitiesController.text.isEmpty ? null : _specialAbilitiesController.text);
    viewModel.updateLegendaryActions(_legendaryActionsController.text.isEmpty ? null : _legendaryActionsController.text);
    viewModel.updateAttacks(_attacksController.text);
    viewModel.updateSpeed(_speedController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.creature == null ? 'Neue Creature' : 'Creature bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<EditCreatureViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: viewModel.canSave ? _saveCreature : null,
                tooltip: 'Speichern',
              );
            },
          ),
        ],
      ),
      body: Consumer<EditCreatureViewModel>(
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
                          decoration: _buildInputDecoration('Name', Icons.person),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name ist erforderlich';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration('Beschreibung', Icons.description),
                          maxLines: 3,
                          onChanged: (_) => _updateViewModel(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kreatureigenschaften
                  _buildSectionCard(
                    title: 'Kreatureigenschaften',
                    icon: Icons.category,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _typeController,
                                decoration: _buildInputDecoration('Typ', Icons.label),
                                onChanged: (_) => _updateViewModel(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _subtypeController,
                                decoration: _buildInputDecoration('Subtyp', Icons.subdirectory_arrow_right),
                                onChanged: (_) => _updateViewModel(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _alignmentController,
                          decoration: _buildInputDecoration('Ausrichtung', Icons.balance),
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _speedController,
                          decoration: _buildInputDecoration('Bewegungsrate', Icons.speed),
                          onChanged: (_) => _updateViewModel(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kampfwerte
                  _buildSectionCard(
                    title: 'Kampfwerte',
                    icon: Icons.security,
                    child: Consumer<EditCreatureViewModel>(
                      builder: (context, viewModel, child) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: viewModel.creature?.maxHp.toString(),
                                    decoration: _buildInputDecoration('Max. LP', Icons.favorite),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Max. LP ist erforderlich';
                                      final hp = int.tryParse(value);
                                      if (hp == null || hp <= 0) return 'Ungültiger Wert';
                                      return null;
                                    },
                                    onChanged: (value) {
                                      final hp = int.tryParse(value) ?? 0;
                                      viewModel.updateMaxHp(hp);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: viewModel.creature?.currentHp.toString(),
                                    decoration: _buildInputDecoration('Aktuelle LP', Icons.favorite_border),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final hp = int.tryParse(value) ?? 0;
                                      viewModel.updateCurrentHp(hp);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: viewModel.creature?.armorClass.toString(),
                              decoration: _buildInputDecoration('Rüstungsklasse', Icons.shield),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Rüstungsklasse ist erforderlich';
                                final ac = int.tryParse(value);
                                if (ac == null || ac < 0) return 'Ungültiger Wert';
                                return null;
                              },
                              onChanged: (value) {
                                final ac = int.tryParse(value) ?? 0;
                                viewModel.updateArmorClass(ac);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: viewModel.creature?.challengeRating.toString(),
                              decoration: _buildInputDecoration('Herausforderungsgrad', Icons.star),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final cr = int.tryParse(value);
                                if (cr != null) {
                                  viewModel.updateChallengeRating(cr);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Attribute
                  _buildAttributesSection(viewModel),

                  const SizedBox(height: 16),

                  // Fähigkeiten
                  _buildSectionCard(
                    title: 'Fähigkeiten',
                    icon: Icons.auto_awesome,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _attacksController,
                          decoration: _buildInputDecoration('Angriffe', Icons.gavel),
                          maxLines: 2,
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _specialAbilitiesController,
                          decoration: _buildInputDecoration('Spezielle Fähigkeiten', Icons.psychology),
                          maxLines: 3,
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _legendaryActionsController,
                          decoration: _buildInputDecoration('Legendäre Aktionen', Icons.star),
                          maxLines: 2,
                          onChanged: (_) => _updateViewModel(),
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

  Widget _buildAttributesSection(EditCreatureViewModel viewModel) {
    return _buildSectionCard(
      title: 'Attribute',
      icon: Icons.fitness_center,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildAttributeField('Stärke', 'strength', viewModel.strength)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttributeField('Geschicklichkeit', 'dexterity', viewModel.dexterity)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAttributeField('Konstitution', 'constitution', viewModel.constitution)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttributeField('Intelligenz', 'intelligence', viewModel.intelligence)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAttributeField('Weisheit', 'wisdom', viewModel.wisdom)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttributeField('Charisma', 'charisma', viewModel.charisma)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeField(String label, String attribute, int currentValue) {
    return TextFormField(
      initialValue: currentValue.toString(),
      decoration: _buildInputDecoration(label, _getAttributeIcon(attribute)),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return '$label ist erforderlich';
        final val = int.tryParse(value);
        if (val == null || val < 1 || val > 30) return 'Wert muss zwischen 1-30 liegen';
        return null;
      },
      onChanged: (value) {
        final val = int.tryParse(value) ?? 10;
        switch (attribute) {
          case 'strength':
            context.read<EditCreatureViewModel>().updateStrength(val);
            break;
          case 'dexterity':
            context.read<EditCreatureViewModel>().updateDexterity(val);
            break;
          case 'constitution':
            context.read<EditCreatureViewModel>().updateConstitution(val);
            break;
          case 'intelligence':
            context.read<EditCreatureViewModel>().updateIntelligence(val);
            break;
          case 'wisdom':
            context.read<EditCreatureViewModel>().updateWisdom(val);
            break;
          case 'charisma':
            context.read<EditCreatureViewModel>().updateCharisma(val);
            break;
        }
      },
    );
  }

  IconData _getAttributeIcon(String attribute) {
    switch (attribute) {
      case 'strength':
        return Icons.fitness_center;
      case 'dexterity':
        return Icons.directions_run;
      case 'constitution':
        return Icons.favorite;
      case 'intelligence':
        return Icons.psychology;
      case 'wisdom':
        return Icons.lightbulb;
      case 'charisma':
        return Icons.people;
      default:
        return Icons.help_outline;
    }
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

  Widget _buildActionButtons(EditCreatureViewModel viewModel) {
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
            onPressed: viewModel.canSave ? _saveCreature : null,
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
              onPressed: _duplicateCreature,
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

  Future<void> _saveCreature() async {
    final viewModel = context.read<EditCreatureViewModel>();
    
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.saveCreature();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creature erfolgreich gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _duplicateCreature() async {
    final viewModel = context.read<EditCreatureViewModel>();
    await viewModel.duplicateCreature();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creature dupliziert'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
