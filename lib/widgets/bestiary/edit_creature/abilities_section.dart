import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';
import '../../../widgets/ui_components/forms/form_field_widget.dart';
import '../../../widgets/ui_components/cards/section_card_widget.dart';

/// Widget für die Fähigkeiten-Sektion in der Kreatur-Bearbeitung
class AbilitiesSection extends StatelessWidget {
  final String attacks;
  final String? specialAbilities;
  final String? legendaryActions;
  final Function(String) onAttacksChanged;
  final Function(String?) onSpecialAbilitiesChanged;
  final Function(String?) onLegendaryActionsChanged;

  const AbilitiesSection({
    super.key,
    required this.attacks,
    this.specialAbilities,
    this.legendaryActions,
    required this.onAttacksChanged,
    required this.onSpecialAbilitiesChanged,
    required this.onLegendaryActionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Angriffe & Fähigkeiten',
      icon: Icons.auto_awesome,
      child: Column(
        children: [
          FormFieldWidget(
            label: 'Angriffe',
            value: attacks,
            onChanged: onAttacksChanged,
            icon: Icons.gavel,
            maxLines: 3,
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Spezielle Fähigkeiten',
            value: specialAbilities ?? '',
            onChanged: (value) => onSpecialAbilitiesChanged(value.isEmpty ? null : value),
            icon: Icons.psychology,
            maxLines: 3,
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Legendäre Aktionen',
            value: legendaryActions ?? '',
            onChanged: (value) => onLegendaryActionsChanged(value.isEmpty ? null : value),
            icon: Icons.star,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}