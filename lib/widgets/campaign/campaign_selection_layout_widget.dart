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

class CampaignSelectionLayout extends StatelessWidget {
  const CampaignSelectionLayout({super.key});

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
              _buildFilterSection(context, viewModel, C),
              Expanded(child: _buildContent(context, viewModel, C)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, C),
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
                        '${vm.campaigns.length}',
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

    final filtered = viewModel.filteredCampaigns;

    if (filtered.isEmpty) {
      return viewModel.campaigns.isEmpty
          ? EmptyStateWidget.withCreate(
              title: 'Noch keine Kampagnen',
              message: 'Erstelle deine erste Kampagne, um dein Abenteuer zu beginnen!',
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

  Widget _buildFab(BuildContext context, AppColorsExtension C) {
    return Consumer<CampaignViewModel>(
      builder: (context, vm, _) {
        if (vm.campaigns.isEmpty) {
          return const SizedBox.shrink();
        }
        return FilledButton.icon(
          onPressed: () => _showCreateCampaignDialog(context),
          icon: AppIcon(AppIconName.plus, size: 14, color: Colors.white),
          label: const Text('Neue Kampagne'),
          style: FilledButton.styleFrom(
            backgroundColor: C.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );
      },
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
