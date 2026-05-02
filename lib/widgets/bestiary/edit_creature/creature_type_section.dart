import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
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
    final C = context.appColors;
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
            style: TextStyle(
              fontSize: 12,
              color: C.textMid,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: C.bgPanel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<CreatureCategory?>(
              value: selectedCategory,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  selectedCategory?.icon ?? Icons.category,
                  color: C.amber,
                  size: 32,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: 'Typ auswählen...',
                hintStyle: TextStyle(fontSize: 12, color: C.textMid),
              ),
              style: TextStyle(fontSize: 14, color: C.text),
              dropdownColor: C.bg,
              selectedItemBuilder: (context) => [
                Text(
                  'Kein Typ ausgewählt',
                  style: TextStyle(fontSize: 12, color: C.textMid),
                ),
                ...CreatureCategory.values.map((category) => Text(
                  category.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: C.text,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
              items: [
                DropdownMenuItem<CreatureCategory?>(
                  value: null,
                  child: Text(
                    'Kein Typ ausgewählt',
                    style: TextStyle(fontSize: 12, color: C.textMid),
                  ),
                ),
                ...CreatureCategory.values.map((category) {
                  final isNpc = category == CreatureCategory.humanoid;
                  return DropdownMenuItem<CreatureCategory?>(
                    value: category,
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: C.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                category.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: C.textMid,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isNpc ? C.accent : C.red,
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
          const SizedBox(height: 16),

          // Info-Text
          if (selectedCategory != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selectedCategory == CreatureCategory.humanoid
                    ? C.accent
                    : C.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedCategory == CreatureCategory.humanoid
                      ? C.accent
                      : C.red,
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
                        ? C.accent
                        : C.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCategory == CreatureCategory.humanoid
                          ? 'Wird im NPC-Tab der Szenen-Auswahl angezeigt'
                          : 'Wird im Monster-Tab der Szenen-Auswahl angezeigt',
                      style: TextStyle(
                        fontSize: 12,
                        color: C.textMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Restliche Felder
          FormFieldWidget(
            label: 'Subtyp',
            value: subtype ?? '',
            onChanged: (value) => onSubtypeChanged(value.isEmpty ? null : value),
            icon: Icons.layers,
          ),
          const SizedBox(height: 16),
          FormFieldWidget(
            label: 'Größe',
            value: size ?? '',
            onChanged: onSizeChanged,
            icon: Icons.straighten,
          ),
          const SizedBox(height: 16),
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
