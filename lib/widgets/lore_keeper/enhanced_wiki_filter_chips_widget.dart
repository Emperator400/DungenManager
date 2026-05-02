import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/wiki_viewmodel.dart';
import '../../theme/app_theme.dart';

/// Enhanced Wiki Filter Chips Widget mit Enhanced Design und ViewModel-Integration
class EnhancedWikiFilterChipsWidget extends StatelessWidget {
  final WikiViewModel viewModel;
  final ValueChanged<String>? onSearchChanged;

  const EnhancedWikiFilterChipsWidget({
    super.key,
    required this.viewModel,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeFilters(context, C),
        const SizedBox(height: 8),
        _buildScopeFilters(context, C),
        const SizedBox(height: 8),
        if (viewModel.availableTags.isNotEmpty) ...[
          _buildTagFilters(context, C),
          const SizedBox(height: 8),
        ],
        if (viewModel.hasActiveFilters) ...[
          _buildClearFiltersButton(context, C),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildTypeFilters(BuildContext context, AppColorsExtension C) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typ filtern',
          style: TextStyle(
            fontSize: 12,
            color: C.amber,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildTypeChip(context, C, null, 'Alle'),
            ...WikiEntryType.values.map((type) => _buildTypeChip(
              context,
              C,
              type,
              _getTypeDisplayName(type),
              count: viewModel.entryTypeCounts[type] ?? 0,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    AppColorsExtension C,
    WikiEntryType? type,
    String label, {
    int? count,
  }) {
    final isSelected = viewModel.selectedType == type;
    final hasEntries = count == null || count > 0;
    final chipColor = type == null ? C.text : _getTypeColor(type, C);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(
            fontSize: 11,
            color: isSelected ? chipColor : C.textMid,
          )),
          if (count != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : C.textMid,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: hasEntries ? (selected) {
        viewModel.setTypeFilter(selected ? type : null);
      } : null,
      backgroundColor: C.bgPanel.withValues(alpha: 0.3),
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      disabledColor: C.bgPanel.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? chipColor : C.accent.withValues(alpha: 0.3),
        width: 1,
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? chipColor : C.textMid,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildScopeFilters(BuildContext context, AppColorsExtension C) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: Text('Global', style: TextStyle(fontSize: 11, color: C.textMid)),
            selected: viewModel.showGlobalOnly,
            onSelected: (selected) => viewModel.toggleGlobalOnly(),
            backgroundColor: C.bgPanel.withValues(alpha: 0.3),
            selectedColor: C.accent.withValues(alpha: 0.2),
            checkmarkColor: C.accent,
            side: BorderSide(
              color: viewModel.showGlobalOnly
                  ? C.accent
                  : C.accent.withValues(alpha: 0.3),
            ),
            labelStyle: TextStyle(
              fontSize: 11,
              color: viewModel.showGlobalOnly ? C.accent : C.textMid,
              fontWeight: viewModel.showGlobalOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FilterChip(
            label: Text('Campaign', style: TextStyle(fontSize: 11, color: C.textMid)),
            selected: viewModel.showCampaignOnly,
            onSelected: (selected) => viewModel.toggleCampaignOnly(),
            backgroundColor: C.bgPanel.withValues(alpha: 0.3),
            selectedColor: C.amber.withValues(alpha: 0.2),
            checkmarkColor: C.amber,
            side: BorderSide(
              color: viewModel.showCampaignOnly
                  ? C.amber
                  : C.accent.withValues(alpha: 0.3),
            ),
            labelStyle: TextStyle(
              fontSize: 11,
              color: viewModel.showCampaignOnly ? C.amber : C.textMid,
              fontWeight: viewModel.showCampaignOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagFilters(BuildContext context, AppColorsExtension C) {
    final availableTags = viewModel.availableTags.toList();
    if (availableTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags filtern',
          style: TextStyle(
            fontSize: 12,
            color: C.amber,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: availableTags.map((tag) => _buildTagChip(context, C, tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, AppColorsExtension C, String tag) {
    final isSelected = viewModel.selectedTags.contains(tag);

    return FilterChip(
      label: Text(tag, style: TextStyle(fontSize: 11, color: C.textMid)),
      selected: isSelected,
      onSelected: (selected) => viewModel.toggleTagFilter(tag),
      backgroundColor: C.bgPanel.withValues(alpha: 0.3),
      selectedColor: C.amber.withValues(alpha: 0.2),
      checkmarkColor: C.amber,
      side: BorderSide(
        color: isSelected
            ? C.amber
            : C.accent.withValues(alpha: 0.3),
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? C.amber : C.textMid,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildClearFiltersButton(BuildContext context, AppColorsExtension C) {
    return OutlinedButton.icon(
      onPressed: viewModel.clearAllFilters,
      icon: const Icon(Icons.clear_all, size: 16),
      label: const Text('Alle Filter löschen'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: C.red,
        side: BorderSide(color: C.red),
      ),
    );
  }

  String _getTypeDisplayName(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return 'NPC';
      case WikiEntryType.Place:
        return 'Ort';
      case WikiEntryType.Lore:
        return 'Lore';
      case WikiEntryType.Faction:
        return 'Fraktion';
      case WikiEntryType.Magic:
        return 'Magie';
      case WikiEntryType.History:
        return 'Geschichte';
      case WikiEntryType.Item:
        return 'Gegenstand';
      case WikiEntryType.Quest:
        return 'Quest';
      case WikiEntryType.Creature:
        return 'Kreatur';
    }
  }

  Color _getTypeColor(WikiEntryType type, AppColorsExtension C) {
    switch (type) {
      case WikiEntryType.Person:
        return C.accent;
      case WikiEntryType.Place:
        return C.green;
      case WikiEntryType.Lore:
        return C.accent;
      case WikiEntryType.Faction:
        return C.amber;
      case WikiEntryType.Magic:
        return C.accent;
      case WikiEntryType.History:
        return C.amber;
      case WikiEntryType.Item:
        return C.accent;
      case WikiEntryType.Quest:
        return C.accent;
      case WikiEntryType.Creature:
        return C.red;
    }
  }
}
