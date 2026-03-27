import 'package:flutter/material.dart';
import '../../../models/creature.dart';
import '../../../theme/dnd_theme.dart';
import '../base/unified_card_base.dart';
import '../base/card_header_widget.dart';
import '../base/card_content_widget.dart';
import '../base/card_actions_widget.dart';
import '../base/card_metadata_widget.dart';
import '../shared/unified_card_theme.dart';
import '../chips/unified_info_chip.dart';

/// Unified Creature Card für das Bestiary
/// 
/// Erbt von UnifiedCardBase und nutzt die einheitlichen Chip-Komponenten
class UnifiedCreatureCard extends UnifiedCardBase {
  final Creature creature;
  final VoidCallback? onTap;

  const UnifiedCreatureCard({
    super.key,
    required this.creature,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    this.onTap,
    super.isFavorite,
    super.isSelected,
    super.showActions,
    super.elevation,
    super.margin,
    super.borderRadius,
  });

  @override
  bool get isFavorite => creature.isFavorite;

  @override
  Color getAccentColor(BuildContext context) {
    return _getSourceColor(creature.sourceType);
  }

  /// Gibt die Farbe basierend auf dem Quelltyp zurück
  Color _getSourceColor(String sourceType) {
    switch (sourceType) {
      case 'official':
        return DnDTheme.arcaneBlue;
      case 'custom':
        return DnDTheme.successGreen;
      case 'hybrid':
        return DnDTheme.mysticalPurple;
      default:
        return DnDTheme.slateGrey;
    }
  }

  /// Gibt das Icon basierend auf dem Quelltyp zurück
  IconData _getSourceIcon(String sourceType) {
    switch (sourceType) {
      case 'official':
        return Icons.public;
      case 'custom':
        return Icons.person;
      case 'hybrid':
        return Icons.sync;
      default:
        return Icons.pets;
    }
  }

