import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/dnd_theme.dart';
import '../../../widgets/ui_components/forms/form_field_widget.dart';
import '../../../widgets/ui_components/cards/section_card_widget.dart';

/// Widget für die Kampfwerte-Sektion in der Kreatur-Bearbeitung
class CombatStatsSection extends StatelessWidget {
  final int maxHp;
  final int armorClass;
  final int challengeRating;
  final Function(int) onMaxHpChanged;
  final Function(int) onArmorClassChanged;
  final Function(int) onChallengeRatingChanged;

  const CombatStatsSection({
    super.key,
    required this.maxHp,
    required this.armorClass,
    required this.challengeRating,
    required this.onMaxHpChanged,
    required this.onArmorClassChanged,
    required this.onChallengeRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Kampfwerte',
      icon: Icons.security,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  label: 'Max. HP',
                  value: maxHp.toString(),
                  onChanged: (value) {
                    final hp = int.tryParse(value) ?? 10;
                    onMaxHpChanged(hp);
                  },
                  icon: Icons.favorite,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: DnDTheme.md),
              Expanded(
                child: FormFieldWidget(
                  label: 'RK',
                  value: armorClass.toString(),
                  onChanged: (value) {
                    final ac = int.tryParse(value) ?? 10;
                    onArmorClassChanged(ac);
                  },
                  icon: Icons.security,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Challenge Rating',
            value: challengeRating.toString(),
            onChanged: (value) {
              final cr = int.tryParse(value) ?? 1;
              onChallengeRatingChanged(cr);
            },
            icon: Icons.star,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}