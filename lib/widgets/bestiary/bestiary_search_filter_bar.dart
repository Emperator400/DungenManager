import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
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
    final C = context.appColors;
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(
              bottom: BorderSide(
                color: C.accent.withValues(alpha: 0.3),
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
                  hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
                  prefixIcon: Icon(Icons.search, color: C.amber),
                  suffixIcon: viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: C.red),
                          onPressed: () {
                            viewModel.updateSearchQuery('');
                            searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: C.accent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: C.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: C.amber, width: 2),
                  ),
                  filled: true,
                  fillColor: C.bgActive.withValues(alpha: 0.3),
                ),
                style: TextStyle(fontSize: 14, color: C.text),
                onChanged: (value) {
                  viewModel.updateSearchQuery(value);
                },
              ),

              const SizedBox(height: 8),

              // Filter-Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    BestiaryFilterChip(
                      label: 'Alle',
                      isSelected: viewModel.selectedSourceType == 'all',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('all'),
                      color: C.accent,
                    ),
                    BestiaryFilterChip(
                      label: 'Eigene',
                      isSelected: viewModel.selectedSourceType == 'custom',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('custom'),
                      color: C.green,
                    ),
                    BestiaryFilterChip(
                      label: 'Offiziell',
                      isSelected: viewModel.selectedSourceType == 'official',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('official'),
                      color: C.accent,
                    ),
                    BestiaryFilterChip(
                      label: 'Favoriten',
                      isSelected: viewModel.showFavoritesOnly,
                      onSelected: (selected) => viewModel.updateFavoritesFilter(selected),
                      color: C.amber,
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
    final C = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: C.bgActive.withValues(alpha: 0.3),
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
