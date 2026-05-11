import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/player.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart' show SnackBarHelper;
import 'edit_player_screen.dart';
import 'player_detail_screen.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerViewModel>().loadPlayers();
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditPlayerScreen()),
    );
    if (created == true && mounted) {
      context.read<PlayerViewModel>().loadPlayers();
    }
  }

  Future<void> _openDetail(Player player) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
    );
    if (mounted) context.read<PlayerViewModel>().loadPlayers();
  }

  Future<void> _deletePlayer(Player player) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Spieler löschen',
      message:
          'Spieler „${player.name}" wirklich löschen?\nCharaktere bleiben erhalten.',
      confirmText: 'Löschen',
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<PlayerViewModel>().deletePlayer(player.id);
    if (mounted) {
      if (ok) {
        SnackBarHelper.showSuccess(context, '${player.name} gelöscht');
      } else {
        SnackBarHelper.showError(context, 'Fehler beim Löschen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        foregroundColor: C.text,
        title: Text('Spieler', style: TextStyle(color: C.text, fontWeight: FontWeight.w600)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: C.border),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<PlayerViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return Center(child: CircularProgressIndicator(color: C.accent));
          }
          if (vm.players.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: C.textSoft),
                  const SizedBox(height: 16),
                  Text('Noch keine Spieler', style: TextStyle(color: C.textMid, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tippe auf + um einen Spieler anzulegen',
                      style: TextStyle(color: C.textSoft, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.players.length,
            itemBuilder: (context, i) => _PlayerCard(
              player: vm.players[i],
              onTap: () => _openDetail(vm.players[i]),
              onDelete: () => _deletePlayer(vm.players[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.onTap,
    required this.onDelete,
  });

  final Player player;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF6B6B66);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final color = _parseColor(player.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(player.name,
            style: TextStyle(color: C.text, fontWeight: FontWeight.w600)),
        subtitle: player.notes != null && player.notes!.isNotEmpty
            ? Text(
                player.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: C.textSoft, fontSize: 12),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: C.textSoft, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
