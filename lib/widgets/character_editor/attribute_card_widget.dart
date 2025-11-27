import 'package:flutter/material.dart';
import '../../game_data/dnd_logic.dart';

class AttributeCardWidget extends StatelessWidget {
  final String name;
  final TextEditingController controller;
  final Color color;
  final String description;
  final void Function(String name, TextEditingController controller, Color color) onQuickEdit;
  final void Function(TextEditingController controller, int adjustment) onAdjustAttribute;

  const AttributeCardWidget({
    super.key,
    required this.name,
    required this.controller,
    required this.color,
    required this.description,
    required this.onQuickEdit,
    required this.onAdjustAttribute,
  });

  @override
  Widget build(BuildContext context) {
    final value = int.tryParse(controller.text) ?? 10;
    final modifier = getModifier(value);
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    // Bestimme die Qualität des Attributwerts für visuelle Rückmeldung
    Color cardColor = color.withAlpha(40);
    Color borderColor = color.withOpacity(0.6);
    double elevation = 2.0;
    
    if (value >= 18) {
      borderColor = color.withOpacity(0.9);
      elevation = 4.0;
    } else if (value >= 14) {
      borderColor = color.withOpacity(0.7);
      elevation = 3.0;
    } else if (value <= 8) {
      borderColor = Colors.red.withOpacity(0.6);
      elevation = 1.5;
    }
    
    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () => onQuickEdit(name, controller, color),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header mit Icon und Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _getAttributeIcon(name),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getAttributeShortDescription(name),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Wert-Display mit visuellem Feedback
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _getValueColor(value),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        modifierText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Quick-Buttons mit verbessertem Design
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactQuickButton(
                    Icons.remove, 
                    () => onAdjustAttribute(controller, -1),
                    color: Colors.red,
                  ),
                  _buildCompactQuickButton(
                    Icons.add, 
                    () => onAdjustAttribute(controller, 1),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getAttributeIcon(String name) {
    switch (name.toLowerCase()) {
      case 'stärke':
        return const Icon(Icons.fitness_center, color: Colors.white, size: 16);
      case 'geschicklichkeit':
        return const Icon(Icons.flash_on, color: Colors.white, size: 16);
      case 'konstitution':
        return const Icon(Icons.shield, color: Colors.white, size: 16);
      case 'intelligenz':
        return const Icon(Icons.psychology, color: Colors.white, size: 16);
      case 'weisheit':
        return const Icon(Icons.visibility, color: Colors.white, size: 16);
      case 'charisma':
        return const Icon(Icons.star, color: Colors.white, size: 16);
      default:
        return const Icon(Icons.help, color: Colors.white, size: 16);
    }
  }

  String _getAttributeShortDescription(String name) {
    switch (name.toLowerCase()) {
      case 'stärke':
        return 'Muskelkraft';
      case 'geschicklichkeit':
        return 'Reflexe & Geschick';
      case 'konstitution':
        return 'Ausdauer';
      case 'intelligenz':
        return 'Wissen';
      case 'weisheit':
        return 'Wahrnehmung';
      case 'charisma':
        return 'Persönlichkeit';
      default:
        return '';
    }
  }

  Color _getValueColor(int value) {
    if (value >= 18) return Colors.green[700]!;
    if (value >= 16) return Colors.green[600]!;
    if (value >= 14) return Colors.green[500]!;
    if (value >= 12) return Colors.white;
    if (value >= 10) return Colors.white;
    if (value >= 8) return Colors.orange[600]!;
    if (value >= 6) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Widget _buildCompactQuickButton(IconData icon, VoidCallback onPressed, {required Color color}) {
    return Container(
      width: 32,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
