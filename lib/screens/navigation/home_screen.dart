import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/core/database_connection.dart';
import '../../database/repositories/campaign_model_repository.dart';
import '../../models/campaign.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../viewmodels/update_viewmodel.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import '../../widgets/ui_components/shared/app_logo.dart';
import '../../widgets/update_dialog.dart';

import '../../utils/color_utils.dart';
import '../bestiary/bestiary_screen.dart';
import '../audio/sound_library_screen.dart';
import '../campaign/campaign_selection_screen.dart';
import '../items/item_library_screen.dart';
import '../lore/lore_keeper_screen.dart';
import '../navigation/main_navigation_screen.dart';

// ── DATA ──────────────────────────────────────────────────────────────────────

class _Bereich {
  const _Bereich({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.beschreibung,
    this.disabled = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String beschreibung;
  final bool disabled;
}

const _bereiche = [
  _Bereich(id: 'kampagnen',    label: 'Kampagnen',    icon: Icons.auto_stories,  color: Color(0xFF2F6FEB), beschreibung: 'Verwalte deine Abenteuer'),
  _Bereich(id: 'bestiarium',   label: 'Bestiarium',   icon: Icons.pets,           color: Color(0xFF1A7F4B), beschreibung: 'Monster & Kreaturen'),
  _Bereich(id: 'ausruestung',  label: 'Ausrüstung',   icon: Icons.inventory_2,    color: Color(0xFFB45309), beschreibung: 'Items & Gegenstände'),
  _Bereich(id: 'lore',         label: 'Lore Keeper',  icon: Icons.menu_book,      color: Color(0xFF7C3AED), beschreibung: 'Wiki & Weltenwissen'),
  _Bereich(id: 'sounds',       label: 'Sounds',       icon: Icons.music_note,     color: Color(0xFF0891B2), beschreibung: 'Atmosphäre & Musik'),
  _Bereich(id: 'profil',       label: 'DM-Profil',    icon: Icons.person,         color: Color(0xFF6B6B66), beschreibung: 'Dein Profil & Daten',   disabled: true),
  _Bereich(id: 'einstellungen',label: 'Einstellungen',icon: Icons.settings,       color: Color(0xFF6B6B66), beschreibung: 'App konfigurieren',     disabled: true),
];

// ── SCREEN ────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _campaignRepo = CampaignModelRepository(DatabaseConnection.instance);
  Campaign? _lastCampaign;
  String? _selectedId;
  bool _loading = true;
  bool _updateChecked = false;
  UpdateViewModel? _updateViewModel;

  @override
  void initState() {
    super.initState();
    _loadLastCampaign();
    _checkForUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateViewModel ??= context.read<UpdateViewModel>();
  }

  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;
    _updateChecked = true;
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || _updateViewModel == null) return;
    final hasUpdate = await _updateViewModel!.checkForUpdate();
    if (hasUpdate && mounted) {
      unawaited(showUpdateDialogIfNeeded(context));
    }
  }

  Future<void> _checkForUpdatesManually() async {
    final vm = context.read<UpdateViewModel>();
    await vm.checkForUpdate();
    if (!mounted) return;
    if (vm.availableUpdate != null) {
      await showUpdateDialogIfNeeded(context, forceShow: true);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: ${vm.errorMessage}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du verwendest die neueste Version!')),
      );
    }
  }

  Future<void> _loadLastCampaign() async {
    try {
      final c = await _campaignRepo.findLastOpened();
      if (mounted) setState(() { _lastCampaign = c; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectBereich(String id) =>
      setState(() => _selectedId = _selectedId == id ? null : id);

  void _openBereich(BuildContext context, _Bereich b) {
    switch (b.id) {
      case 'kampagnen':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CampaignSelectionScreen()),
        ).then((_) => _loadLastCampaign());
      case 'bestiarium':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BestiaryScreen()),
        );
      case 'ausruestung':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ItemLibraryScreen()),
        );
      case 'lore':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LoreKeeperScreen()),
        );
      case 'sounds':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SoundLibraryScreen()),
        );
    }
  }

  Future<void> _openLastCampaign(BuildContext context) async {
    final c = _lastCampaign;
    if (c == null) return;
    final viewModel = context.read<CampaignViewModel>();
    await viewModel.selectCampaign(c);
    await _campaignRepo.updateLastOpenedAt(c.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EnhancedMainNavigationScreen(campaign: c),
      ),
    ).then((_) => _loadLastCampaign());
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final selected = _bereiche.where((b) => b.id == _selectedId).firstOrNull;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          _TopBar(C: C, onCheckUpdate: _checkForUpdatesManually),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Begrüßung
                  Text(
                    'Willkommen zurück',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: C.text),
                  ),
                  const SizedBox(height: 4),
                  Text('Was möchtest du heute vorbereiten?', style: TextStyle(fontSize: 13, color: C.textSoft)),
                  const SizedBox(height: 24),

                  // Schnellstart
                  if (!_loading) _buildSchnellstart(context, C),
                  if (!_loading) const SizedBox(height: 24),

                  // Grid
                  _buildGridHeader(C),
                  const SizedBox(height: 10),
                  _buildGrid(C),

                  // Detail Banner
                  if (selected != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailBanner(context, selected, C),
                  ],
                  const SizedBox(height: 24),

                  // Letzte Aktivität
                  _buildAktivitaetHeader(C),
                  const SizedBox(height: 10),
                  _buildAktivitaetListe(C),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SCHNELLSTART ────────────────────────────────────────────────────────────

  Widget _buildSchnellstart(BuildContext context, AppColorsExtension C) {
    if (_lastCampaign == null) {
      return _SchnellstartEmpty(C: C, onTap: () => _openBereich(context, _bereiche.first));
    }
    final c = _lastCampaign!;
    final sessionCount = c.sessionIds.length;
    final campaignColor = ColorUtils.fromHex(c.accentColor) ?? C.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: campaignColor.withValues(alpha: 0.13),
              border: Border.all(color: campaignColor.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                c.title.isNotEmpty ? c.title[0].toUpperCase() : 'D',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: campaignColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: C.green)),
                    const SizedBox(width: 5),
                    Text(
                      sessionCount > 0 ? 'Zuletzt gespielt · Session $sessionCount' : 'Zuletzt geöffnet',
                      style: TextStyle(fontSize: 11, color: C.textSoft),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _FilledBtn(
            label: 'Fortsetzen',
            icon: AppIconName.play,
            color: campaignColor,
            onTap: () => _openLastCampaign(context),
          ),
        ],
      ),
    );
  }

  // ── GRID ────────────────────────────────────────────────────────────────────

  Widget _buildGridHeader(AppColorsExtension C) => Text(
    'BEREICHE',
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: C.textSoft, letterSpacing: 0.6),
  );

  Widget _buildGrid(AppColorsExtension C) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: _bereiche.length,
      itemBuilder: (_, i) => _GridTile(
        bereich: _bereiche[i],
        isSelected: _selectedId == _bereiche[i].id,
        onTap: _bereiche[i].disabled ? null : () => _selectBereich(_bereiche[i].id),
        C: C,
      ),
    );
  }

  // ── DETAIL BANNER ────────────────────────────────────────────────────────────

  Widget _buildDetailBanner(BuildContext context, _Bereich b, AppColorsExtension C) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: b.color.withValues(alpha: 0.35), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: b.color.withValues(alpha: 0.13),
              border: Border.all(color: b.color.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(b.icon, color: b.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 1),
                Text(b.beschreibung, style: TextStyle(fontSize: 11, color: C.textSoft)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _FilledBtn(
            label: 'Öffnen',
            icon: AppIconName.chevronRight,
            color: b.color,
            onTap: () => _openBereich(context, b),
          ),
        ],
      ),
    );
  }

  // ── AKTIVITÄT ────────────────────────────────────────────────────────────────

  Widget _buildAktivitaetHeader(AppColorsExtension C) => Text(
    'LETZTE AKTIVITÄT',
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: C.textSoft, letterSpacing: 0.6),
  );

  Widget _buildAktivitaetListe(AppColorsExtension C) {
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Text('Noch keine Aktivität', style: TextStyle(fontSize: 13, color: C.textSoft)),
        ),
      ),
    );
  }
}

