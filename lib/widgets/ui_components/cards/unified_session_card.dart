import 'package:flutter/material.dart';
import '../base/unified_card_base.dart';
import '../../../models/session.dart';

/// Unified Session Card
/// 
/// Zeigt eine Spielsitzung mit allen relevanten Informationen
/// Verwendet das Unified Card System für konsistentes Design
class UnifiedSessionCard extends UnifiedCardBase {
  final Session session;
  final int sessionNumber;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UnifiedSessionCard({
    super.key,
    required this.session,
    required this.sessionNumber,
    this.onTap,
    this.onPlay,
    this.onEdit,
    this.onDelete,
  });

  @override
  String get cardType => 'session';

  @override
  IconData get leadingIcon => Icons.event_note;

  @override
  String get title => session.title;

  @override
  String? get subtitle => 'Sitzung $sessionNumber';

  @override
  String? get description {
    if (session.liveNotes.isNotEmpty) {
      return session.liveNotes.length > 100 
          ? '${session.liveNotes.substring(0, 100)}...' 
          : session.liveNotes;
    }
    return null;
  }

  @override
  List<String>? get tags {
    List<String> tags = [];
    
    // Status-Tag
    tags.add(_getSessionStatusText());
    
    return tags;
  }

  @override
  Widget? buildAdditionalHeaderContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play Button
        if (onPlay != null)
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 20),
            onPressed: onPlay,
            tooltip: 'Sitzung starten',
            color: Colors.amber,
          ),
      ],
    );
  }

  @override
  List<PopupMenuEntry<String>> get popupMenuItems {
    List<PopupMenuEntry<String>> items = [];
    
    if (onPlay != null) {
      items.add(const PopupMenuItem(
        value: 'play',
        child: Row(
          children: [
            Icon(Icons.play_arrow, size: 16),
            SizedBox(width: 8),
            Text('Starten'),
          ],
        ),
      ));
    }
    
    if (onEdit != null) {
      items.add(const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 16),
            SizedBox(width: 8),
            Text('Bearbeiten'),
          ],
        ),
      ));
    }
    
    if (onDelete != null) {
      items.add(const PopupMenuDivider());
      items.add(const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16, color: Colors.red),
            SizedBox(width: 8),
            Text('Löschen', style: TextStyle(color: Colors.red)),
          ],
        ),
      ));
    }
    
    return items;
  }

  @override
  void handlePopupMenuItem(String value) {
    switch (value) {
      case 'play':
        onPlay?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  @override
  void onTapAction() {
    onTap?.call();
  }

  @override
  Widget? buildMetadata(BuildContext context) {
    return Row(
      children: [
        // Spieldauer
        _buildMetadataItem(
          context,
          Icons.timer,
          _formatDuration(session.inGameTimeInMinutes),
        ),
        // Status
        _buildMetadataItem(
          context,
          Icons.circle,
          _getSessionStatusText(),
          color: _getSessionStatusColor(),
        ),
      ],
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: color ?? Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.amber,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '${mins}min';
  }

  String _getSessionStatusText() {
    // Sessions sind standardmäßig aktiv, es sei denn es gibt einen Indikator für Abgeschlossen
    return 'Aktiv';
  }

  Color _getSessionStatusColor() {
    return Colors.amber;
  }

  @override
  Widget buildCardContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominenter Icon Header
            Row(
              children: [
                // Großes Icon mit Hintergrund
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      leadingIcon,
                      size: 36,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Titel und Info rechts daneben
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.timer,
                            _formatDuration(session.inGameTimeInMinutes),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
            // Play Button im Header
                if (onPlay != null)
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 28),
                    onPressed: onPlay,
                    tooltip: 'Sitzung starten',
                    color: Colors.amber,
                  ),
                // Bearbeiten Button direkt sichtbar
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 24),
                    onPressed: onEdit,
                    tooltip: 'Bearbeiten',
                    color: Colors.blue,
                  ),
              ],
            ),
            
            const SizedBox(height: UnifiedCardBase.defaultSpacing),
            
            // Content
            if (description != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            const SizedBox(height: UnifiedCardBase.defaultSpacing),
            
            // Tags
            if (tags != null && tags!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags!.map((tag) => _buildTagChip(tag)).toList(),
              ),
            
            const SizedBox(height: UnifiedCardBase.defaultSpacing),
            
            // Metadata
            buildMetadata(context) ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.amber,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
