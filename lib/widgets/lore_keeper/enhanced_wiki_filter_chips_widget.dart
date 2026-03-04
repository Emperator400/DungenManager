import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/wiki_viewmodel.dart';
import '../../theme/dnd_theme.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeFilters(context),
        const SizedBox(height: DnDTheme.sm),
        _buildScopeFilters(context),
        const SizedBox(height: DnDTheme.sm),
        if (viewModel.availableTags.isNotEmpty) ...[
          _buildTagFilters(context),
          const SizedBox(height: DnDTheme.sm),
        ],
        if (viewModel.hasActiveFilters) ...[
          _buildClearFiltersButton(context),
          const SizedBox(height: DnDTheme.sm),
        ],
      ],
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typ filtern',
          style: DnDTheme.bodyText2.copyWith(
            fontWeight: FontWeight.w600,
            color: DnDTheme.ancientGold,
          ),
        ),
        const SizedBox(height: DnDTheme.xs),
        Wrap(
          spacing: DnDTheme.xs,
          runSpacing: DnDTheme.xs,
          children: [
            _buildTypeChip(context, null, 'Alle'),
            ...WikiEntryType.values.map((type) => _buildTypeChip(
              context,
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
    WikiEntryType? type,
    String label, {
    int? count,
  }) {
    final isSelected = viewModel.selectedType == type;
    final hasEntries = count == null || count > 0;
    final chipColor = type == null ? Colors.white : _getTypeColor(type);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: DnDTheme.caption.copyWith(
            color: isSelected ? chipColor : Colors.white70,
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
                style: DnDTheme.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white70,
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
      backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      disabledColor: DnDTheme.slateGrey.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? chipColor : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        width: 1,
      ),
      labelStyle: DnDTheme.caption.copyWith(
        color: isSelected ? chipColor : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildScopeFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: Text('Global', style: DnDTheme.caption),
            selected: viewModel.showGlobalOnly,
            onSelected: (selected) => viewModel.toggleGlobalOnly(),
            backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
            selectedColor: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
            checkmarkColor: DnDTheme.arcaneBlue,
            side: BorderSide(
              color: viewModel.showGlobalOnly 
                  ? DnDTheme.arcaneBlue 
                  : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
            ),
            labelStyle: DnDTheme.caption.copyWith(
              color: viewModel.showGlobalOnly ? DnDTheme.arcaneBlue : Colors.white70,
              fontWeight: viewModel.showGlobalOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: DnDTheme.xs),
        Expanded(
          child: FilterChip(
            label: Text('Campaign', style: DnDTheme.caption),
            selected: viewModel.showCampaignOnly,
            onSelected: (selected) => viewModel.toggleCampaignOnly(),
            backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
            selectedColor: DnDTheme.warningOrange.withValues(alpha: 0.2),
            checkmarkColor: DnDTheme.warningOrange,
            side: BorderSide(
              color: viewModel.showCampaignOnly 
                  ? DnDTheme.warningOrange 
                  : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
            ),
            labelStyle: DnDTheme.caption.copyWith(
              color: viewModel.showCampaignOnly ? DnDTheme.warningOrange : Colors.white70,
              fontWeight: viewModel.showCampaignOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagFilters(BuildContext context) {
    final availableTags = viewModel.availableTags.toList();
    if (availableTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags filtern',
          style: DnDTheme.bodyText2.copyWith(
            fontWeight: FontWeight.w600,
            color: DnDTheme.ancientGold,
          ),
        ),
        const SizedBox(height: DnDTheme.xs),
        Wrap(
          spacing: DnDTheme.xs,
          runSpacing: DnDTheme.xs,
          children: availableTags.map((tag) => _buildTagChip(context, tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    final isSelected = viewModel.selectedTags.contains(tag);
    
    return FilterChip(
      label: Text(tag, style: DnDTheme.caption),
      selected: isSelected,
      onSelected: (selected) => viewModel.toggleTagFilter(tag),
      backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
      selectedColor: DnDTheme.ancientGold.withValues(alpha: 0.2),
      checkmarkColor: DnDTheme.ancientGold,
      side: BorderSide(
        color: isSelected 
            ? DnDTheme.ancientGold 
            : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
      ),
      labelStyle: DnDTheme.caption.copyWith(
        color: isSelected ? DnDTheme.ancientGold : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildClearFiltersButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: viewModel.clearAllFilters,
      icon: const Icon(Icons.clear_all, size: 16),
      label: const Text('Alle Filter löschen'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: DnDTheme.sm, vertical: DnDTheme.xs),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: DnDTheme.errorRed,
        side: BorderSide(color: DnDTheme.errorRed),
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

  Color _getTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Place:
        return DnDTheme.successGreen;
      case WikiEntryType.Lore:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Faction:
        return DnDTheme.warningOrange;
      case WikiEntryType.Magic:
        return DnDTheme.infoBlue;
      case WikiEntryType.History:
        return DnDTheme.ancientGold;
      case WikiEntryType.Item:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Quest:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Creature:
        return DnDTheme.errorRed;
    }
  }
}