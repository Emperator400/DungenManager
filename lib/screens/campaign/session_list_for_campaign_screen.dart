import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/session.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import '../../viewmodels/session_list_for_campaign_viewmodel.dart';
import '../../widgets/ui_components/cards/unified_session_card.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/states/error_state_widget.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../session/active_session_screen.dart' show ActiveSessionScreen;
import '../session/edit_session_screen.dart' show EditSessionScreen;
import 'edit_campaign_screen.dart' show EditCampaignScreen;

class SessionListForCampaignScreen extends StatefulWidget {
  const SessionListForCampaignScreen({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<SessionListForCampaignScreen> createState() =>
      _SessionListForCampaignScreenState();
}

class _SessionListForCampaignScreenState
    extends State<SessionListForCampaignScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  List<Session> _getFilteredSessions(SessionListForCampaignViewModel viewModel) {
    if (_searchQuery.isEmpty) return viewModel.sessions;
    return viewModel.searchSessions(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          _buildTopBar(C),
          Expanded(child: _buildSessionsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSession,
        backgroundColor: C.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Neue Session', style: TextStyle(color: Colors.white)),
        tooltip: 'Neue Session erstellen',
      ),
    );
  }

  Widget _buildTopBar(AppColorsExtension C) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildIconBtn(C, Icons.arrow_back, () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 18, color: C.border),
                  const SizedBox(width: 10),
                  _buildCampaignAvatar(C, 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.campaign.title,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Sessions', style: TextStyle(fontSize: 11, color: C.textSoft)),
                      ],
                    ),
                  ),
                  _buildIconBtn(C, Icons.edit_outlined, _editCampaign),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }

  Widget _buildIconBtn(AppColorsExtension C, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(7),
          color: C.bgHover,
        ),
        child: Center(child: Icon(icon, size: 16, color: C.textMid)),
      ),
    );
  }

  Widget _buildCampaignAvatar(AppColorsExtension C, double size) {
    final initial = widget.campaign.title.isNotEmpty
        ? widget.campaign.title[0].toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: C.accentSoft,
        border: Border.all(color: C.accent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w700, color: C.accent),
        ),
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
      context.read<SessionListForCampaignViewModel>().refreshSessions();
    }
  }

  Widget _buildSessionsList() {
    final C = context.appColors;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Sitzungen durchsuchen...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.accent, width: 2),
              ),
              filled: true,
              fillColor: C.bgPanel,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(child: _buildSessionsContent()),
      ],
    );
  }

  Widget _buildSessionsContent() {
    final C = context.appColors;
    return Consumer<SessionListForCampaignViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) return const LoadingStateWidget();
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

        if (filteredSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_outlined, size: 64, color: C.textSoft),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'Keine Sitzungen gefunden' : 'Noch keine Sitzungen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.textSoft),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Erstelle deine erste Sitzung für diese Kampagne',
                    style: TextStyle(color: C.textSoft),
                  ),
                ],
              ],
            ),
          );
        }

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
          child: ActiveSessionScreen(session: session, campaign: widget.campaign),
        ),
      ),
    );
  }

  Future<void> _editSession(Session session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => EditSessionScreen(session: session)),
    );
    if (!mounted) return;
    context.read<SessionListForCampaignViewModel>().refreshSessions();
  }

  Future<void> _deleteSession(Session session) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Sitzung löschen',
      message: 'Möchtest du die Sitzung "${session.title}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
    );
    if (confirmed != true || !mounted) return;
    final success =
        await context.read<SessionListForCampaignViewModel>().deleteSession(session.id);
    if (!mounted) return;
    if (!success) SnackBarHelper.showError(context, 'Fehler beim Löschen der Sitzung');
  }

  void _editCampaign() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => EditCampaignScreen(campaign: widget.campaign)),
    );
  }
}
