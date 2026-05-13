import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/player_model_repository.dart';
import '../../models/player.dart';
import '../../models/player_character.dart';
import '../../theme/app_theme.dart';

Color _hexToColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFF6B6B66);
  }
}

class HeroListSection extends StatefulWidget {
  final String campaignId;
  final double maxContentHeight;
  final PlayerCharacterModelRepository? pcRepository;

  const HeroListSection({
    super.key,
    required this.campaignId,
    this.maxContentHeight = 220,
    this.pcRepository,
  });

  @override
  State<HeroListSection> createState() => _HeroListSectionState();
}

class _HeroListSectionState extends State<HeroListSection> {
  List<PlayerCharacter> _heroes = [];
  Map<String, Player> _playerById = {};
  bool _isLoading = true;
  late PlayerCharacterModelRepository _pcRepository;
  late PlayerModelRepository _playerRepository;

  @override
  void initState() {
    super.initState();
    _pcRepository = widget.pcRepository ??
        PlayerCharacterModelRepository(DatabaseConnection.instance);
    _playerRepository = PlayerModelRepository(DatabaseConnection.instance);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _pcRepository.findByCampaign(widget.campaignId),
        _playerRepository.findAll(),
      ]);
      final heroes = results[0] as List<PlayerCharacter>;
      final players = results[1] as List<Player>;
      if (mounted) {
        setState(() {
          _heroes = heroes;
          _playerById = {for (final p in players) p.id: p};
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showHeroPickerDialog() async {
    final C = context.appColors;

    // Alle Helden laden die noch nicht in dieser Kampagne sind
    final all = await _pcRepository.findAll();
    final available = all
        .where((pc) =>
            pc.campaignId == null ||
            pc.campaignId!.isEmpty ||
            pc.campaignId != widget.campaignId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Keine verfügbaren Helden — zuerst im Spieler-Profil anlegen'),
          backgroundColor: C.textMid,
        ),
      );
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _HeroPickerDialog(
        available: available,
        playerById: _playerById,
      ),
    );

    if (selected == null || selected.isEmpty || !mounted) return;

    for (final id in selected) {
      try {
        await _pcRepository.assignToCampaign(id, widget.campaignId);
      } catch (_) {}
    }

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header immer sichtbar – scrollt nicht mit
        _buildHeader(C),
        // Nur die Heldenliste scrollt
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxContentHeight),
          child: _buildContent(C),
        ),
      ],
    );
  }

  Widget _buildContent(AppColorsExtension C) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: C.accent),
          ),
        ),
      );
    }
    if (_heroes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Text(
          'Keine Helden in dieser Kampagne',
          style: TextStyle(fontSize: 12, color: C.textSoft),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      itemCount: _heroes.length,
      itemBuilder: (context, index) => _buildHeroCard(_heroes[index], C),
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
          const Spacer(),
          // Nur Auswählen, kein Erstellen
          GestureDetector(
            onTap: () => _showHeroPickerDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: C.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: C.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_outlined, size: 12, color: C.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Held wählen',
                    style: TextStyle(
                        fontSize: 10,
                        color: C.accent,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(PlayerCharacter hero, AppColorsExtension C) {
    final classColor = _classColor(hero.className, C);
    final player = hero.playerId != null ? _playerById[hero.playerId] : null;
    final playerColor = player != null ? _hexToColor(player.color) : C.accent;
    final displayName =
        player?.name ?? (hero.playerName.isNotEmpty ? hero.playerName : null);

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
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: playerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hero.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: C.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (displayName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: playerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: playerColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 9,
                            color: playerColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${hero.className} · Lvl ${hero.level}',
                  style: TextStyle(fontSize: 11, color: classColor),
                ),
                const SizedBox(height: 5),
                _buildHpBar(hero.maxHp, C),
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

  Widget _buildHpBar(int maxHp, AppColorsExtension C) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: 3,
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          color: C.border,
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: maxHp > 0 ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: C.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      String label, IconData icon, Color color, AppColorsExtension C) {
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
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _classColor(String className, AppColorsExtension C) {
    return switch (className) {
      'Barbar' => const Color(0xFFC93A3A),
      'Barde' => const Color(0xFF7C3AED),
      'Kleriker' => const Color(0xFFD4890A),
      'Druide' => const Color(0xFF1A7F4B),
      'Kämpfer' => const Color(0xFF6B6B66),
      'Mönch' => const Color(0xFF0891B2),
      'Paladin' => const Color(0xFF2F6FEB),
      'Waldläufer' => const Color(0xFF065F46),
      'Schurke' => const Color(0xFF4A4A4A),
      'Zauberer' => const Color(0xFFBE185D),
      'Hexenmeister' => const Color(0xFF4A235A),
      'Magier' => const Color(0xFF1B4F72),
      _ => C.accent,
    };
  }
}

// ── PICKER DIALOG ─────────────────────────────────────────────────────────────

class _HeroPickerDialog extends StatefulWidget {
  const _HeroPickerDialog({
    required this.available,
    required this.playerById,
  });
  final List<PlayerCharacter> available;
  final Map<String, Player> playerById;

  @override
  State<_HeroPickerDialog> createState() => _HeroPickerDialogState();
}

class _HeroPickerDialogState extends State<_HeroPickerDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Held auswählen',
                      style: TextStyle(
                          color: C.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Wähle bestehende Helden für diese Sitzung aus.',
                      style: TextStyle(color: C.textSoft, fontSize: 12)),
                ],
              ),
            ),
            Divider(color: C.border, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.available.length,
                itemBuilder: (ctx, i) {
                  final pc = widget.available[i];
                  final isSelected = _selected.contains(pc.id);
                  final player = pc.playerId != null
                      ? widget.playerById[pc.playerId]
                      : null;
                  final playerColor = player != null
                      ? _hexToColor(player.color)
                      : const Color(0xFF6B6B66);
                  final ownerName = player?.name ??
                      (pc.playerName.isNotEmpty ? pc.playerName : null);
                  final hasCampaign =
                      pc.campaignId != null && pc.campaignId!.isNotEmpty;

                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: C.accent,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(pc.id);
                      } else {
                        _selected.remove(pc.id);
                      }
                    }),
                    secondary: CircleAvatar(
                      backgroundColor: playerColor.withValues(alpha: 0.15),
                      radius: 18,
                      child: Text(
                        pc.name.isNotEmpty ? pc.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: playerColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    title: Text(pc.name,
                        style: TextStyle(
                            color: C.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    subtitle: Text(
                      [
                        'Lvl ${pc.level} ${pc.className}',
                        if (ownerName != null) ownerName,
                        if (hasCampaign) 'aktuell anderswo',
                      ].join(' · '),
                      style: TextStyle(color: C.textSoft, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            Divider(color: C.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_selected.isEmpty
                        ? 'Auswählen'
                        : '${_selected.length} hinzufügen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
