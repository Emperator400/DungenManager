import 'package:flutter/material.dart';

/// Standardisierter Header für alle Cards
/// 
/// Zeigt Icon/Avatar, Titel, Meta-Info und Favorite-Button
class CardHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final List<Widget>? additionalInfo;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final VoidCallback? onMoreOptions;
  final List<PopupMenuItem<String>>? popupMenuItems;
  final Function(String)? onPopupMenuItemSelected;

  const CardHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.leadingWidget,
    this.iconColor,
    this.iconBackgroundColor,
    this.additionalInfo,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.onMoreOptions,
    this.popupMenuItems,
    this.onPopupMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Leading Icon/Avatar
        if (leadingWidget != null)
          leadingWidget!
        else if (leadingIcon != null)
          _buildLeadingIcon(context),
        
        const SizedBox(width: 12),
        
        // Titel und Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: iconColor ?? Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Zusätzliche Info
              if (additionalInfo != null && additionalInfo!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: additionalInfo!,
                ),
              ],
            ],
          ),
        ),
        
        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final defaultColor = iconColor ?? Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (iconBackgroundColor ?? defaultColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        leadingIcon,
        color: defaultColor,
        size: 24,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Favorite Button
        if (onFavoriteToggle != null)
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite 
                  ? Colors.amber[600] 
                  : Colors.grey[600],
              size: 20,
            ),
            onPressed: onFavoriteToggle,
            tooltip: isFavorite 
                ? 'Aus Favoriten entfernen' 
                : 'Zu Favoriten hinzufügen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        // More Options Button
        if (onMoreOptions != null || (popupMenuItems != null && popupMenuItems!.isNotEmpty))
          _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: onPopupMenuItemSelected,
      itemBuilder: (BuildContext context) => popupMenuItems ?? [],
      tooltip: 'Weitere Optionen',
    );
  }
}