  /// Gibt das Icon für den Kreatur-Typ zurück
  IconData _getCreatureTypeIcon(String? type) {
    if (type == null) return Icons.help_outline;
    
    final lowerType = type.toLowerCase();
    switch (lowerType) {
      case 'dragon':
      case 'drache':
        return Icons.local_fire_department; // Ersatzicon für dragon
      case 'undead':
      case 'untot':
        return Icons.nightlife;
      case 'fiend':
      case 'dämon':
      case 'teufel':
        return Icons.whatshot;
      case 'beast':
      case 'tier':
        return Icons.pets;
      case 'humanoid':
        return Icons.person;
      case 'giant':
      case 'riese':
        return Icons.accessibility_new;
      case 'fey':
        return Icons.auto_awesome;
      case 'construct':
        return Icons.smart_toy;
      case 'elemental':
      case 'elementar':
        return Icons.bubble_chart;
      case 'ooze':
        return Icons.water_drop;
      case 'plant':
      case 'pflanze':
        return Icons.grass;
      case 'aberration':
        return Icons.bug_report;
      case 'celestial':
        return Icons.star;
      case 'monstrosity':
        return Icons.warning;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Name und Typ
          CardHeaderWidget(
            title: creature.name,
            subtitle: _buildSubtitle(),
            leadingIcon: _getSourceIcon(creature.sourceType),
            iconColor: _getSourceColor(creature.sourceType),
            iconBackgroundColor: _getSourceColor(creature.sourceType).withOpacity(0.2),
            additionalInfo: [
              if (creature.sourceType == 'official')
                UnifiedInfoChip.tag(
                  tag: 'Offiziell',
                  icon: Icons.verified,
                  color: DnDTheme.arcaneBlue,
                ),
              if (creature.sourceType == 'custom')
                UnifiedInfoChip.tag(
                  tag: 'Eigen',
                  icon: Icons.person,
                  color: DnDTheme.successGreen,
                ),
            ],
            onFavoriteToggle: onToggleFavorite,
            isFavorite: isFavorite,
            popupMenuItems: _buildPopupMenuItems(context),
            onPopupMenuItemSelected: (value) => _handlePopupMenuAction(context, value),
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Kampf-Statistiken
          _buildCombatStatsRow(),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Typ und Größe
          if (creature.type != null || creature.size != null)
            _buildTypeAndSizeRow(),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Beschreibung (falls vorhanden)
          if (creature.description != null && creature.description!.isNotEmpty)
            CardContentWidget(
              description: creature.description!,
              descriptionMaxLines: 2,
            ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Metadaten
          CardMetadataWidget(
            customMetadata: _buildMetadata(),
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Aktionen
          CardActionsWidget(
            onEdit: onEdit,
            onDelete: onDelete,
            onQuickAction: onTap,
            alignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    
    if (creature.type != null) {
      var typeText = creature.type!;
      if (creature.subtype != null) {
        typeText += ' (${creature.subtype})';
      }
      parts.add(typeText);
    }
    
    if (creature.challengeRating != null) {
      parts.add('CR ${creature.challengeRating}');
    }
    
    return parts.join(' • ');
  }

  Widget _buildCombatStatsRow() {
    final stats = <UnifiedStatItem>[];
    
    // HP
    stats.add(UnifiedStatItem.hp(
      creature.currentHp,
      creature.maxHp,
    ));
    
    // AC
    stats.add(UnifiedStatItem.ac(creature.armorClass));
    
    // Initiative (falls vorhanden)
    final initMod = ((creature.dexterity - 10) / 2).floor();
    stats.add(UnifiedStatItem.initiative(initMod));
    
    // Speed als String parsen für Anzeige (nicht als Zahl)
    // Wir zeigen die Geschwindigkeit als Info-Chip statt als StatItem
    
    return UnifiedStatsRow(stats: stats);
  }

  Widget _buildTypeAndSizeRow() {
    final chips = <Widget>[];
    
    // Kreatur-Typ
    if (creature.type != null) {
      chips.add(
        UnifiedInfoChip.type(
          type: creature.type!,
          icon: _getCreatureTypeIcon(creature.type),
          color: UnifiedCardTheme.getIconColor('creature'),
        ),
      );
    }
    
    // Größe
    if (creature.size != null) {
      chips.add(
        UnifiedInfoChip.tag(
          tag: creature.size!,
          icon: Icons.straighten,
          color: Colors.teal,
        ),
      );
    }
    
    // Alignment (falls vorhanden)
    if (creature.alignment != null && creature.alignment!.isNotEmpty) {
      chips.add(
        UnifiedInfoChip.alignment(
          alignment: creature.alignment!,
        ),
      );
    }
    
    // Speed anzeigen
    if (creature.speed.isNotEmpty) {
      chips.add(
        UnifiedInfoChip.combat(
          label: 'Bew.',
          value: creature.speed,
          icon: Icons.directions_run,
          color: Colors.green,
        ),
      );
    }
    
    return UnifiedChipRow(chips: chips);
  }

  Map<String, String> _buildMetadata() {
    final metadata = <String, String>{};
    
    if (creature.challengeRating != null) {
      metadata['CR'] = '${creature.challengeRating}';
    }
    
    if (creature.armorClass > 0) {
      metadata['RK'] = '${creature.armorClass}';
    }
    
    if (creature.gold > 0 || creature.silver > 0 || creature.copper > 0) {
      final total = creature.gold + (creature.silver / 10) + (creature.copper / 100);
      metadata['Gold'] = total.toStringAsFixed(1);
    }
    
    return metadata;
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    return [
      const PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 16),
            SizedBox(width: 8),
            Text('Duplizieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.file_download, size: 16),
            SizedBox(width: 8),
            Text('Exportieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'addToEncounter',
        child: Row(
          children: [
            Icon(Icons.group_add, size: 16),
            SizedBox(width: 8),
            Text('Zu Encounter hinzufügen'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share, size: 16),
            SizedBox(width: 8),
            Text('Teilen'),
          ],
        ),
      ),
    ];
  }

  void _handlePopupMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kreatur duplizieren...')),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kreatur exportieren...')),
        );
        break;
      case 'addToEncounter':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zu Encounter hinzufügen...')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kreatur teilen...')),
        );
        break;
    }
  }
}