import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';
import '../../../widgets/ui_components/forms/form_field_widget.dart';
import '../../../widgets/ui_components/cards/section_card_widget.dart';

/// Widget für die Währungs-Sektion in der Kreatur-Bearbeitung
class CurrencySection extends StatelessWidget {
  final double gold;
  final double silver;
  final double copper;
  final Function(double) onGoldChanged;
  final Function(double) onSilverChanged;
  final Function(double) onCopperChanged;

  const CurrencySection({
    super.key,
    required this.gold,
    required this.silver,
    required this.copper,
    required this.onGoldChanged,
    required this.onSilverChanged,
    required this.onCopperChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Währung',
      icon: Icons.monetization_on,
      child: Row(
        children: [
          Expanded(
            child: FormFieldWidget(
              label: 'Gold',
              value: gold.toStringAsFixed(2),
              onChanged: (value) {
                final goldValue = double.tryParse(value) ?? 0.0;
                onGoldChanged(goldValue);
              },
              icon: Icons.monetization_on,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: DnDTheme.md),
          Expanded(
            child: FormFieldWidget(
              label: 'Silber',
              value: silver.toStringAsFixed(2),
              onChanged: (value) {
                final silverValue = double.tryParse(value) ?? 0.0;
                onSilverChanged(silverValue);
              },
              icon: Icons.monetization_on,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: DnDTheme.md),
          Expanded(
            child: FormFieldWidget(
              label: 'Kupfer',
              value: copper.toStringAsFixed(2),
              onChanged: (value) {
                final copperValue = double.tryParse(value) ?? 0.0;
                onCopperChanged(copperValue);
              },
              icon: Icons.monetization_on,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }
}