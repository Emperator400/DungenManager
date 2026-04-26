import 'package:flutter/material.dart';

import '../../../models/player_character.dart';
import '../../../services/armor_calculation_service.dart';
import '../../../theme/app_colors_map.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/ui_components/shared/app_icon.dart';
import '../base/unified_card_base.dart';

class UnifiedHeroCard extends UnifiedCardBase {
  const UnifiedHeroCard({
    required this.hero,
    super.key,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    super.isSelected,
  });

  final PlayerCharacter hero;

  @override
  Widget buildCardContent(BuildContext context) =>
      _HeroCardContent(card: this);
}

// ── CARD CONTENT ──────────────────────────────────────────────────────────────

class _HeroCardContent extends StatefulWidget {
  const _HeroCardContent({required this.card});

  final UnifiedHeroCard card;

  @override
  State<_HeroCardContent> createState() => _HeroCardContentState();
}

class _HeroCardContentState extends State<_HeroCardContent> {
  bool _hovered = false;
  final _armorService = ArmorCalculationService();
  ArmorClassResult? _armorResult;
  bool _loadingAc = true;

  UnifiedHeroCard get c => widget.card;

  @override
  void initState() {
    super.initState();
    _loadAc();
  }

  @override
  void didUpdateWidget(_HeroCardContent old) {
    super.didUpdateWidget(old);
    if (old.card.hero.id != c.hero.id) {
      _loadAc();
    }
  }

  Future<void> _loadAc() async {
    if (!mounted) return;
    setState(() => _loadingAc = true);
    try {
      final result = await _armorService.calculateArmorClass(
        characterId: c.hero.id,
        dexterity: c.hero.dexterity,
        baseArmorClass: 10,
      );
      if (mounted) {
        setState(() { _armorResult = result; _loadingAc = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _armorResult = null; _loadingAc = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final bright = Theme.of(context).brightness == Brightness.light;
    final typeName = _classTypeName(c.hero.className);
    final typeConfig = AppTypeColors.of(typeName);
    final classColor = typeConfig.color;
    final classBg = bright ? typeConfig.bgLight : typeConfig.bgDark;

    final acValue = _loadingAc
        ? c.hero.armorClass
        : (_armorResult?.totalAc ?? c.hero.armorClass);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: c.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? C.bgHover : C.bgPanel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farbstreifen
              Container(height: 3, color: classColor),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(
                          letter: c.hero.name.isNotEmpty
                              ? c.hero.name[0].toUpperCase()
                              : '?',
                          level: c.hero.level,
                          color: classColor,
                          bg: classBg,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.hero.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: C.text,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _ClassBadge(
                                label:
                                    '${c.hero.raceName} ${c.hero.className}',
                                color: classColor,
                                bg: classBg,
                              ),
                            ],
                          ),
                        ),
                        if (_hovered) ...[
                          _IconBtn(
                            C: C,
                            icon: AppIconName.edit,
                            onTap: c.onEdit,
                          ),
                          const SizedBox(width: 2),
                          _PopupBtn(card: c, C: C),
                        ],
                      ],
                    ),

                    // Spielername
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AppIcon(AppIconName.user, size: 11, color: C.textSoft),
                        const SizedBox(width: 4),
                        Text(
                          c.hero.playerName,
                          style:
                              TextStyle(fontSize: 11, color: C.textSoft),
                        ),
                      ],
                    ),

                    // Kampfwerte
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatChip(
                          icon: AppIconName.shield,
                          label: 'AC',
                          value: '$acValue',
                          C: C,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: AppIconName.heart,
                          label: 'HP',
                          value: '${c.hero.maxHp}',
                          C: C,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: AppIconName.star,
                          label: 'INIT',
                          value: _signedMod(c.hero.dexterity,
                              bonus: c.hero.initiativeBonus),
                          C: C,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: AppIconName.play,
                          label: 'ft',
                          value: '${c.hero.speed}',
                          C: C,
                        ),
                      ],
                    ),

                    // Attribute
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AttrCell(name: 'STR', score: c.hero.strength, C: C),
                        _AttrCell(name: 'DEX', score: c.hero.dexterity, C: C),
                        _AttrCell(name: 'CON', score: c.hero.constitution, C: C),
                        _AttrCell(name: 'INT', score: c.hero.intelligence, C: C),
                        _AttrCell(name: 'WIS', score: c.hero.wisdom, C: C),
                        _AttrCell(name: 'CHA', score: c.hero.charisma, C: C),
                      ],
                    ),

                    // Beschreibung
                    if (c.hero.description != null &&
                        c.hero.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.hero.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: C.textMid,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── POPUP MENU ────────────────────────────────────────────────────────────────

class _PopupBtn extends StatelessWidget {
  const _PopupBtn({required this.card, required this.C});

  final UnifiedHeroCard card;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: '',
        color: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: C.border),
        ),
        offset: const Offset(0, 30),
        onSelected: (v) => _handle(context, v),
        itemBuilder: (_) => [
          _item('delete', AppIconName.trash, 'Löschen', C, color: C.red),
        ],
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.bgHover,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: AppIcon(AppIconName.dots, size: 12, color: C.textSoft),
          ),
        ),
      );

  PopupMenuItem<String> _item(
    String value,
    AppIconName icon,
    String label,
    AppColorsExtension C, {
    Color? color,
  }) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            AppIcon(icon, size: 13, color: color ?? C.textMid),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 13, color: color ?? C.text)),
          ],
        ),
      );

  void _handle(BuildContext context, String action) {
    switch (action) {
      case 'delete':
        _showDeleteDialog(context);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(name: card.hero.name, C: C),
    );
    if ((confirmed ?? false) && context.mounted) {
      card.onDelete?.call();
    }
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name, required this.C});

  final String name;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Held löschen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: C.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Möchtest du "$name" wirklich löschen? '
                'Diese Aktion kann nicht rückgängig gemacht werden.',
                style: TextStyle(fontSize: 13, color: C.textMid),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: C.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: C.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text('Löschen',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.letter,
    required this.level,
    required this.color,
    required this.bg,
  });

  final String letter;
  final int level;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$level',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
}

