import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbares Widget für D&D 5e Attribute (STR, DEX, CON, INT, WIS, CHA)
/// 
/// Beispiele:
/// ```dart
/// AttributesGridWidget(
///   attributes: {
///     'strength': viewModel.strength,
///     'dexterity': viewModel.dexterity,
///     'constitution': viewModel.constitution,
///     'intelligence': viewModel.intelligence,
///     'wisdom': viewModel.wisdom,
///     'charisma': viewModel.charisma,
///   },
///   onAttributeChanged: (attribute, value) {
///     // Handle Attribut-Änderung
///   },
///   isEditable: true,
/// )
/// ```
class AttributesGridWidget extends StatelessWidget {
  final Map<String, int> attributes;
  final Function(String attribute, int value) onAttributeChanged;
  final bool isEditable;
  final Map<String, int?>? modifiers;
  final bool showModifiers;

  const AttributesGridWidget({
    Key? key,
    required this.attributes,
    required this.onAttributeChanged,
    this.isEditable = true,
    this.modifiers,
    this.showModifiers = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: attributes.length,
      itemBuilder: (context, index) {
        final attributeName = attributes.keys.elementAt(index);
        return _buildAttributeCard(context, attributeName);
      },
    );
  }

  Widget _buildAttributeCard(BuildContext context, String attributeName) {
    final value = attributes[attributeName] ?? 10;
    final modifier = showModifiers ? _calculateModifier(value) : null;
    final displayModifier = modifiers?[attributeName] ?? modifier;

    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              ),
              child: Icon(
                _getAttributeIcon(attributeName),
                color: DnDTheme.ancientGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Attribut-Wert
            Expanded(
              child: isEditable
                  ? _buildEditableField(attributeName, value)
                  : _buildDisplayField(attributeName, value, displayModifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String attributeName, int value) {
    return TextField(
      key: ValueKey('${attributeName}_field'),
      controller: TextEditingController(text: value.toString()),
      keyboardType: TextInputType.number,
      style: DnDTheme.bodyText1.copyWith(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: _getAttributeLabel(attributeName),
        labelStyle: DnDTheme.bodyText2.copyWith(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (newValue) {
        final parsedValue = int.tryParse(newValue) ?? 10;
        onAttributeChanged(attributeName, parsedValue.clamp(1, 30));
      },
    );
  }

  Widget _buildDisplayField(String attributeName, int value, int? modifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getAttributeLabel(attributeName),
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              value.toString(),
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (modifier != null) ...[
              const SizedBox(width: 8),
              _buildModifierBadge(modifier),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildModifierBadge(int modifier) {
    final modifierText = modifier >= 0 ? '+$modifier' : modifier.toString();
    final color = modifier >= 0 ? DnDTheme.successGreen : DnDTheme.errorRed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        modifierText,
        style: DnDTheme.bodyText2.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  String _getAttributeLabel(String attribute) {
    switch (attribute) {
      case 'strength':
        return 'Stärke';
      case 'dexterity':
        return 'Geschicklichkeit';
      case 'constitution':
        return 'Konstitution';
      case 'intelligence':
        return 'Intelligenz';
      case 'wisdom':
        return 'Weisheit';
      case 'charisma':
        return 'Charisma';
      default:
        return attribute;
    }
  }

  /// Berechnet den Modifikator für einen Attributwert
  /// D&D 5e Regel: (Wert - 10) / 2, abgerundet
  int _calculateModifier(int value) {
    return ((value - 10) / 2).floor();
  }
}
