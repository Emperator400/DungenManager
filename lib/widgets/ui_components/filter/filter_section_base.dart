import 'package:flutter/material.dart';

/// Abstrakte Basis-Klasse für Filter-Sektionen
/// 
/// Bietet eine einheitliche Struktur für Filter-Chips in verschiedenen Screens.
/// Konkrete Implementierungen überschreiben die abstrakten Methoden
/// für ihre spezifischen Filter-Sektionen.
abstract class FilterSectionBase extends StatelessWidget {
  /// Zeigt an, ob aktive Filter vorhanden sind
  final bool hasActiveFilters;
  
  /// Callback zum Löschen aller Filter
  final VoidCallback onClearAllFilters;

  const FilterSectionBase({
    super.key,
    required this.hasActiveFilters,
    required this.onClearAllFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 12),
          
          // Filter-Sektionen
          ...buildFilterSections(context),
        ],
      ),
    );
  }

  /// Baut den Header mit Titel und "Alle entfernen"-Button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          getFilterTitle(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
  }

  /// Gibt den Titel der Filter-Sektion zurück
  String getFilterTitle() => 'Filter';

  /// Baut alle Filter-Sektionen
  /// Konkrete Implementierungen überschreiben diese Methode
  List<Widget> buildFilterSections(BuildContext context) => [];

  /// Baut eine Section-Überschrift
  Widget buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  /// Baut eine Standard-FilterChip
  Widget buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? selectedColor,
    Color? checkmarkColor,
  }) {
    return FilterChip(
      label: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Text(label),
              ],
            )
          : Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: selectedColor?.withOpacity(0.2) ?? 
                  Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: checkmarkColor ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected 
            ? (checkmarkColor ?? Theme.of(context).primaryColor)
            : Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }

  /// Baut eine Wrap-Sektion für Chips
  Widget buildChipWrap({
    required List<Widget> children,
    double spacing = 8,
    double runSpacing = 4,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
