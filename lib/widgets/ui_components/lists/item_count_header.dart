import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ItemCountHeader extends StatelessWidget {
  const ItemCountHeader({
    required this.itemCount,
    required this.singular,
    super.key,
    this.plural,
    this.actions,
    this.showSortButton = false,
    this.isAscending = true,
    this.onSortToggle,
    this.additionalInfo,
  });

  factory ItemCountHeader.simple({
    required int itemCount,
    required String singular,
    String? plural,
    String? additionalInfo,
    Key? key,
  }) =>
      ItemCountHeader(
        key: key,
        itemCount: itemCount,
        singular: singular,
        plural: plural,
        additionalInfo: additionalInfo,
      );

  factory ItemCountHeader.withSort({
    required int itemCount,
    required String singular,
    required bool isAscending,
    required VoidCallback onSortToggle,
    String? plural,
    String? additionalInfo,
    Key? key,
  }) =>
      ItemCountHeader(
        key: key,
        itemCount: itemCount,
        singular: singular,
        plural: plural,
        isAscending: isAscending,
        onSortToggle: onSortToggle,
        showSortButton: true,
        additionalInfo: additionalInfo,
      );

  final int itemCount;
  final String singular;
  final String? plural;
  final List<Widget>? actions;
  final bool showSortButton;
  final bool isAscending;
  final VoidCallback? onSortToggle;
  final String? additionalInfo;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemCountText(),
                  style: TextStyle(color: C.textMid, fontWeight: FontWeight.w500, fontSize: 14),
                ),
                if (additionalInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(additionalInfo!, style: TextStyle(color: C.textSoft, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (showSortButton && onSortToggle != null)
            Tooltip(
              message: isAscending ? 'Absteigend sortieren' : 'Aufsteigend sortieren',
              child: IconButton(
                icon: Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: C.amber),
                onPressed: onSortToggle,
              ),
            ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  String _itemCountText() {
    final name = itemCount == 1 ? singular : (plural ?? '${singular}s');
    return '$itemCount $name';
  }
}
