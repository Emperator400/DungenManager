import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../models/player_character.dart';
import '../../theme/app_theme.dart';

class HeroListSection extends StatefulWidget {
  final String campaignId;
  final PlayerCharacterModelRepository? pcRepository;

  const HeroListSection({
    super.key,
    required this.campaignId,
    this.pcRepository,
  });

  @override
  State<HeroListSection> createState() => _HeroListSectionState();
}

class _HeroListSectionState extends State<HeroListSection> {
  List<PlayerCharacter> _heroes = [];
  bool _isLoading = true;
  late PlayerCharacterModelRepository _pcRepository;

  @override
  void initState() {
    super.initState();
    _pcRepository = widget.pcRepository ??
        PlayerCharacterModelRepository(DatabaseConnection.instance);
    _loadHeroes();
  }

  Future<void> _loadHeroes() async {
    try {
      final heroes = await _pcRepository.findByCampaign(widget.campaignId);
      if (mounted) setState(() { _heroes = heroes; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(C),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: C.accent),
              ),
            ),
          )
        else if (_heroes.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Text(
              'Keine Helden in dieser Kampagne',
              style: TextStyle(fontSize: 12, color: C.textSoft),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            itemCount: _heroes.length,
            itemBuilder: (context, index) => _buildHeroCard(_heroes[index], C),
          ),
      ],
    );
  }

  Widget _buildHeader(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 14, color: C.accent),
          const SizedBox(width: 7),
          Text(
            'Helden',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: C.text,
            ),
          ),
          const SizedBox(width: 7),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: C.bgHover,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_heroes.length} Helden',
                style: TextStyle(fontSize: 10, color: C.textSoft),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(PlayerCharacter hero, AppColorsExtension C) {
    final classColor = _classColor(hero.className, C);
    final hpPercent = hero.maxHp > 0 ? 1.0 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: classColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hero.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: C.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${hero.className} · Lvl ${hero.level}',
                  style: TextStyle(fontSize: 11, color: C.textSoft),
                ),
                const SizedBox(height: 5),
                _buildHpBar(hero.maxHp, hero.maxHp, hpPercent, C),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatChip('RK ${hero.armorClass}', Icons.security, C.accent, C),
              const SizedBox(height: 4),
              _buildStatChip('${hero.maxHp} HP', Icons.favorite, C.green, C),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHpBar(int current, int max, double percent, AppColorsExtension C) {
    final barColor = percent > 0.5
        ? C.green
        : percent > 0.25
            ? C.amber
            : C.red;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 3,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: C.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color, AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _classColor(String className, AppColorsExtension C) {
    final lower = className.toLowerCase();
    if (lower.contains('barbar') || lower.contains('krieger') || lower.contains('fighter') || lower.contains('barbarian')) return C.red;
    if (lower.contains('magier') || lower.contains('wizard') || lower.contains('zauberer') || lower.contains('hexenmeister') || lower.contains('warlock') || lower.contains('sorcerer')) return C.accent;
    if (lower.contains('kleriker') || lower.contains('cleric') || lower.contains('paladin')) return C.amber;
    if (lower.contains('schurke') || lower.contains('rogue') || lower.contains('bard') || lower.contains('barde')) return C.amber;
    if (lower.contains('waldläufer') || lower.contains('ranger') || lower.contains('druide') || lower.contains('druid') || lower.contains('monk') || lower.contains('mönch')) return C.green;
    return C.textMid;
  }
}
