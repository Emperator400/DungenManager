import 'package:flutter/material.dart';
import '../../models/attack.dart';
import 'attack_list_widget.dart';

class AttacksTabWidget extends StatefulWidget {
  final List<Attack> attacks;
  final void Function(List<Attack>) onAttacksChanged;
  final bool isEditable;
  
  const AttacksTabWidget({
    super.key,
    required this.attacks,
    required this.onAttacksChanged,
    this.isEditable = true,
  });

  @override
  State<AttacksTabWidget> createState() => _AttacksTabWidgetState();
}

class _AttacksTabWidgetState extends State<AttacksTabWidget> {
  bool _showCompactMode = false;
  late List<Attack> _attacks;

  @override
  void initState() {
    super.initState();
    _attacks = List.from(widget.attacks);
  }

  @override
  void didUpdateWidget(AttacksTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attacks != widget.attacks) {
      setState(() {
        _attacks = List.from(widget.attacks);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header mit Titel und Ansichts-Optionen
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.gavel, size: 28, color: Colors.red),
              const SizedBox(width: 12),
              const Text(
                'Angriffe & Aktionen',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (widget.isEditable) ...[
                // Ansicht wechseln Button
                IconButton(
                  icon: Icon(
                    _showCompactMode ? Icons.view_list : Icons.view_module,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCompactMode = !_showCompactMode;
                    });
                  },
                  tooltip: _showCompactMode ? 'Detaillierte Ansicht' : 'Kompakte Ansicht',
                ),
                // Hilfe Button
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.grey),
                  onPressed: () => _showHelpDialog(),
                  tooltip: 'Hilfe zu Angriffen',
                ),
              ],
            ],
          ),
        ),
        
        // Hauptinhalt
        Expanded(
          child: AttackListWidget(
            attacks: _attacks,
            onAttacksChanged: (attacks) {
              setState(() {
                _attacks = attacks;
              });
              widget.onAttacksChanged(attacks);
            },
            isEditable: widget.isEditable,
            showCompactMode: _showCompactMode,
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Angriffe & Aktionen Hilfe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Strukturierte Angriffe:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Das neue System ermöglicht detaillierte Verwaltung von Angriffen mit:\n'
                '• Angriffsname\n'
                '• Angriffsbonus (automatisch berechenbar)\n'
                '• Schadenswürfel (z.B. 1W8, 2W6)\n'
                '• Schadensbonus\n'
                '• Schadensart (Feuer, Hiebschaden, etc.)\n'
                '• Reichweite (optional)\n'
                '• Genutzte Fähigkeit (STR, DEX, etc.)\n'
                '• Proficiency-Status',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              
              Text(
                'Vorteile gegenüber altem System:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Automatische Validierung der Eingaben\n'
                '• Bessere Übersichtlichkeit\n'
                '• Berechnung von Gesamtbonus möglich\n'
                '• Filter und Sortierung\n'
                '• Import/Export möglich',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              
              Text(
                'Abwärtskompatibilität:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Alte Angriffsformate werden automatisch erkannt und können importiert werden.\n'
                'Format: "Schwerthieb: +4 (1W8+2) Hiebschaden"',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              
              Text(
                'Tipps:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Nutze den Import für bestehende Angriffe\n'
                '• Setze Proficiency für Fertigkeitsboni\n'
                '• Wähle die passende Fähigkeit für automatische Boni\n'
                '• Nutze die Beschreibung für Spezialeffekte',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }
}
