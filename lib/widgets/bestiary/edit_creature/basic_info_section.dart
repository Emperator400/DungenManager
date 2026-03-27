import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';
import '../../../widgets/ui_components/forms/form_field_widget.dart';
import '../../../widgets/ui_components/cards/section_card_widget.dart';

/// Widget für die Grundinformationen-Sektion in der Kreatur-Bearbeitung
class BasicInfoSection extends StatelessWidget {
  final String name;
  final String? description;
  final String speed;
  final Function(String) onNameChanged;
  final Function(String) onDescriptionChanged;
  final Function(String) onSpeedChanged;

  const BasicInfoSection({
    super.key,
    required this.name,
    this.description,
    required this.speed,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Grundinformationen',
      icon: Icons.info_outline,
      child: Column(
        children: [
          FormFieldWidget(
            label: 'Name',
            value: name,
            onChanged: onNameChanged,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name ist erforderlich';
              }
              return null;
            },
            icon: Icons.pets,
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Beschreibung',
            value: description ?? '',
            onChanged: onDescriptionChanged,
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Geschwindigkeit',
            value: speed,
            onChanged: onSpeedChanged,
            icon: Icons.speed,
          ),
        ],
      ),
    );
  }
}