import 'package:flutter/material.dart';
import '../../models/player_character.dart';
import '../../theme/app_theme.dart';
import '../../services/armor_calculation_service.dart';
import 'character_list_helpers.dart';
import 'hero_avatar_widget.dart';
import 'pc_info_chip.dart';

/// Moderne Heldenkarte mit UI-Chips für alle relevanten Informationen
class EnhancedHeroCardWidget extends StatefulWidget {
  final PlayerCharacter character;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onQuickAction;
  final bool isSelected;

  const EnhancedHeroCardWidget({
    super.key,
    required this.character,
    this.onTap,
    this.onEdit,
    this.onFavoriteToggle,
    this.onQuickAction,
    this.isSelected = false,
  });

  @override
  State<EnhancedHeroCardWidget> createState() => _EnhancedHeroCardWidgetState();
}

class _EnhancedHeroCardWidgetState extends State<EnhancedHeroCardWidget> {
  final ArmorCalculationService _armorService = ArmorCalculationService();
  ArmorClassResult? _armorResult;
  bool _isLoadingAc = true;

  @override
  void initState() {
    super.initState();
    _loadArmorClass();
  }

  @override
  void didUpdateWidget(EnhancedHeroCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Neu laden wenn sich der Character ändert
    if (oldWidget.character.id != widget.character.id) {
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
        characterId: widget.character.id,
        dexterity: widget.character.dexterity,
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

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final classColor = CharacterListHelpers.getClassColor(widget.character.className);

    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: widget.isSelected ? C.amber : classColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === HEADER: Avatar und Basis-Info ===
                _buildHeader(classColor, C),

                Divider(
                  color: C.border,
                  height: 24,
                  thickness: 1,
                ),

                // === KAMPF-CHIPS ===
                _buildCombatChips(C),

                const SizedBox(height: 8.0),

                // === ATTRIBUT-CHIPS ===
                _buildAttributeChips(),

                const SizedBox(height: 8.0),

                // === WÄHRUNGS-CHIPS ===
                _buildCurrencyChips(),

                // === GESINNUNG (falls vorhanden) ===
                if (widget.character.alignment != null && widget.character.alignment!.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  _buildAlignmentChip(),
                ],

                // === BESCHREIBUNG (falls vorhanden) ===
                if (widget.character.description != null && widget.character.description!.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  _buildDescription(C),
                ],

                // === AKTIONS-LEISTE ===
                const SizedBox(height: 8.0),
                _buildActionBar(classColor, C),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header mit Avatar, Name und Basis-Info
  Widget _buildHeader(Color classColor, AppColorsExtension C) {
    return Row(
      children: [
        // Avatar mit Level-Badge
        HeroAvatarWidget(
          character: widget.character,
          size: 56,
          showLevelBadge: true,
          showAlignment: false,
        ),

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
                      widget.character.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected ? C.amber : C.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        widget.character.isFavorite ? Icons.star : Icons.star_border,
                        color: widget.character.isFavorite
                            ? C.amber
                            : C.bgActive,
                        size: 22,
                      ),
                      onPressed: widget.onFavoriteToggle,
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
                '${widget.character.raceName} ${widget.character.className}',
                style: TextStyle(
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
                    color: C.textSoft,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.character.playerName,
                    style: TextStyle(
                      fontSize: 12,
                      color: C.textSoft,
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

  /// Kampf-Stat Chips (AC, HP, INIT, SPEED)
  Widget _buildCombatChips(AppColorsExtension C) {
    final dexMod = CharacterListHelpers.getModifier(widget.character.dexterity);
    final initiative = dexMod + widget.character.initiativeBonus;
    final initText = initiative >= 0 ? '+$initiative' : '$initiative';

    // AC-Wert: Berechnet oder Fallback
    String acDisplay;
    String? acTooltip;

    if (_isLoadingAc) {
      acDisplay = '${widget.character.armorClass}';
      acTooltip = 'Wird berechnet...';
    } else if (_armorResult != null) {
      acDisplay = '${_armorResult!.totalAc}';
      if (_armorResult!.formula.isNotEmpty) {
        acTooltip = _armorResult!.formula;
      }
    } else {
      acDisplay = '${widget.character.armorClass}';
    }

    return PcChipSection(
      title: 'Kampfwerte',
      titleIcon: Icons.shield,
      chips: [
        // AC-Chip mit Tooltip für Formel
        Tooltip(
          message: acTooltip ?? 'Basis AC',
          child: PcInfoChip.combat(
            label: 'AC',
            value: acDisplay,
            icon: Icons.shield_outlined,
            color: C.accent,
            onTap: widget.onEdit,
          ),
        ),
        PcInfoChip.combat(
          label: 'HP',
          value: '${widget.character.maxHp}',
          icon: Icons.favorite_outlined,
          color: C.green,
          onTap: widget.onEdit,
        ),
        PcInfoChip.combat(
          label: 'INIT',
          value: initText,
          icon: Icons.bolt_outlined,
          color: C.accent,
          onTap: widget.onEdit,
        ),
        PcInfoChip.combat(
          label: 'SPEED',
          value: '${widget.character.speed} ft',
          icon: Icons.directions_run_outlined,
          color: C.accent,
          onTap: widget.onEdit,
        ),
      ],
    );
  }

  /// Alle 6 Attribut-Chips
  Widget _buildAttributeChips() {
    return PcChipSection(
      title: 'Attribute',
      titleIcon: Icons.auto_graph,
      chips: [
        PcInfoChip.attribute(
          name: 'STR',
          value: widget.character.strength,
          modifier: CharacterListHelpers.getModifier(widget.character.strength),
          onTap: widget.onEdit,
        ),
        PcInfoChip.attribute(
          name: 'DEX',
          value: widget.character.dexterity,
          modifier: CharacterListHelpers.getModifier(widget.character.dexterity),
          onTap: widget.onEdit,
        ),
        PcInfoChip.attribute(
          name: 'CON',
          value: widget.character.constitution,
          modifier: CharacterListHelpers.getModifier(widget.character.constitution),
          onTap: widget.onEdit,
        ),
        PcInfoChip.attribute(
          name: 'INT',
          value: widget.character.intelligence,
          modifier: CharacterListHelpers.getModifier(widget.character.intelligence),
          onTap: widget.onEdit,
        ),
        PcInfoChip.attribute(
          name: 'WIS',
          value: widget.character.wisdom,
          modifier: CharacterListHelpers.getModifier(widget.character.wisdom),
          onTap: widget.onEdit,
        ),
        PcInfoChip.attribute(
          name: 'CHA',
          value: widget.character.charisma,
          modifier: CharacterListHelpers.getModifier(widget.character.charisma),
          onTap: widget.onEdit,
        ),
      ],
    );
  }

  /// Währungs-Chips
  Widget _buildCurrencyChips() {
    final hasCurrency = widget.character.gold > 0 || widget.character.silver > 0 || widget.character.copper > 0;

    if (!hasCurrency) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    if (widget.character.gold > 0) {
      chips.add(PcInfoChip.currency(
        label: '',
        amount: widget.character.gold,
        icon: Icons.monetization_on,
        color: Colors.amber,
      ));
    }

    if (widget.character.silver > 0) {
      chips.add(PcInfoChip.currency(
        label: '',
        amount: widget.character.silver,
        icon: Icons.monetization_on_outlined,
        color: Colors.blueGrey,
      ));
    }

    if (widget.character.copper > 0) {
      chips.add(PcInfoChip.currency(
        label: '',
        amount: widget.character.copper,
        icon: Icons.circle_outlined,
        color: Colors.brown,
      ));
    }

    return PcChipSection(
      title: 'Vermögen',
      titleIcon: Icons.account_balance_wallet_outlined,
      chips: chips,
    );
  }

  /// Gesinnungs-Chip
  Widget _buildAlignmentChip() {
    return PcChipRow(
      chips: [
        PcInfoChip.alignment(alignment: widget.character.alignment!),
      ],
    );
  }

  /// Beschreibungstext
  Widget _buildDescription(AppColorsExtension C) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: C.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        widget.character.description!,
        style: TextStyle(
          fontSize: 12,
          color: C.textMid,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Aktionsleiste mit Buttons
  Widget _buildActionBar(Color classColor, AppColorsExtension C) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onQuickAction != null)
          TextButton.icon(
            onPressed: widget.onQuickAction,
            icon: const Icon(Icons.more_horiz, size: 18),
            label: const Text('Aktionen'),
            style: TextButton.styleFrom(
              foregroundColor: C.accent,
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
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
