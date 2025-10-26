import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/attack.dart';

class AttackEditorWidget extends StatefulWidget {
  final Attack? attack;
  final Function(Attack) onSave;
  final VoidCallback? onCancel;

  const AttackEditorWidget({
    super.key,
    this.attack,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<AttackEditorWidget> createState() => _AttackEditorWidgetState();
}

class _AttackEditorWidgetState extends State<AttackEditorWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _attackBonusController;
  late TextEditingController _damageDiceController;
  late TextEditingController _damageBonusController;
  late TextEditingController _descriptionController;
  late String _selectedDamageType;
  late String? _selectedRange;
  late String? _selectedAbility;
  late bool _isProficient;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final attack = widget.attack;
    
    _nameController = TextEditingController(text: attack?.name ?? '');
    _attackBonusController = TextEditingController(
      text: attack?.attackBonus.toString() ?? '0',
    );
    _damageDiceController = TextEditingController(
      text: attack?.damageDice ?? '1W6',
    );
    _damageBonusController = TextEditingController(
      text: attack?.damageBonus.toString() ?? '0',
    );
    _descriptionController = TextEditingController(
      text: attack?.description ?? '',
    );
    _selectedDamageType = attack?.damageType ?? AttackHelper.commonDamageTypes.first;
    _selectedRange = attack?.range;
    _selectedAbility = attack?.abilityUsed;
    _isProficient = attack?.isProficient ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attackBonusController.dispose();
    _damageDiceController.dispose();
    _damageBonusController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveAttack() {
    if (_formKey.currentState?.validate() == true) {
      final attack = Attack(
        id: widget.attack?.id,
        name: _nameController.text.trim(),
        attackBonus: int.tryParse(_attackBonusController.text) ?? 0,
        damageDice: _damageDiceController.text.trim(),
        damageBonus: int.tryParse(_damageBonusController.text) ?? 0,
        damageType: _selectedDamageType,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        range: _selectedRange?.trim().isEmpty == true ? null : _selectedRange?.trim(),
        abilityUsed: _selectedAbility?.trim().isEmpty == true ? null : _selectedAbility?.trim(),
        isProficient: _isProficient,
      );

      widget.onSave(attack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.gavel, size: 24, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.attack == null ? 'Neuer Angriff' : 'Angriff bearbeiten',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Angriffsname *',
                hintText: 'z.B. Schwerthieb, Feuerball, Biss',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Der Angriffsname ist erforderlich';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Erste Zeile: Angriffsbonus und Würfel
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _attackBonusController,
                    decoration: const InputDecoration(
                      labelText: 'Angriffsbonus',
                      hintText: '+4',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gavel),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[+-]?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _damageDiceController,
                    decoration: const InputDecoration(
                      labelText: 'Schadenswürfel',
                      hintText: '1W8',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.casino),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Schadenswürfel ist erforderlich';
                      }
                      if (!RegExp(r'^\d+W\d+$').hasMatch(value.trim())) {
                        return 'Format: AnzahlWSeite (z.B. 2W6, 1W12)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Zweite Zeile: Schadensbonus und Schadensart
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _damageBonusController,
                    decoration: const InputDecoration(
                      labelText: 'Schadensbonus',
                      hintText: '+2',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add_circle),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[+-]?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDamageType,
                    decoration: const InputDecoration(
                      labelText: 'Schadensart',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_fire_department),
                    ),
                    items: AttackHelper.commonDamageTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDamageType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Dritte Zeile: Reichweite und Fähigkeit
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRange,
                    decoration: const InputDecoration(
                      labelText: 'Reichweite',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.my_location),
                      hintText: 'Optional',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Keine Reichweite'),
                      ),
                      ...AttackHelper.commonRanges.map((range) {
                        return DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRange = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAbility,
                    decoration: const InputDecoration(
                      labelText: 'Fähigkeit',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                      hintText: 'Optional',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Keine Fähigkeit'),
                      ),
                      ...AttackHelper.abilities.map((ability) {
                        return DropdownMenuItem(
                          value: ability,
                          child: Text(ability),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAbility = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Proficiency Checkbox
            Row(
              children: [
                Checkbox(
                  value: _isProficient,
                  onChanged: (value) {
                    setState(() {
                      _isProficient = value ?? false;
                    });
                  },
                ),
                const Text(
                  'Proficient mit diesem Angriff',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Beschreibung
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Zusätzliche Informationen zum Angriff...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            
            const SizedBox(height: 20),
            
            // Vorschau
            if (_nameController.text.trim().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vorschau:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAttackPreview(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveAttack,
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getAttackPreview() {
    final name = _nameController.text.trim();
    final attackBonus = int.tryParse(_attackBonusController.text) ?? 0;
    final damageDice = _damageDiceController.text.trim();
    final damageBonus = int.tryParse(_damageBonusController.text) ?? 0;
    final damageType = _selectedDamageType;
    
    final bonus = attackBonus >= 0 ? '+$attackBonus' : '$attackBonus';
    final totalDamage = damageBonus != 0 ? '$damageDice+$damageBonus' : damageDice;
    
    return '$name: $bonus ($totalDamage) $damageType';
  }
}

// Dialog-Wrapper für einfachere Verwendung
class AttackEditorDialog extends StatelessWidget {
  final Attack? attack;
  final Function(Attack) onSave;

  const AttackEditorDialog({
    super.key,
    this.attack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: AttackEditorWidget(
          attack: attack,
          onSave: (attack) {
            Navigator.of(context).pop();
            onSave(attack);
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// Bottom Sheet Version für mobile
class AttackEditorBottomSheet extends StatelessWidget {
  final Attack? attack;
  final Function(Attack) onSave;

  const AttackEditorBottomSheet({
    super.key,
    this.attack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: AttackEditorWidget(
              attack: attack,
              onSave: (attack) {
                Navigator.of(context).pop();
                onSave(attack);
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }
}
