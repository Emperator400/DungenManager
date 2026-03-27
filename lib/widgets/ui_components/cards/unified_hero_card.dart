import 'package:flutter/material.dart';
import '../../../models/player_character.dart';
import '../../../theme/dnd_theme.dart';
import '../../../services/armor_calculation_service.dart';
import '../chips/unified_info_chip.dart';

/// Unified Hero Card
/// 
/// Erweiterte Heldenkarte mit ArmorCalculationService, 
/// UnifiedInfoChip Integration und DnDTheme-Styling
class UnifiedHeroCard extends StatefulWidget {
  final PlayerCharacter hero;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onQuickAction;
  final bool isSelected;
  final bool showActions;

  const UnifiedHeroCard({
    super.key,
    required this.hero,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.onQuickAction,
    this.isSelected = false,
    this.showActions = true,
  });

  @override
  State<UnifiedHeroCard> createState() => _UnifiedHeroCardState();
}

class _UnifiedHeroCardState extends State<UnifiedHeroCard> {
  final ArmorCalculationService _armorService = ArmorCalculationService();
  ArmorClassResult? _armorResult;
  bool _isLoadingAc = true;

  @override
  void initState() {
    super.initState();
    _loadArmorClass();
  }

  @override
  void didUpdateWidget(UnifiedHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hero.id != widget.hero.id) {
      _loadArmorClass();
    }
  }

  Future<void> _loadArmorClass() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingAc = true;
    });

    try {
      final result = await _armorService.calculateArmorClass(
        characterId: widget.hero.id,
        dexterity: widget.hero.dexterity,
        baseArmorClass: 10,
      );
      
      if (mounted) {
        setState(() {
          _armorResult = result;
          _isLoadingAc = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _armorResult = null;
          _isLoadingAc = false;
        });
      }
    }
  }

  int _calculateModifier(int score) {
    return ((score - 10) / 2).floor();
  }

  Color _getClassColor() {
    final className = widget.hero.className.toLowerCase();
    switch (className) {
      case 'barbarian':
        return Colors.red.shade700;
      case 'bard':
        return Colors.purple.shade400;
      case 'cleric':
        return Colors.grey.shade300;
      case 'druid':
        return Colors.orange.shade600;
      case 'fighter':
        return Colors.brown.shade600;
      case 'monk':
        return Colors.blue.shade300;
      case 'paladin':
        return Colors.pink.shade300;
      case 'ranger':
        return Colors.green.shade600;
      case 'rogue':
        return Colors.grey.shade600;
      case 'sorcerer':
        return Colors.red.shade400;
      case 'warlock':
        return Colors.purple.shade700;
      case 'wizard':
        return Colors.blue.shade600;
      default:
        return DnDTheme.mysticalPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor();
    
    return Container(
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: widget.isSelected ? DnDTheme.ancientGold : classColor,
        isLegendary: widget.hero.isFavorite,
      ).copyWith(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(DnDTheme.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === HEADER: Avatar und Basis-Info ===
                _buildHeader(classColor),
                
                const Divider(
                  color: DnDTheme.slateGrey,
                  height: 24,
                  thickness: 1,
                ),
                
                // === KAMPF-CHIPS ===
                _buildCombatChips(),
                
                const SizedBox(height: DnDTheme.sm),
                
                // === ATTRIBUT-CHIPS ===
                _buildAttributeChips(),
                
                const SizedBox(height: DnDTheme.sm),
                
                // === WÄHRUNGS-CHIPS ===
                _buildCurrencyChips(),
                
                // === GESINNUNG (falls vorhanden) ===
                if (widget.hero.alignment != null && widget.hero.alignment!.isNotEmpty) ...[
                  const SizedBox(height: DnDTheme.sm),
                  _buildAlignmentChip(),
                ],
                
                // === BESCHREIBUNG (falls vorhanden) ===
                if (widget.hero.description != null && widget.hero.description!.isNotEmpty) ...[
                  const SizedBox(height: DnDTheme.sm),
                  _buildDescription(),
                ],
                
                // === AKTIONS-LEISTE ===
                if (widget.showActions) ...[
                  const SizedBox(height: DnDTheme.sm),
                  _buildActionBar(classColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header mit Avatar, Name und Basis-Info
  Widget _buildHeader(Color classColor) {
    return Row(
      children: [
        // Avatar mit Level-Badge
        _buildAvatar(),
        
        const SizedBox(width: 12),
        
        // Name und Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name mit Favorit-Stern
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.hero.name,
                      style: DnDTheme.headline3.copyWith(
                        fontSize: 18,
                        color: widget.isSelected ? DnDTheme.ancientGold : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onToggleFavorite != null)
                    IconButton(
                      icon: Icon(
                        widget.hero.isFavorite ? Icons.star : Icons.star_border,
                        color: widget.hero.isFavorite 
                            ? DnDTheme.ancientGold 
                            : DnDTheme.stoneGrey,
                        size: 22,
                      ),
                      onPressed: widget.onToggleFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 2),
              
              // Klasse und Rasse
              Text(
                '${widget.hero.raceName} ${widget.hero.className}',
                style: DnDTheme.bodyText2.copyWith(
                  fontSize: 13,
                  color: classColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 2),
              
              // Spielername
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.hero.playerName,
                    style: DnDTheme.caption.copyWith(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Avatar mit Level-Badge
  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DnDTheme.getMysticalGradient(
              startColor: _getClassColor(),
              endColor: DnDTheme.slateGrey,
            ),
            border: Border.all(
              color: DnDTheme.ancientGold.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              widget.hero.name.isNotEmpty ? widget.hero.name[0].toUpperCase() : '?',
              style: DnDTheme.headline2.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
        ),
        // Level-Badge
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DnDTheme.dungeonBlack,
                width: 1,
              ),
            ),
            child: Text(
              'Lvl ${widget.hero.level}',
              style: DnDTheme.caption.copyWith(
                fontSize: 9,
                color: DnDTheme.dungeonBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kampf-Stat Chips (AC, HP, INIT, SPEED)
  Widget _buildCombatChips() {
    final dexMod = _calculateModifier(widget.hero.dexterity);
    final initiative = dexMod + widget.hero.initiativeBonus;
    
    // AC-Wert: Berechnet oder Fallback
    String acDisplay;
    String? acTooltip;
    
    if (_isLoadingAc) {
      acDisplay = '${widget.hero.armorClass}';
      acTooltip = 'Wird berechnet...';
    } else if (_armorResult != null) {
      acDisplay = '${_armorResult!.totalAc}';
      if (_armorResult!.formula.isNotEmpty) {
        acTooltip = _armorResult!.formula;
      }
    } else {
      acDisplay = '${widget.hero.armorClass}';
    }
    
    return UnifiedChipSection(
      title: 'Kampfwerte',
      titleIcon: Icons.shield,
      titleColor: DnDTheme.ancientGold,
      chips: [
        // AC-Chip mit Tooltip für Formel
        Tooltip(
          message: acTooltip ?? 'Basis AC',
          child: UnifiedInfoChip.combat(
            label: 'AC',
            value: acDisplay,
            icon: Icons.shield_outlined,
            color: DnDTheme.infoBlue,
            onTap: widget.onEdit,
          ),
        ),
        UnifiedInfoChip.combat(
          label: 'HP',
          value: '${widget.hero.maxHp}',
          icon: Icons.favorite_outlined,
          color: DnDTheme.successGreen,
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.combat(
          label: 'INIT',
          value: initiative >= 0 ? '+$initiative' : '$initiative',
          icon: Icons.bolt_outlined,
          color: DnDTheme.arcaneBlue,
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.combat(
          label: 'SPEED',
          value: '${widget.hero.speed} ft',
          icon: Icons.directions_run_outlined,
          color: DnDTheme.mysticalPurple,
          onTap: widget.onEdit,
        ),
      ],
    );
  }

  /// Alle 6 Attribut-Chips
  Widget _buildAttributeChips() {
    return UnifiedChipSection(
      title: 'Attribute',
      titleIcon: Icons.auto_graph,
      titleColor: DnDTheme.ancientGold,
      chips: [
        UnifiedInfoChip.attribute(
          name: 'STR',
          value: widget.hero.strength,
          modifier: _calculateModifier(widget.hero.strength),
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.attribute(
          name: 'DEX',
          value: widget.hero.dexterity,
          modifier: _calculateModifier(widget.hero.dexterity),
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.attribute(
          name: 'CON',
          value: widget.hero.constitution,
          modifier: _calculateModifier(widget.hero.constitution),
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.attribute(
          name: 'INT',
          value: widget.hero.intelligence,
          modifier: _calculateModifier(widget.hero.intelligence),
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.attribute(
          name: 'WIS',
          value: widget.hero.wisdom,
          modifier: _calculateModifier(widget.hero.wisdom),
          onTap: widget.onEdit,
        ),
        UnifiedInfoChip.attribute(
          name: 'CHA',
          value: widget.hero.charisma,
          modifier: _calculateModifier(widget.hero.charisma),
          onTap: widget.onEdit,
        ),
      ],
    );
  }

  /// Währungs-Chips
  Widget _buildCurrencyChips() {
    final hasCurrency = widget.hero.gold > 0 || widget.hero.silver > 0 || widget.hero.copper > 0;
    
    if (!hasCurrency) {
      return const SizedBox.shrink();
    }
    
    final chips = <Widget>[];
    
    if (widget.hero.gold > 0) {
      chips.add(UnifiedInfoChip.currency(
        label: '',
        amount: widget.hero.gold,
        icon: Icons.monetization_on,
        color: Colors.amber,
      ));
    }
    
    if (widget.hero.silver > 0) {
      chips.add(UnifiedInfoChip.currency(
        label: '',
        amount: widget.hero.silver,
        icon: Icons.monetization_on_outlined,
        color: Colors.blueGrey,
      ));
    }
    
    if (widget.hero.copper > 0) {
      chips.add(UnifiedInfoChip.currency(
        label: '',
        amount: widget.hero.copper,
        icon: Icons.circle_outlined,
        color: Colors.brown,
      ));
    }
    
    return UnifiedChipSection(
      title: 'Vermögen',
      titleIcon: Icons.account_balance_wallet_outlined,
      titleColor: DnDTheme.ancientGold,
      chips: chips,
    );
  }

  /// Gesinnungs-Chip
  Widget _buildAlignmentChip() {
    return UnifiedChipRow(
      chips: [
        UnifiedInfoChip.alignment(
          alignment: widget.hero.alignment!,
          onTap: widget.onEdit,
        ),
      ],
    );
  }

  /// Beschreibungstext
  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        widget.hero.description!,
        style: DnDTheme.bodyText2.copyWith(
          fontSize: 12,
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Aktionsleiste mit Buttons
  Widget _buildActionBar(Color classColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onQuickAction != null)
          TextButton.icon(
            onPressed: widget.onQuickAction,
            icon: const Icon(Icons.more_horiz, size: 18),
            label: const Text('Aktionen'),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.mysticalPurple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        if (widget.onEdit != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Bearbeiten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: classColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              ),
            ),
          ),
        ],
        if (widget.onDelete != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete_outline, color: DnDTheme.errorRed),
            tooltip: 'Löschen',
          ),
        ],
      ],
    );
  }
}