class _ClassBadge extends StatelessWidget {
  const _ClassBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.C,
  });

  final AppIconName icon;
  final String label;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 11, color: C.textSoft),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: C.text,
            ),
          ),
          const SizedBox(width: 1),
          Text(label, style: TextStyle(fontSize: 9, color: C.textSoft)),
        ],
      );
}

class _AttrCell extends StatelessWidget {
  const _AttrCell({
    required this.name,
    required this.score,
    required this.C,
  });

  final String name;
  final int score;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final mod = ((score - 10) / 2).floor();
    final modStr = mod >= 0 ? '+$mod' : '$mod';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: TextStyle(fontSize: 9, color: C.textSoft)),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: C.text,
          ),
        ),
        Text(modStr, style: TextStyle(fontSize: 9, color: C.textSoft)),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.C, required this.icon, this.onTap});

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.bgActive,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: AppIcon(icon, size: 12, color: C.textSoft),
          ),
        ),
      );
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

String _classTypeName(String className) {
  switch (className.toLowerCase()) {
    case 'barbarian':
      return 'Barbar';
    case 'bard':
      return 'Barde';
    case 'cleric':
      return 'Kleriker';
    case 'druid':
      return 'Druide';
    case 'fighter':
      return 'Kämpfer';
    case 'monk':
      return 'Mönch';
    case 'paladin':
      return 'Paladin';
    case 'ranger':
      return 'Waldläufer';
    case 'rogue':
      return 'Schurke';
    case 'sorcerer':
    case 'warlock':
    case 'wizard':
      return 'Zauberer';
    default:
      return className;
  }
}

String _signedMod(int score, {int bonus = 0}) {
  final mod = ((score - 10) / 2).floor() + bonus;
  return mod >= 0 ? '+$mod' : '$mod';
}