// ── TOPBAR ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.C, required this.onCheckUpdate});

  final AppColorsExtension C;
  final VoidCallback onCheckUpdate;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
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
                  const AppLogo(size: 28),
                  const SizedBox(width: 8),
                  Text('DungenManager', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                  const Spacer(),
                  // Update badge button
                  Consumer<UpdateViewModel>(
                    builder: (_, vm, __) => GestureDetector(
                      onTap: onCheckUpdate,
                      child: _UpdateBadgeBtn(C: C, hasUpdate: vm.hasUpdateAvailable),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _IconBtn(
                    C: C,
                    icon: notifier.isDark ? AppIconName.sun : AppIconName.moon,
                    onTap: notifier.toggle,
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }
}

class _UpdateBadgeBtn extends StatefulWidget {
  const _UpdateBadgeBtn({required this.C, required this.hasUpdate});

  final AppColorsExtension C;
  final bool hasUpdate;

  @override
  State<_UpdateBadgeBtn> createState() => _UpdateBadgeBtnState();
}

class _UpdateBadgeBtnState extends State<_UpdateBadgeBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: _hovered ? widget.C.bgHover : Colors.transparent,
        border: Border.all(color: _hovered ? widget.C.border : Colors.transparent),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppIcon(AppIconName.download, size: 14, color: widget.C.textMid),
          if (widget.hasUpdate)
            Positioned(
              top: 4, right: 4,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: widget.C.green, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    ),
  );
}

