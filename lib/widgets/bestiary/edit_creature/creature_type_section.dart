import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';
import '../../../widgets/ui_components/forms/form_field_widget.dart';
import '../../../widgets/ui_components/cards/section_card_widget.dart';
import 'creature_category_enum.dart';

/// Widget für die Kreaturentyp-Sektion in der Kreatur-Bearbeitung
class CreatureTypeSection extends StatelessWidget {
  final String? type;
  final String? subtype;
  final String? size;
  final String? alignment;
  final Function(String?) onTypeChanged;
  final Function(String?) onSubtypeChanged;
  final Function(String?) onSizeChanged;
  final Function(String?) onAlignmentChanged;

  const CreatureTypeSection({
    super.key,
    this.type,
    this.subtype,
    this.size,
    this.alignment,
    required this.onTypeChanged,
    required this.onSubtypeChanged,
    required this.onSizeChanged,
    required this.onAlignmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Finde den aktuellen Kreaturentyp
    CreatureCategory? selectedCategory;
    if (type != null && type!.isNotEmpty) {
      final typeLower = type!.toLowerCase();
      try {
        selectedCategory = CreatureCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == typeLower || c.displayName.toLowerCase() == typeLower,
        );
      } catch (_) {
        // Typ nicht gefunden, bleibt null
      }
    }

    return SectionCardWidget(
      title: 'Kreatureigenschaften',
      icon: Icons.category,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kreaturentyp-Dropdown
          Text(
            'Kreaturentyp',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: DnDTheme.slateGrey,
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            ),
            child: DropdownButtonFormField<CreatureCategory?>(
              value: selectedCategory,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  selectedCategory?.icon ?? Icons.category,
                  color: DnDTheme.ancientGold,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: 'Typ auswählen...',
                hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white60),
              ),
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              dropdownColor: DnDTheme.stoneGrey,
              items: [
                DropdownMenuItem<CreatureCategory?>(
                  value: null,
                  child: Text(
                    'Kein Typ ausgewählt',
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white60),
                  ),
                ),
                ...CreatureCategory.values.map((category) {
                  final isNpc = category == CreatureCategory.humanoid;
                  return DropdownMenuItem<CreatureCategory?>(
                    value: category,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          color: isNpc ? DnDTheme.arcaneBlue : DnDTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category.displayName,
                                style: DnDTheme.bodyText1.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                category.description,
                                style: DnDTheme.bodyText2.copyWith(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isNpc ? DnDTheme.arcaneBlue : DnDTheme.errorRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isNpc ? 'NPC' : 'Monster',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (category) {
                if (category != null) {
                  onTypeChanged(category.displayName);
                } else {
                  onTypeChanged(null);
                }
              },
            ),
          ),
          const SizedBox(height: DnDTheme.md),
          
          // Info-Text
          if (selectedCategory != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selectedCategory == CreatureCategory.humanoid 
                    ? DnDTheme.arcaneBlue 
                    : DnDTheme.errorRed).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedCategory == CreatureCategory.humanoid 
                      ? DnDTheme.arcaneBlue 
                      : DnDTheme.errorRed,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedCategory == CreatureCategory.humanoid 
                        ? Icons.person 
                        : Icons.pets,
                    color: selectedCategory == CreatureCategory.humanoid 
                        ? DnDTheme.arcaneBlue 
                        : DnDTheme.errorRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCategory == CreatureCategory.humanoid
                          ? 'Wird im NPC-Tab der Szenen-Auswahl angezeigt'
                          : 'Wird im Monster-Tab der Szenen-Auswahl angezeigt',
                      style: DnDTheme.bodyText2.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DnDTheme.md),
          
          // Restliche Felder
          FormFieldWidget(
            label: 'Subtyp',
            value: subtype ?? '',
            onChanged: (value) => onSubtypeChanged(value.isEmpty ? null : value),
            icon: Icons.layers,
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Größe',
            value: size ?? '',
            onChanged: onSizeChanged,
            icon: Icons.straighten,
          ),
          const SizedBox(height: DnDTheme.md),
          FormFieldWidget(
            label: 'Ausrichtung',
            value: alignment ?? '',
            onChanged: onAlignmentChanged,
            icon: Icons.compass_calibration,
          ),
        ],
      ),
    );
  }
}