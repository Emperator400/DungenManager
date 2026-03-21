import 'package:flutter/material.dart';
import '../../../models/campaign.dart';
import '../../../viewmodels/campaign_viewmodel.dart';
import '../base/unified_card_base.dart';
import '../base/card_content_widget.dart';
import '../base/card_metadata_widget.dart';
import '../shared/unified_card_theme.dart';

/// Unified Campaign Card
/// 
/// Kampagnen-Card mit vollständiger Logik
/// - Delete: Dialog + Operation über ViewModel
/// - Edit/Duplicate/ToggleActive: Callbacks vom Screen
class UnifiedCampaignCard extends UnifiedCardBase {
  final Campaign campaign;
  final CampaignViewModel viewModel;
  final VoidCallback? onNavigate;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleFavorite;

  const UnifiedCampaignCard({
    super.key,
    required this.campaign,
    required this.viewModel,
    this.onNavigate,
    this.onEdit,
    this.onDuplicate,
    this.onToggleFavorite,
    super.onTap,
    super.isSelected,
    super.showActions,
  });

  /// Prüft ob die Kampagne als Favorit markiert ist
  bool get isFavorite => campaign.isFavorite;

  @override
  Widget buildCardContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap ?? () => _navigateToCampaign(context),
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
                    color: UnifiedCardTheme.getIconBackgroundColor('campaign'),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: UnifiedCardTheme.getIconBackgroundColor('campaign').withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.campaign,
                      size: 36,
                      color: UnifiedCardTheme.getIconColor('campaign'),
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
                        campaign.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Hole dynamische Statistiken aus dem ViewModel
                          final stats = viewModel.getStatsForCampaign(campaign.id);
                          return Wrap(
                            spacing: 8,
                            children: [
                              _buildInfoChip(
                                Icons.people,
                                '${stats['heroCount'] ?? 0}',
                              ),
                              _buildInfoChip(
                                Icons.calendar_today,
                                '${stats['sessionCount'] ?? 0}',
                              ),
                              _buildInfoChip(
                                Icons.assessment,
                                '${stats['questCount'] ?? 0}',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Favorit-Stern
                if (onToggleFavorite != null)
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey[600],
                      size: 24,
                    ),
                    tooltip: isFavorite ? 'Als Favorit entfernen' : 'Als Favorit markieren',
                  ),
                
                // Einzelne Aktions-Schaltfläche
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 28,
                    color: Colors.grey[700],
                  ),
                  onSelected: (value) => _handlePopupMenuAction(context, value),
                  itemBuilder: (context) => _buildAllMenuItems(context),
                ),
              ],
            ),
            
            const SizedBox(height: UnifiedCardBase.defaultSpacing),
            
            // Content
            if (campaign.description.isNotEmpty)
              CardContentWidget(
                description: campaign.description,
                descriptionMaxLines: 2,
              ),
            
            const SizedBox(height: UnifiedCardBase.defaultSpacing),
            
            // Metadata
            Builder(
              builder: (context) {
                final stats = viewModel.getStatsForCampaign(campaign.id);
                return CardMetadataWidget(
                  createdAt: campaign.createdAt,
                  updatedAt: campaign.updatedAt,
                  status: campaign.statusDescription,
                  itemCount: stats['questCount'] ?? 0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    return '${campaign.typeDescription} • ${campaign.statusDescription}';
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

  List<PopupMenuEntry<String>> _buildAllMenuItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 12),
            Text('Bearbeiten'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 18),
            SizedBox(width: 12),
            Text('Duplizieren'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(
              Icons.delete,
              size: 18,
              color: UnifiedCardTheme.deleteActionColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Löschen',
              style: TextStyle(color: UnifiedCardTheme.deleteActionColor),
            ),
          ],
        ),
      ),
    ];
  }

  void _handlePopupMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        if (onEdit != null) {
          onEdit!();
        } else {
          _showNotImplementedMessage(context, 'Bearbeiten');
        }
        break;
      case 'duplicate':
        if (onDuplicate != null) {
          onDuplicate!();
        } else {
          _duplicateCampaign(context);
        }
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktion: $action')),
        );
    }
  }

  /// Navigation zur Kampagne
  void _navigateToCampaign(BuildContext context) async {
    if (onNavigate != null) {
      onNavigate!();
    }
  }

  /// Zeigt eine Nachricht für noch nicht implementierte Funktionen
  void _showNotImplementedMessage(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action... (noch nicht implementiert)')),
    );
  }

  /// Kampagne duplizieren
  Future<void> _duplicateCampaign(BuildContext context) async {
    try {
      await viewModel.duplicateCampaign(campaign);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kampagne dupliziert'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Duplizieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Kampagne löschen
  Future<void> _deleteCampaign() async {
    try {
      await viewModel.deleteCampaign(campaign);
    } catch (e) {
      // Error handling wird vom ViewModel übernommen
    }
  }


  /// Zeigt den Delete-Bestätigungsdialog an
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kampagne löschen',
          style: TextStyle(
            color: Color.fromARGB(255, 134, 37, 37),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Möchtest du die Kampagne "${campaign.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: const TextStyle(color: Colors.white70),
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color.fromARGB(255, 134, 37, 37),
            width: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteCampaign();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 134, 37, 37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