// ── GRID TILE ─────────────────────────────────────────────────────────────────

class _GridTile extends StatefulWidget {
  const _GridTile({
    required this.bereich,
    required this.isSelected,
    required this.C,
    this.onTap,
  });

  final _Bereich bereich;
  final bool isSelected;
  final AppColorsExtension C;
  final VoidCallback? onTap;

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.bereich;
    final C = widget.C;
    final active = widget.isSelected;
    final disabled = b.disabled;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: disabled ? null : (_) => setState(() => _hovered = true),
      onExit: disabled ? null : (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: active
                ? b.color.withValues(alpha: 0.1)
                : _hovered
                    ? C.bgHover
                    : C.bgPanel,
            border: Border.all(
              color: active ? b.color.withValues(alpha: 0.45) : _hovered ? C.borderStrong : C.border,
              width: active ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: b.color.withValues(alpha: disabled ? 0.07 : 0.13),
                  border: Border.all(color: b.color.withValues(alpha: disabled ? 0.15 : 0.28)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(b.icon, color: b.color.withValues(alpha: disabled ? 0.4 : 1.0), size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                b.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: disabled ? C.textSoft : C.text),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SCHNELLSTART EMPTY STATE ──────────────────────────────────────────────────

class _SchnellstartEmpty extends StatelessWidget {
  const _SchnellstartEmpty({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: C.bgHover,
                border: Border.all(color: C.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: C.textSoft, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keine aktive Kampagne', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
                  const SizedBox(height: 2),
                  Text('Kampagne erstellen oder öffnen', style: TextStyle(fontSize: 11, color: C.textSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: C.textSoft, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final AppIconName icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.C, required this.icon, required this.onTap});

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: _hovered ? widget.C.bgHover : Colors.transparent,
          border: Border.all(color: _hovered ? widget.C.border : Colors.transparent),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(child: AppIcon(widget.icon, size: 14, color: widget.C.textMid)),
      ),
    ),
  );
}
