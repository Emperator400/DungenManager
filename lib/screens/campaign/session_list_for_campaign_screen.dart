import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/session.dart';
import '../../viewmodels/session_list_for_campaign_viewmodel.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import '../session/edit_session_screen.dart' show EditSessionScreen;
import '../session/active_session_screen.dart' show ActiveSessionScreen;
import 'edit_campaign_screen.dart' show EditCampaignScreen;
import '../../widgets/ui_components/cards/unified_session_card.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/states/error_state_widget.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../theme/dnd_theme.dart';

class SessionListForCampaignScreen extends StatefulWidget {
  final Campaign campaign;
  const SessionListForCampaignScreen({super.key, required this.campaign});

  @override
  State<SessionListForCampaignScreen> createState() => _SessionListForCampaignScreenState();
}

class _SessionListForCampaignScreenState extends State<SessionListForCampaignScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sessions: ${widget.campaign.title}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DnDTheme.dungeonBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DnDTheme.dungeonBlack,
                DnDTheme.stoneGrey.withValues(alpha: 0.3),
              ],
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
      ),
      body: _buildSessionsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSession,
        backgroundColor: DnDTheme.mysticalPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Neue Session',
          style: TextStyle(color: Colors.white),
        ),
        tooltip: 'Neue Session erstellen',
      ),
    );
  }

  Future<void> _createNewSession() async {
    final viewModel = context.read<SessionListForCampaignViewModel>();
    final newSession = await viewModel.createSession();
    
    if (newSession != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EditSessionScreen(session: newSession, isNewSession: true),
        ),
      );
      if (!mounted) return;
      // Liste nach dem Editieren aktualisieren
      context.read<SessionListForCampaignViewModel>().refreshSessions();
    }
  }

  Widget _buildSessionsList() {
    return Column(
      children: [
        // Search Bar
        Container(
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
        
        // Sessions Content
        Expanded(child: _buildSessionsContent()),
      ],
    );
  }

  Widget _buildSessionsContent() {
    return Consumer<SessionListForCampaignViewModel>(
      builder: (context, viewModel, child) {
        // Loading state
        if (viewModel.isLoading) {
          return const LoadingStateWidget();
        }

        if (viewModel.errorMessage != null) {
          return ErrorStateWidget.withRetry(
            title: 'Fehler beim Laden der Sitzungen',
            message: viewModel.errorMessage,
            onRetry: () {
              viewModel.clearError();
              viewModel.refreshSessions();
            },
          );
        }

        final filteredSessions = _getFilteredSessions(viewModel);

        // Empty state
        if (filteredSessions.isEmpty) {
          return Center(
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
          );
        }

        // Content
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredSessions.length,
          itemBuilder: (context, index) {
            final session = filteredSessions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UnifiedSessionCard(
                session: session,
                sessionNumber: index + 1,
                onTap: () => _openSession(session),
                onPlay: () => _openSession(session),
                onEdit: () => _editSession(session),
                onDelete: () => _deleteSession(session),
              ),
            );
          },
        );
      },
    );
  }

  void _openSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChangeNotifierProvider<ActiveSessionViewModel>(
          create: (context) => ActiveSessionViewModel(
            session: session,
            campaign: widget.campaign,
          ),
          child: ActiveSessionScreen(
            session: session,
            campaign: widget.campaign,
          ),
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

  void _deleteSession(Session session) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Sitzung löschen',
      message: 'Möchtest du die Sitzung "${session.title}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<SessionListForCampaignViewModel>().deleteSession(session.id);
    if (!mounted) return;
    if (!success) {
      SnackBarHelper.showError(context, 'Fehler beim Löschen der Sitzung');
    }
  }

  void _editCampaign() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => EditCampaignScreen(campaign: widget.campaign),
    ));
  }
}