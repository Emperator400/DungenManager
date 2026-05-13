import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/player.dart';
import '../../models/player_character.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart' show SnackBarHelper;
import '../characters/edit_pc_screen.dart';
import 'edit_player_screen.dart';

Color _parseColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return const Color(0xFF6B6B66);
  }
}

class PlayerDetailScreen extends StatefulWidget {
  final Player player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  late Player _player;
  List<PlayerCharacter> _characters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _loading = true);
    final chars = await context.read<PlayerViewModel>().getCharactersForPlayer(_player.id);
    if (mounted) setState(() { _characters = chars; _loading = false; });
  }

  Future<void> _createCharacter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPCScreen(initialPlayerId: _player.id),
      ),
    );
    if (mounted) _loadCharacters();
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPlayerScreen(player: _player)),
    );
    if (updated == true && mounted) {
      final vm = context.read<PlayerViewModel>();
      await vm.loadPlayers();
      final fresh = vm.players.where((p) => p.id == _player.id).toList();
      if (fresh.isNotEmpty && mounted) setState(() => _player = fresh.first);
    }
  }

  Future<void> _unassignCharacter(PlayerCharacter character) async {
    final ok = await context
        .read<PlayerViewModel>()
        .unassignCharacterFromPlayer(character.id);
    if (mounted) {
      if (ok) {
        SnackBarHelper.showSuccess(context, '${character.name} entfernt');
        _loadCharacters();
      } else {
        SnackBarHelper.showError(context, 'Fehler beim Entfernen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final color = _parseColor(_player.color);

    return Scaffold(
      backgroundColor: C.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCharacter,
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Neuer Held'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: color.withValues(alpha: 0.9),
            foregroundColor: Colors.white,
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _player.name.isNotEmpty ? _player.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _openEdit,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_player.notes != null && _player.notes!.isNotEmpty) ...[
                    _SectionHeader(label: 'Notizen', C: C),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: C.bgPanel,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.border),
                      ),
                      child: Text(_player.notes!, style: TextStyle(color: C.text, height: 1.5)),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _SectionHeader(label: 'Charaktere', C: C),
                  const SizedBox(height: 8),
                  if (_loading)
                    Center(child: CircularProgressIndicator(color: C.accent))
                  else if (_characters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: C.bgPanel,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.border),
                      ),
                      child: Center(
                        child: Text(
                          'Noch keine Charaktere zugeordnet',
                          style: TextStyle(color: C.textSoft),
                        ),
                      ),
                    )
                  else
                    ..._characters.map((c) => _CharacterTile(
                          character: c,
                          color: color,
                          C: C,
                          onUnassign: () => _unassignCharacter(c),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.C});
  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: C.textMid,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({
    required this.character,
    required this.color,
    required this.C,
    required this.onUnassign,
  });
  final PlayerCharacter character;
  final Color color;
  final AppColorsExtension C;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Text(
            character.name.isNotEmpty ? character.name[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        title: Text(character.name, style: TextStyle(color: C.text, fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Lvl ${character.level} ${character.className} · ${character.raceName}',
          style: TextStyle(color: C.textSoft, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.link_off, color: C.textSoft, size: 18),
          tooltip: 'Verknüpfung aufheben',
          onPressed: onUnassign,
        ),
      ),
    );
  }
}
