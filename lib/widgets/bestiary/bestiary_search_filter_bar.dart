import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';

/// Such- und Filterleiste für das Bestiarum
class BestiarySearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;

  const BestiarySearchFilterBar({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.stoneGrey,
              endColor: DnDTheme.slateGrey,
            ),
            border: Border(
              bottom: BorderSide(
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Suchleiste
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Kreaturen suchen...',
                  hintStyle: DnDTheme.bodyText2.copyWith(
                    color: Colors.white54,
                  ),
                  prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
                  suffixIcon: viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                          onPressed: () {
                            viewModel.updateSearchQuery('');
                            searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    borderSide: BorderSide(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
                  filled: true,
                  fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                ),
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                onChanged: (value) {
                  viewModel.updateSearchQuery(value);
                },
              ),
              
              const SizedBox(height: DnDTheme.sm),
              
              // Filter-Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    BestiaryFilterChip(
                      label: 'Alle',
                      isSelected: viewModel.selectedSourceType == 'all',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('all'),
                      color: DnDTheme.mysticalPurple,
                    ),
                    BestiaryFilterChip(
                      label: 'Eigene',
                      isSelected: viewModel.selectedSourceType == 'custom',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('custom'),
                      color: DnDTheme.successGreen,
                    ),
                    BestiaryFilterChip(
                      label: 'Offiziell',
                      isSelected: viewModel.selectedSourceType == 'official',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('official'),
                      color: DnDTheme.arcaneBlue,
                    ),
                    BestiaryFilterChip(
                      label: 'Favoriten',
                      isSelected: viewModel.showFavoritesOnly,
                      onSelected: (selected) => viewModel.updateFavoritesFilter(selected),
                      color: DnDTheme.ancientGold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Einzelner Filter-Chip für das Bestiarum
class BestiaryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final Color color;

  const BestiaryFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: DnDTheme.xs),
      child: FilterChip(
        label: Text(
          label,
          style: DnDTheme.bodyText2.copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.5),
          width: 1.5,
        ),
        elevation: isSelected ? 2 : 0,
        pressElevation: 4,
      ),
    );
  }
}