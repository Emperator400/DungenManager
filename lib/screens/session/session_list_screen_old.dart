// lib/screens/session_list_for_campaign_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/session.dart';
import '../../viewmodels/session_list_for_campaign_viewmodel.dart';
import 'edit_session_screen.dart';
import 'active_session_screen.dart';
import '../../widgets/ui_components/cards/unified_session_card.dart';
import '../../theme/dnd_theme.dart';

class SessionListForCampaignScreen extends StatefulWidget {
  final Campaign campaign;
  const SessionListForCampaignScreen({super.key, required this.campaign});

  @override
  State<SessionListForCampaignScreen> createState() => _SessionListForCampaignScreenState();
}

class _SessionListForCampaignScreenState extends State<SessionListForCampaignScreen> 
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionListForCampaignViewModel>().initialize(widget.campaign);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Session> _getFilteredSessions(SessionListForCampaignViewModel viewModel) {
    if (_searchQuery.isEmpty) return viewModel.sessions;
    return viewModel.searchSessions(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom AppBar mit Kampagnen-Info
          _buildSliverAppBar(),
          
          // Search Bar
          _buildSearchBar(),
          
          // Sessions Content
          _buildSessionsContent(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewSession(),
        icon: const Icon(Icons.add),
        label: const Text('Neue Sitzung'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: DnDTheme.dungeonBlack,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.campaign.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        expandedTitleScale: 1.2,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DnDTheme.dungeonBlack,
                DnDTheme.stoneGrey.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => _editCampaign(),
          tooltip: 'Kampagne bearbeiten',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Sitzungen durchsuchen...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsContent() {
    return Consumer<SessionListForCampaignViewModel>(
      builder: (context, viewModel, child) {
        // Loading state
        if (viewModel.isLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error state
        if (viewModel.errorMessage != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fehler beim Laden der Sitzungen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.refreshSessions();
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredSessions = _getFilteredSessions(viewModel);

        // Empty state
        if (filteredSessions.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty 
                        ? 'Keine Sitzungen gefunden'
                        : 'Noch keine Sitzungen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle deine erste Sitzung für diese Kampagne',
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Content
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = filteredSessions[index];
                return UnifiedSessionCard(
                  session: session,
                  sessionNumber: index + 1,
                  onTap: () => _openSession(session),
                  onPlay: () => _openSession(session),
                  onEdit: () => _editSession(session),
                  onDelete: () => _deleteSession(session),
                );
              },
              childCount: filteredSessions.length,
            ),
          ),
        );
      },
    );
  }

  void _openSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ActiveSessionScreen(
          session: session,
          campaign: widget.campaign,
        ),
      ),
    );
  }

  void _editSession(Session session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditSessionScreen(session: session),
      ),
    );
    // Liste nach dem Editieren aktualisieren
    context.read<SessionListForCampaignViewModel>().refreshSessions();
  }

  void _deleteSession(Session session) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sitzung löschen'),
        content: Text(
          'Möchtest du die Sitzung "${session.title}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<SessionListForCampaignViewModel>().deleteSession(session.id!);
              if (!success) {
                // Fehler anzeigen, falls notwendig
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fehler beim Löschen der Sitzung'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _createNewSession() async {
    final newSession = await context.read<SessionListForCampaignViewModel>().createSession(
      title: "Sitzung ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
    );
    
    if (newSession != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EditSessionScreen(session: newSession),
        ),
      );
    }
  }

  void _editCampaign() {
    // Hier könntest du zum Kampagnen-Edit-Screen navigieren
    // import 'enhanced_edit_campaign_screen.dart';
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (ctx) => EnhancedEditCampaignScreen(campaign: widget.campaign),
    // ));
  }
}
