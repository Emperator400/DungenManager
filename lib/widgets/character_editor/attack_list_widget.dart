import 'package:flutter/material.dart';
import '../../models/attack.dart';
import '../../utils/attack_helper.dart';
import 'attack_card_widget.dart';
import 'attack_editor_widget.dart';

class AttackListWidget extends StatefulWidget {
  final List<Attack> attacks;
  final void Function(List<Attack>) onAttacksChanged;
  final bool isEditable;
  final bool showCompactMode;

  const AttackListWidget({
    super.key,
    required this.attacks,
    required this.onAttacksChanged,
    this.isEditable = true,
    this.showCompactMode = false,
  });

  @override
  State<AttackListWidget> createState() => _AttackListWidgetState();
}

class _AttackListWidgetState extends State<AttackListWidget> {
  late List<Attack> _attacks;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _attacks = List.from(widget.attacks);
  }

  @override
  void didUpdateWidget(AttackListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attacks != widget.attacks) {
      setState(() {
        _attacks = List.from(widget.attacks);
      });
    }
  }

  Future<void> _addAttack() async {
    final result = await showDialog<Attack>(
      context: context,
      builder: (context) => AttackEditorDialog(
        onSave: (attack) => attack,
      ),
    );

    if (result != null) {
      setState(() {
        _attacks.add(result);
      });
      widget.onAttacksChanged(_attacks);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angriff hinzugefügt')),
        );
      }
    }
  }

  Future<void> _editAttack(Attack attack) async {
    final result = await showDialog<Attack>(
      context: context,
      builder: (context) => AttackEditorDialog(
        attack: attack,
        onSave: (attack) => attack,
      ),
    );

    if (result != null) {
      setState(() {
        final index = _attacks.indexWhere((a) => a.id == attack.id);
        if (index != -1) {
          _attacks[index] = result;
        }
      });
      widget.onAttacksChanged(_attacks);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angriff aktualisiert')),
        );
      }
    }
  }

  Future<void> _deleteAttack(Attack attack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Angriff löschen'),
        content: Text('Möchtest du den Angriff "${attack.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _attacks.removeWhere((a) => a.id == attack.id);
      });
      widget.onAttacksChanged(_attacks);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angriff gelöscht')),
        );
      }
    }
  }


  Future<void> _importFromLegacy() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Angriffe importieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Füge hier Angriffe im alten Format ein:\n'
              'Format: "Name: +Bonus (Schaden) Art"',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Schwerthieb: +4 (1W8+2) Hiebschaden',
              ),
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final parsedAttacks = AttackHelper.parseAttacksFromString(result);
        setState(() {
          _attacks.addAll(parsedAttacks);
          _isLoading = false;
        });
        widget.onAttacksChanged(_attacks);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${parsedAttacks.length} Angriffe importiert')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Importieren: $e')),
          );
        }
      }
    }
  }

  void _showAttackDetails(Attack attack) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel, size: 24, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        attack.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                AttackCardWidget(
                  attack: attack,
                  showEditButton: false,
                  showDeleteButton: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attacks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header mit Aktionen
        if (widget.isEditable) ...[
          Row(
            children: [
              Text(
                '${_attacks.length} Angriff${_attacks.length == 1 ? '' : 'e'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'add':
                      _addAttack();
                      break;
                    case 'import':
                      _importFromLegacy();
                      break;
                    case 'clear':
                      _clearAllAttacks();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Neuer Angriff'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.upload_file),
                        SizedBox(width: 8),
                        Text('Aus Text importieren'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Alle löschen', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // Angriffsliste
        Expanded(
          child: widget.showCompactMode
              ? _buildCompactList()
              : _buildDetailedList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Angriffe vorhanden',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isEditable
                ? 'Füge Angriffe hinzu, um die Kampffähigkeiten zu definieren.'
                : 'Für diesen Charakter wurden keine Angriffe definiert.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.isEditable) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addAttack,
              icon: const Icon(Icons.add),
              label: const Text('Ersten Angriff hinzufügen'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _importFromLegacy,
              icon: const Icon(Icons.upload_file),
              label: const Text('Aus Text importieren'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedList() {
    return ListView.builder(
      itemCount: _attacks.length,
      itemBuilder: (context, index) {
        final attack = _attacks[index];
        return AttackCardWidget(
          attack: attack,
          onTap: () => _showAttackDetails(attack),
          onEdit: widget.isEditable ? () => _editAttack(attack) : null,
          onDelete: widget.isEditable ? () => _deleteAttack(attack) : null,
        );
      },
    );
  }

  Widget _buildCompactList() {
    return ListView.builder(
      itemCount: _attacks.length,
      itemBuilder: (context, index) {
        final attack = _attacks[index];
        return CompactAttackCardWidget(
          attack: attack,
          onTap: () => _showAttackDetails(attack),
          onEdit: widget.isEditable ? () => _editAttack(attack) : null,
          onDelete: widget.isEditable ? () => _deleteAttack(attack) : null,
        );
      },
    );
  }

  Future<void> _clearAllAttacks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Angriffe löschen'),
        content: const Text(
          'Möchtest du wirklich alle Angriffe löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Alle löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _attacks.clear();
      });
      widget.onAttacksChanged(_attacks);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alle Angriffe gelöscht')),
        );
      }
    }
  }
}
