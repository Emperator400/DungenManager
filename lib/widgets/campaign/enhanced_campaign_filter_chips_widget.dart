import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/campaign_viewmodel.dart';

class EnhancedCampaignFilterChipsWidget extends StatelessWidget {
  const EnhancedCampaignFilterChipsWidget({
    required this.viewModel,
    super.key,
  });

  final CampaignViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Row(
      children: [
        // ── Suchfeld ────────────────────────────────────────────────────────
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextField(
              onChanged: viewModel.searchCampaigns,
              style: TextStyle(fontSize: 12, color: C.text),
              decoration: InputDecoration(
                hintText: 'Suchen…',
                hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
                prefixIcon: Icon(Icons.search, size: 14, color: C.textSoft),
                prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                suffixIcon: viewModel.searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => viewModel.searchCampaigns(''),
                        child: Icon(Icons.close, size: 13, color: C.textSoft),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                filled: true,
                fillColor: C.bgHover,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: C.accent),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ── Sortier-Chips ────────────────────────────────────────────────────
        _SortChip(
          label: 'Name',
          selected: viewModel.sortOption == CampaignSortOption.name,
          C: C,
          onTap: () => viewModel.setSortOption(CampaignSortOption.name),
        ),
        const SizedBox(width: 4),
        _SortChip(
          label: 'Datum',
          selected: viewModel.sortOption == CampaignSortOption.createdDate,
          C: C,
          onTap: () => viewModel.setSortOption(CampaignSortOption.createdDate),
        ),
        const SizedBox(width: 4),
        _SortChip(
          label: 'Aktiv',
          selected: viewModel.sortOption == CampaignSortOption.lastActive,
          C: C,
          onTap: () => viewModel.setSortOption(CampaignSortOption.lastActive),
        ),
        const SizedBox(width: 6),
        // ── Richtungs-Toggle ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () => viewModel.setSortAscending(ascending: !viewModel.sortAscending),
          child: Tooltip(
            message: viewModel.sortAscending ? 'Aufsteigend' : 'Absteigend',
            child: Icon(
              viewModel.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: C.textSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.C,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? C.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? C.accent.withValues(alpha: 0.4) : C.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? C.accent : C.textSoft,
            ),
          ),
        ),
      );
}
