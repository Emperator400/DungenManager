import 'package:flutter/material.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../theme/app_theme.dart';

/// Enhanced Campaign Filter Chips Widget mit vereinfachten Filtern
/// Behält nur: Name (Suche), Erstellungsdatum, Zuletzt gespielt
class EnhancedCampaignFilterChipsWidget extends StatelessWidget {
  final CampaignViewModel viewModel;

  const EnhancedCampaignFilterChipsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildSearchField(context, C),
            const SizedBox(height: 12),
            _buildSortOptions(context, C),
            const SizedBox(height: 8),
            _buildActiveFiltersRow(context, C),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, AppColorsExtension C) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Kampagnen durchsuchen...',
        prefixIcon: const Icon(Icons.search, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        filled: true,
        fillColor: C.textMid.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        hintStyle: const TextStyle(fontSize: 13),
      ),
      onChanged: viewModel.searchCampaigns,
    );
  }

  Widget _buildSortOptions(BuildContext context, AppColorsExtension C) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sortierung',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 3,
          children: [
            _buildSortChip(
              context,
              C,
              'Name',
              viewModel.sortOption == CampaignSortOption.name,
              () => viewModel.setSortOption(CampaignSortOption.name),
            ),
            _buildSortChip(
              context,
              C,
              'Erstellungsdatum',
              viewModel.sortOption == CampaignSortOption.createdDate,
              () => viewModel.setSortOption(CampaignSortOption.createdDate),
            ),
            _buildSortChip(
              context,
              C,
              'Zuletzt gespielt',
              viewModel.sortOption == CampaignSortOption.lastActive,
              () => viewModel.setSortOption(CampaignSortOption.lastActive),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              viewModel.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              viewModel.sortAscending ? 'Aufsteigend' : 'Absteigend',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => viewModel.setSortAscending(!viewModel.sortAscending),
              icon: Icon(
                viewModel.sortAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
              ),
              label: Text(
                viewModel.sortAscending ? 'Absteigend' : 'Aufsteigend',
                style: const TextStyle(fontSize: 11),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    AppColorsExtension C,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? C.accent.withValues(alpha: 0.9)
              : C.textMid.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? C.accent.withValues(alpha: 0.3)
                : C.textMid.withValues(alpha: 0.15),
            width: 0.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: C.accent.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : C.textMid,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow(BuildContext context, AppColorsExtension C) {
    if (viewModel.searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 3,
            children: [
              if (viewModel.searchQuery.isNotEmpty)
                _buildActiveFilterChip(
                  context,
                  C,
                  'Suche: ${viewModel.searchQuery}',
                  () => viewModel.searchCampaigns(''),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => viewModel.searchCampaigns(''),
          icon: const Icon(Icons.clear_all, size: 14),
          label: const Text('Löschen', style: TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            foregroundColor: C.red,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip(
    BuildContext context,
    AppColorsExtension C,
    String label,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

}
