import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/session.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/session_list_for_campaign_viewmodel.dart';
import '../../database/repositories/scene_model_repository.dart';
import '../../database/repositories/creature_model_repository.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import 'edit_session_screen.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import 'active_session_screen.dart';

class EnhancedSessionListForCampaignScreen extends StatefulWidget {
  final Campaign campaign;

  const EnhancedSessionListForCampaignScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<EnhancedSessionListForCampaignScreen> createState() => _EnhancedSessionListForCampaignScreenState();
}

class _EnhancedSessionListForCampaignScreenState extends State<EnhancedSessionListForCampaignScreen> {
  final _searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionListForCampaignViewModel>().initialize(widget.campaign);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Consumer<SessionListForCampaignViewModel>(
          builder: (context, vm, _) => _buildTopBar(context, vm, C),
        ),
      ),
      body: Consumer<SessionListForCampaignViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = _isSearchMode && _searchController.text.isNotEmpty
              ? viewModel.searchSessions(_searchController.text)
              : viewModel.sessions;

          if (sessions.isEmpty) {
            return _buildEmptyState(C);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: C.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Sessions suchen...',
                    hintStyle: TextStyle(color: C.textSoft, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: C.textMid, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: C.textMid, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: C.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: C.accent),
                    ),
                    filled: true,
                    fillColor: C.bgPanel,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isSearchMode = value.isNotEmpty;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _buildSessionCard(session, viewModel, C);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, SessionListForCampaignViewModel vm, AppColorsExtension C) {
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              _IconBtn(icon: Icons.arrow_back, color: C.textMid, onTap: () => Navigator.of(context).pop()),
              Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.15),
                  border: Border.all(color: C.accent.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Icon(Icons.event_note, size: 14, color: C.accent)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sitzungen', style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1)),
                  Text(widget.campaign.title, style: TextStyle(color: C.textSoft, fontSize: 10, height: 1.1)),
                ],
              ),
              const Spacer(),
              PopupMenuButton<SessionSortCriteria>(
                icon: Icon(Icons.sort, size: 18, color: C.textMid),
                tooltip: 'Sortieren',
                color: C.bgPanel,
                onSelected: (criteria) => vm.sortSessions(criteria),
                itemBuilder: (context) => [
                  PopupMenuItem(value: SessionSortCriteria.titleAsc, child: _sortItem(Icons.arrow_upward, 'Titel (A-Z)', C)),
                  PopupMenuItem(value: SessionSortCriteria.titleDesc, child: _sortItem(Icons.arrow_downward, 'Titel (Z-A)', C)),
                  PopupMenuItem(value: SessionSortCriteria.durationAsc, child: _sortItem(Icons.arrow_upward, 'Dauer (kurz-lang)', C)),
                  PopupMenuItem(value: SessionSortCriteria.durationDesc, child: _sortItem(Icons.arrow_downward, 'Dauer (lang-kurz)', C)),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: vm.isLoading ? null : _createNewSession,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: vm.isLoading ? C.bgHover : C.accent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 13, color: vm.isLoading ? C.textSoft : Colors.white),
                    const SizedBox(width: 5),
                    Text('Neue Session',
                        style: TextStyle(color: vm.isLoading ? C.textSoft : Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sortItem(IconData icon, String label, AppColorsExtension C) => Row(children: [
    Icon(icon, size: 14, color: C.textMid),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(color: C.text, fontSize: 13)),
  ]);

  Widget _buildEmptyState(AppColorsExtension C) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: C.border),
          const SizedBox(height: 16),
          Text('Keine Sessions gefunden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: C.textMid)),
          const SizedBox(height: 8),
          Text('Erstelle deine erste Session für diese Kampagne',
              style: TextStyle(fontSize: 14, color: C.textSoft)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewSession,
            icon: const Icon(Icons.add),
            label: const Text('Erste Session erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, SessionListForCampaignViewModel viewModel, AppColorsExtension C) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openSession(session),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: C.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.event, color: C.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.schedule, size: 12, color: C.textMid),
                          const SizedBox(width: 4),
                          Text(_formatDuration(session.inGameTimeInMinutes),
                              style: TextStyle(fontSize: 11, color: C.textMid)),
                        ]),
                      ],
                    ),
                  ),
                  _IconBtn(icon: Icons.edit, color: C.accent, onTap: () => _editSession(session)),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: C.textMid),
                    color: C.bgPanel,
                    onSelected: (value) {
                      switch (value) {
                        case 'duplicate':
                          _duplicateSession(session);
                        case 'delete':
                          _deleteSession(session);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(children: [
                          Icon(Icons.copy, size: 16, color: C.textMid),
                          const SizedBox(width: 8),
                          Text('Duplizieren', style: TextStyle(color: C.text, fontSize: 13)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 16, color: C.red),
                          const SizedBox(width: 8),
                          Text('Löschen', style: TextStyle(color: C.red, fontSize: 13)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              if (session.liveNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: C.bgHover,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.liveNotes,
                    style: TextStyle(fontSize: 11, color: C.textMid, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (session.sceneIds.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildSceneCharacterSummary(session, C),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneCharacterSummary(Session session, AppColorsExtension C) {
    return FutureBuilder<Set<String>>(
      future: _loadAllSceneCharacters(session),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final characterIds = snapshot.data!;
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadCharacterDetails(characterIds.toList()),
          builder: (context, charSnapshot) {
            if (charSnapshot.hasError || !charSnapshot.hasData || charSnapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final characters = charSnapshot.data!;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: C.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: C.accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.people, color: C.accent, size: 12),
                    const SizedBox(width: 4),
                    Text('Beteiligte Charaktere',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: C.accent)),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: characters.values.map((char) {
                      final type = char['type'] as String;
                      final name = char['name'] as String;
                      final color = _getCharacterTypeColor(type, C);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_getCharacterTypeIcon(type), color: color, size: 10),
                          const SizedBox(width: 3),
                          Text(name, style: TextStyle(fontSize: 10, color: C.text, fontWeight: FontWeight.w500)),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Set<String>> _loadAllSceneCharacters(Session session) async {
    final Set<String> characterIds = {};
    try {
      final sceneRepo = context.read<SceneModelRepository>();
      for (final sceneId in session.sceneIds) {
        try {
          final scene = await sceneRepo.findById(sceneId);
          if (scene != null) characterIds.addAll(scene.linkedCharacterIds);
        } catch (e) {
          debugPrint('Fehler beim Laden von Scene $sceneId: $e');
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Scene-Charaktere: $e');
    }
    return characterIds;
  }

  Future<Map<String, dynamic>> _loadCharacterDetails(List<String> characterIds) async {
    final Map<String, dynamic> result = {};
    try {
      final creatureRepo = context.read<CreatureModelRepository>();
      final pcRepo = context.read<PlayerCharacterModelRepository>();
      for (final charId in characterIds) {
        try {
          final pc = await pcRepo.findById(charId);
          if (pc != null) {
            result[charId] = {'name': pc.name, 'type': 'pc'};
            continue;
          }
        } catch (_) {}
        try {
          final creature = await creatureRepo.findById(charId);
          if (creature != null) {
            result[charId] = {
              'name': creature.name,
              'type': creature.sourceType == 'official' ? 'monster' : 'npc',
            };
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Charakterdetails: $e');
    }
    return result;
  }

  Color _getCharacterTypeColor(String type, AppColorsExtension C) => switch (type) {
    'pc' => C.green,
    'npc' => C.accent,
    'monster' => C.red,
    _ => C.textMid,
  };

  IconData _getCharacterTypeIcon(String type) => switch (type) {
    'pc' => Icons.person,
    'npc' => Icons.person_outline,
    'monster' => Icons.pets,
    _ => Icons.person,
  };

  Future<void> _createNewSession() async {
    final viewModel = context.read<SessionListForCampaignViewModel>();
    final newSession = await viewModel.createSession();
    if (newSession != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => EditSessionScreen(session: newSession, isNewSession: true),
        ),
      ).then((_) {
        if (mounted) context.read<SessionListForCampaignViewModel>().refreshSessions();
      });
    }
  }

  void _openSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChangeNotifierProvider<ActiveSessionViewModel>(
          create: (context) => ActiveSessionViewModel(
            session: session,
            campaign: widget.campaign,
          ),
          child: ActiveSessionScreen(session: session, campaign: widget.campaign),
        ),
      ),
    );
  }

  void _editSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditSessionScreen(session: session),
      ),
    ).then((_) {
      if (mounted) context.read<SessionListForCampaignViewModel>().refreshSessions();
    });
  }

  Future<void> _duplicateSession(Session session) async {
    final viewModel = context.read<SessionListForCampaignViewModel>();
    final duplicated = await viewModel.duplicateSession(session);
    if (!mounted) return;
    if (duplicated != null) {
      SnackBarHelper.showSuccess(context, 'Session dupliziert');
    }
  }

  Future<void> _deleteSession(Session session) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Session löschen',
      message: 'Möchtest du die Session "${session.title}" wirklich löschen?',
    );
    if (confirmed != true) return;
    final viewModel = context.read<SessionListForCampaignViewModel>();
    final success = await viewModel.deleteSession(session.id);
    if (!mounted) return;
    if (success) {
      SnackBarHelper.showSuccess(context, 'Session gelöscht');
    }
  }
}

// ── LOCAL WIDGETS ────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: color)),
    );
  }
}
