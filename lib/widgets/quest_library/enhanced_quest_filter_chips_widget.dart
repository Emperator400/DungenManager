import 'package:flutter/material.dart';
import '../../models/quest.dart';
import '../../viewmodels/quest_library_viewmodel.dart';
import '../../theme/app_theme.dart';

/// Modernisiertes QuestFilterChipsWidget mit ViewModel-Integration
/// 
/// Dieses Widget verwendet das QuestLibraryViewModel für State Management
/// anstelle von direkten Callbacks und lokalem State.
class EnhancedQuestFilterChipsWidget extends StatelessWidget {
  final QuestLibraryViewModel viewModel;

  const EnhancedQuestFilterChipsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Titel und Clear-Button
          _buildHeader(context),
          const SizedBox(height: 12),
          
          // Quest-Type Filter
          _buildQuestTypeSection(),
          const SizedBox(height: 16),
          
          // Difficulty Filter
          _buildDifficultySection(),
          const SizedBox(height: 16),
          
          // Favorites Filter
          _buildFavoritesSection(),
          
          // Tags Filter (nur anzeigen wenn Tags verfügbar)
          if (viewModel.availableTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTagsSection(),
          ],
        ],
      ),
    );
  }

  /// Baut den Header mit Titel und Clear-Button
  Widget _buildHeader(BuildContext context) {
    final C = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filter',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: C.accent,
          ),
        ),
        if (viewModel.hasActiveFilters)
          TextButton.icon(
            onPressed: () => viewModel.clearAllFilters(),
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Alle entfernen'),
            style: TextButton.styleFrom(
              foregroundColor: C.red,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
      ],
    );
  }

  /// Baut die Quest-Type Sektion
  Widget _buildQuestTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quest-Typ'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildTypeChip('Alle', null, Icons.flag),
            _buildTypeChip('Hauptquest', QuestType.main, Icons.flag),
            _buildTypeChip('Sidequest', QuestType.side, Icons.explore),
            _buildTypeChip('Persönlich', QuestType.personal, Icons.person),
            _buildTypeChip('Fraktion', QuestType.faction, Icons.group),
          ],
        ),
      ],
    );
  }

  /// Baut die Difficulty Sektion
  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Schwierigkeit'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildDifficultyChip('Alle', null),
            _buildDifficultyChip('Leicht', QuestDifficulty.easy),
            _buildDifficultyChip('Mittel', QuestDifficulty.medium),
            _buildDifficultyChip('Schwer', QuestDifficulty.hard),
            _buildDifficultyChip('Tödlich', QuestDifficulty.deadly),
            _buildDifficultyChip('Episch', QuestDifficulty.epic),
            _buildDifficultyChip('Legendär', QuestDifficulty.legendary),
          ],
        ),
      ],
    );
  }

  /// Baut die Favorites Sektion
  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sonstiges'),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final C = context.appColors;
            return FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16),
                  SizedBox(width: 4),
                  Text('Nur Favoriten'),
                ],
              ),
              selected: viewModel.showFavoritesOnly,
              onSelected: (selected) => viewModel.setFavoritesFilter(selected),
              backgroundColor: C.border,
              selectedColor: C.amber.withValues(alpha: 0.2),
              checkmarkColor: C.amber,
              labelStyle: TextStyle(
                color: viewModel.showFavoritesOnly ? C.amber : C.text,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Baut die Tags Sektion
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tags'),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final C = context.appColors;
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: viewModel.availableTags.map((tag) {
                final isSelected = viewModel.selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => viewModel.toggleTag(tag),
                  backgroundColor: C.border,
                  selectedColor: C.accent.withValues(alpha: 0.2),
                  checkmarkColor: C.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? C.accent : C.text,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Baut eine Sektionsüberschrift
  Widget _buildSectionTitle(String title) {
    return Builder(
      builder: (context) => Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.appColors.text,
        ),
      ),
    );
  }

  /// Baut eine Type-Chip
  Widget _buildTypeChip(String label, QuestType? type, IconData icon) {
    return Builder(
      builder: (context) {
        final C = context.appColors;
        final isSelected = viewModel.selectedType == type;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => viewModel.setTypeFilter(type),
          backgroundColor: C.border,
          selectedColor: _getTypeColor(C, type).withValues(alpha: 0.2),
          checkmarkColor: _getTypeColor(C, type),
          labelStyle: TextStyle(
            color: isSelected ? _getTypeColor(C, type) : C.text,
          ),
        );
      },
    );
  }

  /// Baut eine Difficulty-Chip
  Widget _buildDifficultyChip(String label, QuestDifficulty? difficulty) {
    return Builder(
      builder: (context) {
        final C = context.appColors;
        final isSelected = viewModel.selectedDifficulty == difficulty;
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => viewModel.setDifficultyFilter(difficulty),
          backgroundColor: C.border,
          selectedColor: _getDifficultyColor(C, difficulty).withValues(alpha: 0.2),
          checkmarkColor: _getDifficultyColor(C, difficulty),
          labelStyle: TextStyle(
            color: isSelected ? _getDifficultyColor(C, difficulty) : C.text,
          ),
        );
      },
    );
  }

  /// Gibt die Farbe für den Quest-Typ zurück
  Color _getTypeColor(AppColorsExtension C, QuestType? type) {
    if (type == null) return C.textMid;
    switch (type) {
      case QuestType.main:
        return C.red;
      case QuestType.side:
        return C.accent;
      case QuestType.personal:
        return C.accent;
      case QuestType.faction:
        return C.green;
    }
  }

  /// Gibt die Farbe für die Schwierigkeit zurück
  Color _getDifficultyColor(AppColorsExtension C, QuestDifficulty? difficulty) {
    if (difficulty == null) return C.textMid;
    switch (difficulty) {
      case QuestDifficulty.easy:
        return C.green;
      case QuestDifficulty.medium:
        return C.amber;
      case QuestDifficulty.hard:
        return C.amber;
      case QuestDifficulty.deadly:
        return C.red;
      case QuestDifficulty.epic:
        return C.accent;
      case QuestDifficulty.legendary:
        return C.amber;
    }
  }
}
