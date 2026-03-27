import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Unified Filter Chip
/// 
/// Einheitlicher Filter-Chip für alle Filter-Anwendungen
/// Unterstützt Single-Select, Multi-Select, Icons und verschiedene Styles
class UnifiedFilterChip<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isEnabled;
  final Color? selectedColor;
  final Color? unselectedColor;
  final ValueChanged<T>? onSelected;
  final ValueChanged<T>? onToggle;
  final bool showCheckmark;
  final bool isCompact;

  const UnifiedFilterChip({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.isEnabled = true,
    this.selectedColor,
    this.unselectedColor,
    this.onSelected,
    this.onToggle,
    this.showCheckmark = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor = selectedColor ?? DnDTheme.ancientGold;
    final effectiveUnselectedColor = unselectedColor ?? DnDTheme.mysticalPurple;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                if (onSelected != null) {
                  onSelected!(value);
                }
                if (onToggle != null) {
                  onToggle!(value);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveSelectedColor.withValues(alpha: 0.2)
                : effectiveUnselectedColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(
              color: isSelected
                  ? effectiveSelectedColor
                  : effectiveUnselectedColor.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isCompact ? 14 : 16,
                  color: isSelected
                      ? effectiveSelectedColor
                      : effectiveUnselectedColor,
                ),
                SizedBox(width: isCompact ? 4 : 6),
              ],
              if (showCheckmark && isSelected) ...[
                Icon(
                  Icons.check,
                  size: isCompact ? 14 : 16,
                  color: effectiveSelectedColor,
                ),
                SizedBox(width: isCompact ? 4 : 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? effectiveSelectedColor
                      : effectiveUnselectedColor,
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified Filter Chip Group
/// 
/// Gruppe von Filter-Chips mit Single- oder Multi-Select
class UnifiedFilterChipGroup<T> extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final List<UnifiedFilterChipItem<T>> chips;
  final Set<T> selectedValues;
  final bool isMultiSelect;
  final Color? selectedColor;
  final Color? unselectedColor;
  final ValueChanged<Set<T>>? onChanged;
  final Axis direction;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  const UnifiedFilterChipGroup({
    super.key,
    this.title,
    this.titleIcon,
    required this.chips,
    required this.selectedValues,
    this.isMultiSelect = true,
    this.selectedColor,
    this.unselectedColor,
    this.onChanged,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  void _handleChipSelected(T value) {
    final newSelection = Set<T>.from(selectedValues);
    
    if (isMultiSelect) {
      if (newSelection.contains(value)) {
        newSelection.remove(value);
      } else {
        newSelection.add(value);
      }
    } else {
      newSelection
        ..clear()
        ..add(value);
    }
    
    onChanged?.call(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor = selectedColor ?? DnDTheme.ancientGold;
    final effectiveUnselectedColor = unselectedColor ?? DnDTheme.mysticalPurple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  size: 16,
                  color: effectiveSelectedColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title!,
                style: DnDTheme.bodyText2.copyWith(
                  color: effectiveSelectedColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          direction: direction,
          alignment: alignment,
          spacing: spacing,
          runSpacing: runSpacing,
          children: chips.map((chip) => UnifiedFilterChip<T>(
            value: chip.value,
            label: chip.label,
            icon: chip.icon,
            isSelected: selectedValues.contains(chip.value),
            selectedColor: effectiveSelectedColor,
            unselectedColor: effectiveUnselectedColor,
            onSelected: (_) => _handleChipSelected(chip.value),
          )).toList(),
        ),
      ],
    );
  }
}

/// Datenklasse für Filter-Chip
class UnifiedFilterChipItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const UnifiedFilterChipItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// String-basierte Filter-Chip-Item Factory
class StringFilterChipItem extends UnifiedFilterChipItem<String> {
  const StringFilterChipItem({
    required super.value,
    required super.label,
    super.icon,
  });

  /// Factory für Status-Filter
  factory StringFilterChipItem.status(String status, {IconData? icon}) =>
      StringFilterChipItem(
        value: status,
        label: status,
        icon: icon ?? _getStatusIcon(status),
      );

  /// Factory für Typ-Filter
  factory StringFilterChipItem.type(String type, {IconData? icon}) =>
      StringFilterChipItem(
        value: type,
        label: type,
        icon: icon,
      );

  /// Factory für Sortierungs-Option
  factory StringFilterChipItem.sort(String sortKey, String label, {IconData? icon}) =>
      StringFilterChipItem(
        value: sortKey,
        label: label,
        icon: icon,
      );

  static IconData _getStatusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('aktiv') || lower.contains('active')) {
      return Icons.check_circle;
    }
    if (lower.contains('pending') || lower.contains('wartet')) {
      return Icons.pending;
    }
    if (lower.contains('komplett') || lower.contains('complete')) {
      return Icons.done_all;
    }
    if (lower.contains('archiv')) {
      return Icons.archive;
    }
    return Icons.info_outline;
  }
}

/// Vorgefertigte Filter-Sektionen
class UnifiedFilterSections {
  /// Status-Filter für Kampagnen
  static UnifiedFilterChipGroup<String> campaignStatus({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) => UnifiedFilterChipGroup<String>(
      title: 'Status',
      titleIcon: Icons.flag,
      chips: const [
        StringFilterChipItem(value: 'active', label: 'Aktiv', icon: Icons.play_circle),
        StringFilterChipItem(value: 'paused', label: 'Pausiert', icon: Icons.pause_circle),
        StringFilterChipItem(value: 'completed', label: 'Abgeschlossen', icon: Icons.check_circle),
        StringFilterChipItem(value: 'archived', label: 'Archiviert', icon: Icons.archive),
      ],
      selectedValues: selectedValues,
      onChanged: onChanged,
    );

  /// Quest-Status-Filter
  static UnifiedFilterChipGroup<String> questStatus({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) => UnifiedFilterChipGroup<String>(
      title: 'Quest-Status',
      titleIcon: Icons.assignment,
      chips: const [
        StringFilterChipItem(value: 'open', label: 'Offen', icon: Icons.radio_button_unchecked),
        StringFilterChipItem(value: 'in_progress', label: 'In Arbeit', icon: Icons.pending),
        StringFilterChipItem(value: 'completed', label: 'Erledigt', icon: Icons.check_circle),
        StringFilterChipItem(value: 'failed', label: 'Fehlgeschlagen', icon: Icons.error),
      ],
      selectedValues: selectedValues,
      onChanged: onChanged,
    );

  /// Wiki-Typ-Filter
  static UnifiedFilterChipGroup<String> wikiType({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) => UnifiedFilterChipGroup<String>(
      title: 'Kategorie',
      titleIcon: Icons.category,
      chips: const [
        StringFilterChipItem(value: 'person', label: 'Personen', icon: Icons.person),
        StringFilterChipItem(value: 'location', label: 'Orte', icon: Icons.place),
        StringFilterChipItem(value: 'item', label: 'Gegenstände', icon: Icons.inventory_2),
        StringFilterChipItem(value: 'event', label: 'Ereignisse', icon: Icons.event),
        StringFilterChipItem(value: 'organization', label: 'Organisationen', icon: Icons.groups),
        StringFilterChipItem(value: 'lore', label: 'Lore', icon: Icons.auto_stories),
      ],
      selectedValues: selectedValues,
      onChanged: onChanged,
    );

  /// Kreatur-Typ-Filter
  static UnifiedFilterChipGroup<String> creatureType({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) => UnifiedFilterChipGroup<String>(
      title: 'Kreatur-Typ',
      titleIcon: Icons.pets,
      chips: const [
        StringFilterChipItem(value: 'undead', label: 'Untote', icon: Icons.nights_stay),
        StringFilterChipItem(value: 'beast', label: 'Bestien', icon: Icons.pets),
        StringFilterChipItem(value: 'humanoid', label: 'Humanoide', icon: Icons.person),
        StringFilterChipItem(value: 'dragon', label: 'Drachen', icon: Icons.local_fire_department),
        StringFilterChipItem(value: 'fiend', label: 'Teufel', icon: Icons.whatshot),
        StringFilterChipItem(value: 'elemental', label: 'Elementare', icon: Icons.water_drop),
      ],
      selectedValues: selectedValues,
      onChanged: onChanged,
    );

  /// Sortierungs-Optionen
  static UnifiedFilterChipGroup<String> sortOptions({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) => UnifiedFilterChipGroup<String>(
      title: 'Sortierung',
      titleIcon: Icons.sort,
      chips: const [
        StringFilterChipItem(value: 'name', label: 'Name', icon: Icons.sort_by_alpha),
        StringFilterChipItem(value: 'date', label: 'Datum', icon: Icons.calendar_today),
        StringFilterChipItem(value: 'level', label: 'Level', icon: Icons.bar_chart),
        StringFilterChipItem(value: 'favorites', label: 'Favoriten', icon: Icons.star),
      ],
      selectedValues: selectedValues,
      isMultiSelect: false,
      onChanged: onChanged,
    );
}