import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbarer Header für Item-Anzahl
/// 
/// Zeigt konsistent die Anzahl der Elemente mit optionalen
/// Aktionen und Sortier-Optionen an.
class ItemCountHeader extends StatelessWidget {
  /// Anzahl der Elemente
  final int itemCount;
  
  /// Singular-Form des Elementnamens
  final String singular;
  
  /// Plural-Form des Elementnamens
  final String? plural;
  
  /// Zusätzliche Aktionen
  final List<Widget>? actions;
  
  /// Zeige Sortier-Button
  final bool showSortButton;
  
  /// Aktuelle Sortier-Richtung
  final bool isAscending;
  
  /// Callback für Sortier-Button
  final VoidCallback? onSortToggle;
  
  /// Zusätzliche Nachricht
  final String? additionalInfo;

  const ItemCountHeader({
    super.key,
    required this.itemCount,
    required this.singular,
    this.plural,
    this.actions,
    this.showSortButton = false,
    this.isAscending = true,
    this.onSortToggle,
    this.additionalInfo,
  });

  /// Factory für einfache Item-Anzeige ohne Aktionen
  factory ItemCountHeader.simple({
    required int itemCount,
    required String singular,
    String? plural,
    String? additionalInfo,
    Key? key,
  }) {
    return ItemCountHeader(
      key: key,
      itemCount: itemCount,
      singular: singular,
      plural: plural,
      additionalInfo: additionalInfo,
    );
  }

  /// Factory mit Sortier-Button
  factory ItemCountHeader.withSort({
    required int itemCount,
    required String singular,
    String? plural,
    required bool isAscending,
    required VoidCallback onSortToggle,
    String? additionalInfo,
    Key? key,
  }) {
    return ItemCountHeader(
      key: key,
      itemCount: itemCount,
      singular: singular,
      plural: plural,
      isAscending: isAscending,
      onSortToggle: onSortToggle,
      showSortButton: true,
      additionalInfo: additionalInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Item-Anzahl Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getItemCountText(),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (additionalInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    additionalInfo!,
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Sortier-Button
          if (showSortButton && onSortToggle != null)
            _buildSortButton(context),
          
          // Zusätzliche Aktionen
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return Tooltip(
      message: isAscending ? 'Absteigend sortieren' : 'Aufsteigend sortieren',
      child: IconButton(
        icon: Icon(
          isAscending ? Icons.arrow_upward : Icons.arrow_downward,
          color: DnDTheme.ancientGold,
        ),
        onPressed: onSortToggle,
        tooltip: isAscending ? 'Absteigend' : 'Aufsteigend',
      ),
    );
  }

  String _getItemCountText() {
    final itemName = itemCount == 1 ? singular : (plural ?? '${singular}s');
    return '$itemCount $itemName';
  }
}
