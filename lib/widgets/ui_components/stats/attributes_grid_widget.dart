import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class AttributesGridWidget extends StatelessWidget {
  const AttributesGridWidget({
    required this.attributes,
    required this.onAttributeChanged,
    super.key,
    this.isEditable = true,
    this.modifiers,
    this.showModifiers = false,
  });

  final Map<String, int> attributes;
  final void Function(String attribute, int value) onAttributeChanged;
  final bool isEditable;
  final Map<String, int?>? modifiers;
  final bool showModifiers;

  @override
  Widget build(BuildContext context) => GridView.builder(
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
          final name = attributes.keys.elementAt(index);
          return _buildAttributeCard(context, name);
        },
      );

  Widget _buildAttributeCard(BuildContext context, String name) {
    final C = context.appColors;
    final value = attributes[name] ?? 10;
    final modifier = showModifiers ? ((value - 10) / 2).floor() : null;
    final displayModifier = modifiers?[name] ?? modifier;

    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: C.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(_attributeIcon(name), color: C.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isEditable
                  ? _buildEditableField(name, value, C)
                  : _buildDisplayField(name, value, displayModifier, C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String name, int value, AppColorsExtension C) => TextField(
        key: ValueKey('${name}_field'),
        controller: TextEditingController(text: value.toString()),
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.text),
        decoration: InputDecoration(
          labelText: _attributeLabel(name),
          labelStyle: TextStyle(color: C.textSoft, fontSize: 12),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v) ?? 10;
          onAttributeChanged(name, parsed.clamp(1, 30));
        },
      );

  Widget _buildDisplayField(String name, int value, int? modifier, AppColorsExtension C) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_attributeLabel(name), style: TextStyle(color: C.textSoft, fontSize: 12)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.text)),
              if (modifier != null) ...[
                const SizedBox(width: 8),
                _buildModifierBadge(modifier, C),
              ],
            ],
          ),
        ],
      );

  Widget _buildModifierBadge(int modifier, AppColorsExtension C) {
    final text = modifier >= 0 ? '+$modifier' : modifier.toString();
    final color = modifier >= 0 ? C.green : C.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  IconData _attributeIcon(String attribute) {
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

  String _attributeLabel(String attribute) {
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
}
