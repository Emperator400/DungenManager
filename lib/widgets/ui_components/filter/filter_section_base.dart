import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

abstract class FilterSectionBase extends StatelessWidget {
  const FilterSectionBase({
    required this.hasActiveFilters,
    required this.onClearAllFilters,
    super.key,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearAllFilters;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, C),
          const SizedBox(height: 12),
          ...buildFilterSections(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension C) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getFilterTitle(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
          ),
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: onClearAllFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Alle entfernen'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      );

  String getFilterTitle() => 'Filter';

  List<Widget> buildFilterSections(BuildContext context) => [];

  Widget buildSectionTitle(BuildContext context, String title) {
    final C = context.appColors;
    return Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
    );
  }

  Widget buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? selectedColor,
    Color? checkmarkColor,
  }) {
    final C = context.appColors;
    return FilterChip(
      label: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
            )
          : Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: C.bgPanel,
      selectedColor: selectedColor?.withValues(alpha: 0.2) ??
          C.accent.withValues(alpha: 0.2),
      checkmarkColor: checkmarkColor ?? C.accent,
      labelStyle: TextStyle(
        color: isSelected ? (checkmarkColor ?? C.accent) : C.textMid,
      ),
    );
  }

  Widget buildChipWrap({
    required List<Widget> children,
    double spacing = 8,
    double runSpacing = 4,
  }) =>
      Wrap(spacing: spacing, runSpacing: runSpacing, children: children);
}
