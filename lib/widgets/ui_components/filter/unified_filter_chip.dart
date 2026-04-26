import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class UnifiedFilterChip<T> extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final selColor = selectedColor ?? C.accent;
    final unselColor = unselectedColor ?? C.textMid;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              onSelected?.call(value);
              onToggle?.call(value);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? selColor.withValues(alpha: 0.12)
              : C.bgPanel,
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          border: Border.all(
            color: isSelected ? selColor : C.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheckmark && isSelected) ...[
              Icon(Icons.check, size: isCompact ? 11 : 13, color: selColor),
              SizedBox(width: isCompact ? 3 : 5),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: isCompact ? 12 : 14,
                color: isSelected ? selColor : unselColor,
              ),
              SizedBox(width: isCompact ? 3 : 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selColor : unselColor,
                fontSize: isCompact ? 11 : 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnifiedFilterChipGroup<T> extends StatelessWidget {
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

  void _handleSelect(T value) {
    final next = Set<T>.from(selectedValues);
    if (isMultiSelect) {
      if (next.contains(value)) {
        next.remove(value);
      } else {
        next.add(value);
      }
    } else {
      next
        ..clear()
        ..add(value);
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final selColor = selectedColor ?? C.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 14, color: C.textSoft),
                const SizedBox(width: 6),
              ],
              Text(
                title!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: C.textMid,
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
          children: chips
              .map((chip) => UnifiedFilterChip<T>(
                    value: chip.value,
                    label: chip.label,
                    icon: chip.icon,
                    isSelected: selectedValues.contains(chip.value),
                    selectedColor: selColor,
                    onSelected: (_) => _handleSelect(chip.value),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class UnifiedFilterChipItem<T> {
  const UnifiedFilterChipItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class StringFilterChipItem extends UnifiedFilterChipItem<String> {
  const StringFilterChipItem({
    required super.value,
    required super.label,
    super.icon,
  });

  factory StringFilterChipItem.status(String status, {IconData? icon}) =>
      StringFilterChipItem(
        value: status,
        label: status,
        icon: icon ?? _statusIcon(status),
      );

  factory StringFilterChipItem.type(String type, {IconData? icon}) =>
      StringFilterChipItem(value: type, label: type, icon: icon);

  factory StringFilterChipItem.sort(String key, String label,
          {IconData? icon}) =>
      StringFilterChipItem(value: key, label: label, icon: icon);

  static IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('aktiv') || s.contains('active')) {
      return Icons.check_circle;
    }
    if (s.contains('pending') || s.contains('wartet')) {
      return Icons.pending;
    }
    if (s.contains('komplett') || s.contains('complete')) {
      return Icons.done_all;
    }
    if (s.contains('archiv')) {
      return Icons.archive;
    }
    return Icons.info_outline;
  }
}

class UnifiedFilterSections {
  static UnifiedFilterChipGroup<String> campaignStatus({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) =>
      UnifiedFilterChipGroup<String>(
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

  static UnifiedFilterChipGroup<String> questStatus({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) =>
      UnifiedFilterChipGroup<String>(
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

  static UnifiedFilterChipGroup<String> sortOptions({
    required Set<String> selectedValues,
    ValueChanged<Set<String>>? onChanged,
  }) =>
      UnifiedFilterChipGroup<String>(
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
