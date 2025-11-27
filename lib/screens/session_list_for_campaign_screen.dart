// lib/screens/session_list_for_campaign_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../viewmodels/session_list_for_campaign_viewmodel.dart';
import 'enhanced_edit_session_screen.dart';
import 'enhanced_active_session_screen.dart';

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
      backgroundColor: Theme.of(context).primaryColor,
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
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
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
                return _buildSessionCard(session, index);
              },
              childCount: filteredSessions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(Session session, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openSession(session),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sitzung ${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleSessionAction(value, session),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'play',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, size: 16),
                              SizedBox(width: 8),
                              Text('Starten'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Bearbeiten'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Löschen', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Heute',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSessionStatusColor(session).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSessionStatusText(session),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getSessionStatusColor(session),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unbekannt';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getSessionStatusText(Session session) {
    // Hier könntest du basierend auf session-Status oder anderen Kriterien
    // den Status bestimmen
    return 'Aktiv'; // Placeholder
  }

  Color _getSessionStatusColor(Session session) {
    // Hier könntest du basierend auf session-Status die Farbe bestimmen
    return Theme.of(context).primaryColor;
  }

  void _openSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EnhancedActiveSessionScreen(
          session: session,
          campaign: widget.campaign,
        ),
      ),
    );
  }

  void _handleSessionAction(String action, Session session) {
    switch (action) {
      case 'play':
        _openSession(session);
        break;
      case 'edit':
        _editSession(session);
        break;
      case 'delete':
        _deleteSession(session);
        break;
    }
  }

  void _editSession(Session session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EnhancedEditSessionScreen(session: session),
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
          builder: (ctx) => EnhancedEditSessionScreen(session: newSession),
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
