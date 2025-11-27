import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/wiki_viewmodel.dart';

/// Enhanced Wiki Filter Chips Widget mit ViewModel-Integration
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
        _buildSearchBar(context),
        const SizedBox(height: 12),
        _buildTypeFilters(context),
        const SizedBox(height: 8),
        _buildScopeFilters(context),
        const SizedBox(height: 8),
        _buildSortOptions(context),
        if (viewModel.availableTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTagFilters(context),
        ],
        if (viewModel.hasActiveFilters) ...[
          const SizedBox(height: 8),
          _buildClearFiltersButton(context),
        ],
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Wiki-Einträge durchsuchen...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: viewModel.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  onSearchChanged?.call('');
                  viewModel.searchEntries('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typ filtern',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
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
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[600],
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
      backgroundColor: hasEntries ? Colors.grey[100] : Colors.grey[50],
      selectedColor: _getTypeColor(type).withOpacity(0.2),
      checkmarkColor: _getTypeColor(type),
      disabledColor: Colors.grey[50],
      labelStyle: TextStyle(
        color: isSelected ? _getTypeColor(type) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildScopeFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: const Text('Global'),
            selected: viewModel.showGlobalOnly,
            onSelected: (selected) => viewModel.toggleGlobalOnly(),
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(
              color: viewModel.showGlobalOnly ? Colors.blue : Colors.grey[700],
              fontWeight: viewModel.showGlobalOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilterChip(
            label: const Text('Campaign'),
            selected: viewModel.showCampaignOnly,
            onSelected: (selected) => viewModel.toggleCampaignOnly(),
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.orange.withOpacity(0.2),
            checkmarkColor: Colors.orange,
            labelStyle: TextStyle(
              color: viewModel.showCampaignOnly ? Colors.orange : Colors.grey[700],
              fontWeight: viewModel.showCampaignOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sortierung: ',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: DropdownButton<WikiSortOption>(
            value: viewModel.sortOption,
            isExpanded: true,
            underline: Container(),
            items: [
              DropdownMenuItem(
                value: WikiSortOption.title,
                child: Text('Titel ${viewModel.sortOption == WikiSortOption.title ? (viewModel.sortAscending ? '↑' : '↓') : ''}'),
              ),
              DropdownMenuItem(
                value: WikiSortOption.updatedAt,
                child: Text('Zuletzt aktualisiert ${viewModel.sortOption == WikiSortOption.updatedAt ? (viewModel.sortAscending ? '↑' : '↓') : ''}'),
              ),
              DropdownMenuItem(
                value: WikiSortOption.createdAt,
                child: Text('Erstellt ${viewModel.sortOption == WikiSortOption.createdAt ? (viewModel.sortAscending ? '↑' : '↓') : ''}'),
              ),
              DropdownMenuItem(
                value: WikiSortOption.type,
                child: Text('Typ ${viewModel.sortOption == WikiSortOption.type ? (viewModel.sortAscending ? '↑' : '↓') : ''}'),
              ),
              DropdownMenuItem(
                value: WikiSortOption.tagCount,
                child: Text('Tags ${viewModel.sortOption == WikiSortOption.tagCount ? (viewModel.sortAscending ? '↑' : '↓') : ''}'),
              ),
            ],
            onChanged: (option) {
              if (option != null) {
                viewModel.setSortOption(option);
              }
            },
          ),
        ),
        IconButton(
          onPressed: () => viewModel.setSortAscending(!viewModel.sortAscending),
          icon: Icon(
            viewModel.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 20,
          ),
          tooltip: 'Sortierung umkehren',
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
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: availableTags.map((tag) => _buildTagChip(context, tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    final isSelected = viewModel.selectedTags.contains(tag);
    
    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (selected) => viewModel.toggleTagFilter(tag),
      backgroundColor: Colors.amber[50],
      selectedColor: Colors.amber.withOpacity(0.2),
      checkmarkColor: Colors.amber[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.amber[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Color _getTypeColor(WikiEntryType? type) {
    if (type == null) return Colors.grey;
    
    switch (type) {
      case WikiEntryType.Person:
        return Colors.blue;
      case WikiEntryType.Place:
        return Colors.green;
      case WikiEntryType.Lore:
        return Colors.purple;
      case WikiEntryType.Faction:
        return Colors.orange;
      case WikiEntryType.Magic:
        return Colors.pink;
      case WikiEntryType.History:
        return Colors.brown;
      case WikiEntryType.Item:
        return Colors.teal;
      case WikiEntryType.Quest:
        return Colors.indigo;
      case WikiEntryType.Creature:
        return Colors.red;
    }
  }
}
