import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../viewmodels/update_viewmodel.dart';
import '../../widgets/update_dialog.dart';
import '../../widgets/campaign/enhanced_campaign_filter_chips_widget.dart';
import '../../widgets/ui_components/cards/unified_campaign_card.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/states/empty_state_widget.dart';
import '../../widgets/ui_components/states/error_state_widget.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import '../../widgets/ui_components/shared/app_logo.dart';

import '../../database/core/database_connection.dart';
import '../../database/repositories/campaign_model_repository.dart';
import '../../screens/navigation/main_navigation_screen.dart';
import '../../widgets/campaign/campaign_edit_modal_widget.dart';

class CampaignSelectionLayout extends StatefulWidget {
  const CampaignSelectionLayout({super.key});

  @override
  State<CampaignSelectionLayout> createState() => _CampaignSelectionLayoutState();
}

class _CampaignSelectionLayoutState extends State<CampaignSelectionLayout> {
  int _activeTab = 0; // 0 = Kampagnen, 1 = Vorlagen

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildTopBar(context, C),
      body: Consumer<CampaignViewModel>(
        builder: (context, viewModel, child) => RefreshIndicator(
          onRefresh: () async => viewModel.refresh(),
          color: C.accent,
          child: Column(
            children: [
              _buildTabBar(C),
              if (_activeTab == 0) _buildFilterSection(context, viewModel, C),
              Expanded(child: _buildContent(context, viewModel, C)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, C),
    );
  }

  Widget _buildTabBar(AppColorsExtension C) {
    return Container(
      color: C.bgPanel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _TabPill(
                  label: 'Kampagnen',
                  active: _activeTab == 0,
                  C: C,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: 6),
                _TabPill(
                  label: 'Vorlagen',
                  active: _activeTab == 1,
                  C: C,
                  onTap: () => setState(() => _activeTab = 1),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: C.border),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context, AppColorsExtension C) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        height: 48,
        color: C.bgPanel,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Zurück (nur wenn nicht Root-Screen)
                    if (Navigator.canPop(context)) ...[
                      _iconBtn(context, C, AppIconName.back, () => Navigator.of(context).pop()),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 18, color: C.border),
                      const SizedBox(width: 10),
                    ],
                    // Titel
                    const AppLogo(size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Kampagnen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: C.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer<CampaignViewModel>(
                      builder: (context, vm, _) => Text(
                        _activeTab == 0
                            ? '${vm.activeCampaigns.length}'
                            : '${vm.templates.length}',
                        style: TextStyle(fontSize: 12, color: C.textSoft),
                      ),
                    ),
                    const Spacer(),
                    // Update Check
                    _iconBtn(
                      context,
                      C,
                      AppIconName.refresh,
                      () => _checkForUpdatesManually(context),
                    ),
                    const SizedBox(width: 4),
                    // Suche
                    _iconBtn(
                      context,
                      C,
                      AppIconName.search,
                      () => _showSearchDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: C.border),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(
    BuildContext context,
    AppColorsExtension C,
    AppIconName icon,
    VoidCallback onTap,
  ) => _HoverIconButton(C: C, icon: icon, onTap: onTap);

  Widget _buildFilterSection(
    BuildContext context,
    CampaignViewModel viewModel,
    AppColorsExtension C,
  ) {
    return Container(
      color: C.bgPanel,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: EnhancedCampaignFilterChipsWidget(viewModel: viewModel),
          ),
          Divider(height: 1, thickness: 1, color: C.border),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CampaignViewModel viewModel,
    AppColorsExtension C,
  ) {
    if (viewModel.isLoading) {
      return LoadingStateWidget.withMessage(
        message: 'Kampagnen werden geladen...',
        color: C.accent,
      );
    }

    if (viewModel.error != null) {
      return ErrorStateWidget.withRetry(
        title: 'Fehler beim Laden',
        message: viewModel.error,
        onRetry: viewModel.refresh,
      );
    }

    return _activeTab == 0
        ? _buildCampaignList(context, viewModel, C)
        : _buildTemplateList(context, viewModel, C);
  }

  Widget _buildCampaignList(
    BuildContext context,
    CampaignViewModel viewModel,
    AppColorsExtension C,
  ) {
    final filtered = viewModel.filteredCampaigns;

    if (filtered.isEmpty) {
      return viewModel.activeCampaigns.isEmpty
          ? EmptyStateWidget.withCreate(
              title: 'Noch keine Kampagnen',
              message: 'Erstelle deine erste Kampagne oder nutze eine Vorlage.',
              icon: Icons.campaign_outlined,
              iconColor: C.accent,
              onCreate: () => _showCreateCampaignDialog(context),
              buttonText: 'Erste Kampagne erstellen',
            )
          : EmptyStateWidget.withClearFilters(
              title: 'Keine Kampagnen gefunden',
              message: 'Versuche andere Suchbegriffe oder passe die Filter an.',
              icon: Icons.search_off,
              iconColor: C.textSoft,
              onClearFilters: () => context.read<CampaignViewModel>().clearSearch(),
            );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: UnifiedCampaignCard(
          campaign: filtered[i],
          viewModel: viewModel,
          onNavigate: () => _navigateToCampaign(context, filtered[i]),
          onEdit: () => _editCampaign(context, filtered[i]),
          onDuplicate: () => _duplicateCampaign(context, filtered[i], viewModel),
          onToggleFavorite: () => _toggleFavorite(context, filtered[i], viewModel),
        ),
      ),
    );
  }

  Widget _buildTemplateList(
    BuildContext context,
    CampaignViewModel viewModel,
    AppColorsExtension C,
  ) {
    final filtered = viewModel.filteredTemplates;

    if (filtered.isEmpty) {
      return EmptyStateWidget.withCreate(
        title: 'Noch keine Vorlagen',
        message: 'Erstelle eine Vorlage, um sie für mehrere Gruppen wiederzuverwenden.',
        icon: Icons.copy_outlined,
        iconColor: C.accent,
        onCreate: () => _showCreateTemplateDialog(context),
        buttonText: 'Erste Vorlage erstellen',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: UnifiedCampaignCard(
          campaign: filtered[i],
          viewModel: viewModel,
          onNavigate: () => _editCampaign(context, filtered[i]),
          onEdit: () => _editCampaign(context, filtered[i]),
          onUseCopy: () => _showUseCopyDialog(context, filtered[i], viewModel),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, AppColorsExtension C) {
    return FilledButton.icon(
      onPressed: () => _activeTab == 0
          ? _showCreateCampaignDialog(context)
          : _showCreateTemplateDialog(context),
      icon: AppIcon(AppIconName.plus, size: 14, color: Colors.white),
      label: Text(_activeTab == 0 ? 'Neue Kampagne' : 'Neue Vorlage'),
      style: FilledButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _editCampaign(BuildContext context, Campaign campaign) {
    CampaignEditModal.show(context, campaign: campaign);
  }

  Future<void> _duplicateCampaign(
    BuildContext context,
    Campaign campaign,
    CampaignViewModel viewModel,
  ) async {
    try {
      await viewModel.duplicateCampaign(campaign);
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, 'Kampagne dupliziert');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Duplizieren: $e');
      }
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Campaign campaign,
    CampaignViewModel viewModel,
  ) async {
    try {
      await viewModel.updateCampaign(
        campaign.copyWith(isFavorite: !campaign.isFavorite),
      );
      if (context.mounted) {
        SnackBarHelper.showInfo(
          context,
          campaign.isFavorite
              ? 'Kampagne von Favoriten entfernt'
              : 'Kampagne als Favorit markiert',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Aktualisieren: $e');
      }
    }
  }

  void _navigateToCampaign(BuildContext context, Campaign campaign) async {
    final viewModel = context.read<CampaignViewModel>();
    await viewModel.selectCampaign(campaign);
    await CampaignModelRepository(DatabaseConnection.instance).updateLastOpenedAt(campaign.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EnhancedMainNavigationScreen(campaign: campaign),
      ),
    );
  }

  void _showCreateCampaignDialog(BuildContext context) {
    CampaignEditModal.show(context);
  }

  void _showCreateTemplateDialog(BuildContext context) {
    CampaignEditModal.show(context, isTemplate: true);
  }

  Future<void> _showUseCopyDialog(
    BuildContext context,
    Campaign template,
    CampaignViewModel viewModel,
  ) async {
    final C = context.appColors;
    final controller = TextEditingController(text: '${template.title} — Gruppe 1');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
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
                'Kopie von "${template.title}" erstellen',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
              ),
              const SizedBox(height: 4),
              Text(
                'Wähle einen Namen für die neue Kampagne.',
                style: TextStyle(fontSize: 12, color: C.textMid),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(fontSize: 13, color: C.text),
                decoration: InputDecoration(
                  hintText: 'Name der Kampagne',
                  hintStyle: TextStyle(color: C.textSoft),
                  filled: true,
                  fillColor: C.bgHover,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Kopie erstellen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!(confirmed ?? false) || !context.mounted) return;

    final title = controller.text.trim();
    if (title.isEmpty) return;

    final copy = await viewModel.createCopyFromTemplate(template, title: title);
    if (copy != null && context.mounted) {
      setState(() => _activeTab = 0);
      SnackBarHelper.showSuccess(context, 'Kopie "${copy.title}" erstellt');
    } else if (context.mounted) {
      SnackBarHelper.showError(context, 'Fehler beim Erstellen der Kopie');
    }
  }

  Future<void> _checkForUpdatesManually(BuildContext context) async {
    final viewModel = context.read<UpdateViewModel>();
    SnackBarHelper.showInfo(context, 'Prüfe auf Updates...');
    await viewModel.checkForUpdate();
    if (!context.mounted) return;

    if (viewModel.availableUpdate != null) {
      await showUpdateDialogIfNeeded(context, forceShow: true);
    } else if (viewModel.errorMessage != null) {
      SnackBarHelper.showError(context, 'Fehler: ${viewModel.errorMessage}');
    } else {
      SnackBarHelper.showSuccess(context, 'Du verwendest die neueste Version!');
    }
  }

  void _showSearchDialog(BuildContext context) async {
    final C = context.appColors;
    final viewModel = context.read<CampaignViewModel>();

    final selectedCampaign = await showDialog<Campaign>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kampagnen suchen',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
              ),
              const SizedBox(height: 12),
              ...viewModel.campaigns.map(
                (campaign) => InkWell(
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => Navigator.of(ctx).pop(campaign),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        AppIcon(AppIconName.book, size: 13, color: C.textSoft),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            campaign.title,
                            style: TextStyle(fontSize: 13, color: C.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedCampaign != null && context.mounted) {
      _navigateToCampaign(context, selectedCampaign);
    }
  }
}

// ── HILFWIDGET: Icon-Button mit Hover ─────────────────────────────────────────

class _HoverIconButton extends StatefulWidget {
  const _HoverIconButton({
    required this.C,
    required this.icon,
    required this.onTap,
  });

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback onTap;

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered ? widget.C.bgHover : Colors.transparent,
            border: Border.all(
              color: _hovered ? widget.C.border : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: AppIcon(widget.icon, size: 14, color: widget.C.textMid),
          ),
        ),
      ),
    );
  }
}

// ── TAB PILL ──────────────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.active,
    required this.C,
    required this.onTap,
  });

  final String label;
  final bool active;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? C.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? C.accent.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? C.accent : C.textMid,
            ),
          ),
        ),
      );
}
