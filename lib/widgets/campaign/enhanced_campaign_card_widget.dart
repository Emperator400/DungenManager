import 'package:flutter/material.dart';
import '../../models/campaign.dart';

/// Enhanced Campaign Card Widget mit modernem Design
class EnhancedCampaignCardWidget extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleFavorite;

  const EnhancedCampaignCardWidget({
    super.key,
    required this.campaign,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner-Bild oben (wenn verfügbar)
            if (campaign.settings.imageUrl != null) 
              _buildCampaignImage(context),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  _buildDescription(),
                  const SizedBox(height: 16),
                  _buildStatsRow(context),
                  if (campaign.availableMonsters.isNotEmpty ||
                      campaign.availableNpcs.isNotEmpty ||
                      campaign.availableItems.isNotEmpty ||
                      campaign.availableSpells.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAvailableResources(context),
                  ],
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campaign.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Status-Chip nur anzeigen, wenn kein Bild vorhanden
        if (campaign.settings.imageUrl == null) ...[
          _buildStatusChip(context),
          const SizedBox(height: 6),
        ],
        _buildMetadataRow(context),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    String statusText;
    
    // Echte Status-Auswertung basierend auf campaign.status
    switch (campaign.status) {
      case CampaignStatus.planning:
        chipColor = Colors.grey;
        statusText = 'Planung';
        break;
      case CampaignStatus.active:
        chipColor = Colors.green;
        statusText = 'Aktiv';
        break;
      case CampaignStatus.paused:
        chipColor = Colors.orange;
        statusText = 'Pausiert';
        break;
      case CampaignStatus.completed:
        chipColor = Colors.blue;
        statusText = 'Abgeschlossen';
        break;
      case CampaignStatus.cancelled:
        chipColor = Colors.red;
        statusText = 'Abgebrochen';
        break;
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    return Row(
      children: [
        _buildMetadataItem(
          context,
          Icons.calendar_today,
          _formatDate(campaign.createdAt),
          'Erstellt',
        ),
        const SizedBox(width: 12),
        _buildMetadataItem(
          context,
          Icons.update,
          _formatDate(campaign.updatedAt),
          'Aktualisiert',
        ),
        if (campaign.playerCount > 0) ...[
          const SizedBox(width: 12),
          _buildMetadataItem(
            context,
            Icons.people,
            '${campaign.playerCount}',
            'Spieler',
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          // Hauptbild mit Fallback
          Image.network(
            campaign.settings.imageUrl!,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.castle,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        campaign.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            },
          ),
          
          // Overlay für bessere Text-Lesbarkeit
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          
          // Status-Overlay oben rechts
          Positioned(
            top: 8,
            right: 8,
            child: _buildStatusChip(context),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'vor ${difference.inMinutes} Min.';
      }
      return 'vor ${difference.inHours} Std.';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'vor $weeks ${weeks == 1 ? 'Woche' : 'Wochen'}';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }


  Widget _buildDescription() => Text(
    campaign.description,
    style: const TextStyle(
      fontSize: 14,
      height: 1.4,
    ),
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
  );

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          context,
          Icons.pets,
          campaign.availableMonsters.length.toString(),
          'Monster',
          Colors.red,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          Icons.people,
          campaign.availableNpcs.length.toString(),
          'NPCs',
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          Icons.inventory_2,
          campaign.availableItems.length.toString(),
          'Items',
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          Icons.auto_stories,
          campaign.availableSpells.length.toString(),
          'Spells',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAvailableResources(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verfügbare Ressourcen:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...campaign.availableMonsters.take(3).map((monster) => _buildResourceChip(
              context,
              monster,
              Icons.pets,
              Colors.red,
            )),
            ...campaign.availableNpcs.take(3).map((npc) => _buildResourceChip(
              context,
              npc,
              Icons.people,
              Colors.blue,
            )),
            ...campaign.availableItems.take(3).map((item) => _buildResourceChip(
              context,
              item,
              Icons.inventory_2,
              Colors.green,
            )),
            ...campaign.availableSpells.take(3).map((spell) => _buildResourceChip(
              context,
              spell,
              Icons.auto_stories,
              Colors.purple,
            )),
            if (campaign.availableMonsters.length > 3 ||
                campaign.availableNpcs.length > 3 ||
                campaign.availableItems.length > 3 ||
                campaign.availableSpells.length > 3)
              _buildMoreChip(context),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceChip(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
  ) => Chip(
    label: Text(
      name,
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
    ),
    avatar: Icon(icon, size: 16, color: color),
    backgroundColor: color.withValues(alpha: 0.1),
    side: BorderSide(color: color.withValues(alpha: 0.3)),
  );

  Widget _buildMoreChip(BuildContext context) => Chip(
    label: const Text(
      '...',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    backgroundColor: Colors.grey.withValues(alpha: 0.1),
  );

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Bearbeiten'),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    _showDeleteStepDialog(context, 0);
  }

  void _showDeleteStepDialog(BuildContext context, int clickCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_getDialogTitle(clickCount)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getDialogMessage(clickCount)),
            if (clickCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Noch ${3 - clickCount} Klicks zum endgültigen Löschen',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              if (clickCount < 2) {
                // Nächster Schritt
                _showDeleteStepDialog(context, clickCount + 1);
              } else {
                // Letzter Schritt - wirklich löschen
                onDelete?.call();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: clickCount > 0 ? Colors.red : Colors.orange,
              backgroundColor: clickCount > 0 
                  ? Colors.red.withValues(alpha: 0.1) 
                  : Colors.orange.withValues(alpha: 0.1),
            ),
            child: Text(
              clickCount >= 2 
                  ? 'LETZTER KLICK (${3 - clickCount})'
                  : 'Löschen (${3 - clickCount})',
            ),
          ),
        ],
      ),
    );
  }

  String _getDialogTitle(int clickCount) {
    switch (clickCount) {
      case 0:
        return 'Löschen bestätigen';
      case 1:
        return 'Bist du sicher?';
      case 2:
        return 'LETZTE WARNUNG!';
      default:
        return 'Löschen bestätigen';
    }
  }

  String _getDialogMessage(int clickCount) {
    switch (clickCount) {
      case 0:
        return 'Möchtest du die Campaign "${campaign.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
      case 1:
        return 'Dies ist dein erster Klick zum Löschen. Die Kampagne wird nach 3 Klicks endgültig gelöscht.';
      case 2:
        return 'LETZTER Klick! Die Kampagne "${campaign.title}" wird IM NÄCHSTEN SCHRITT unwiderruflich gelöscht!';
      default:
        return 'Möchtest du die Campaign "${campaign.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
    }
  }
}
