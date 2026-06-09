import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../models/encounter.dart';
import '../../models/map_layer.dart';
import '../../models/ort.dart';
import '../../models/scene.dart';
import '../../models/player.dart';
import '../../models/player_character.dart';
import '../../models/quest.dart';
import '../../models/session.dart';
import '../../models/sound.dart';
import '../../models/verlaufs_eintrag.dart';
import '../../models/wiki_entry.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/player_model_repository.dart';
import '../../widgets/dm_buch/lore_keeper_picker_dialog.dart';
import '../../widgets/dm_buch/quest_picker_dialog.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/dm_buch_viewmodel.dart';
import '../../viewmodels/wiki_viewmodel.dart';
import '../../widgets/active_session/atmosphere_quadrant.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import '../../widgets/ui_components/shared/app_logo.dart';
import '../characters/edit_pc_screen.dart';
import '../lore/lore_keeper_screen.dart';
import '../../database/repositories/creature_model_repository.dart';
import '../../database/repositories/encounter_model_repository.dart';
import '../../database/repositories/encounter_participant_model_repository.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../database/repositories/scene_model_repository.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../database/repositories/wiki_entry_model_repository.dart';
import '../../viewmodels/edit_scene_viewmodel.dart';
import '../quests/edit_quest_screen.dart';
import '../scenes/edit_scene_screen.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/companion_map_state.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../viewmodels/lan_map_viewmodel.dart';
import '../session/active_session_screen.dart';
import '../session/encounter_setup_screen.dart';
import '../resources/resource_library_screen.dart';
import '../../services/campaign_sync_service.dart';
import '../../services/cloud_resource_service.dart';
import '../../services/resource_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

// ── ENTRY POINT ───────────────────────────────────────────────────────────────

class DmBuchScreen extends StatefulWidget {
  const DmBuchScreen({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<DmBuchScreen> createState() => _DmBuchScreenState();
}

class _DmBuchScreenState extends State<DmBuchScreen> {
  late final LanMapViewModel _lanVm;

  @override
  void initState() {
    super.initState();
    _lanVm = LanMapViewModel(); // auto-starts server in constructor
  }

  @override
  void dispose() {
    _lanVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => DmBuchViewModel(
            campaign: widget.campaign,
            campaignSyncService: ctx.read<CampaignSyncService>(),
            cloudResourceService: ctx.read<CloudResourceService>(),
            syncUser: ctx.read<AuthViewModel>().user,
          )..init(),
        ),
        ChangeNotifierProvider.value(value: _lanVm),
      ],
      child: const _DmBuchView(),
    );
  }
}

// ── MAIN VIEW ─────────────────────────────────────────────────────────────────

class _DmBuchView extends StatelessWidget {
  const _DmBuchView();

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final vm = context.watch<DmBuchViewModel>();

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          _TopBar(vm: vm),
          Expanded(
            child: vm.isLoading
                ? Center(child: CircularProgressIndicator(color: C.accent, strokeWidth: 2))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LeftPane(vm: vm),
                      VerticalDivider(width: 1, thickness: 1, color: C.border),
                      Expanded(child: _RightPane(vm: vm)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.vm});

  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

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
                  // Back
                  _TopBarIconBtn(
                    icon: AppIconName.back,
                    C: C,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 18, color: C.border),
                  const SizedBox(width: 10),

                  // Logo + Kampagnen-Name + DM-Tools Menü
                  const AppLogo(size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      vm.campaign.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: C.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DmBuchMenuBtn(vm: vm, C: C),
                  const SizedBox(width: 6),
                  Consumer<LanMapViewModel>(
                    builder: (context, lanVm, _) {
                      final isActive    = lanVm.paintMode == 'viewport';
                      final hasViewport = lanVm.viewportNorm != null;
                      final color = isActive
                          ? C.accent
                          : hasViewport
                              ? C.textMid
                              : C.textSoft;
                      return Tooltip(
                        message: 'Spieler-Sichtfeld steuern – Viewport aktivieren und auf der Karte positionieren',
                        child: GestureDetector(
                          onTap: () {
                            if (isActive) {
                              lanVm.setPaintMode('reveal');
                              lanVm.clearViewport();
                            } else {
                              if (vm.currentMapImagePath != null) {
                                lanVm.setImage(vm.currentMapImagePath!);
                              }
                              lanVm.setPaintMode('viewport');
                              if (lanVm.viewportNorm == null) {
                                lanVm.moveViewportTo(const Offset(0.5, 0.5));
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? C.accent.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? C.accent.withValues(alpha: 0.35)
                                    : C.border.withValues(alpha: hasViewport ? 0.8 : 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.crop_free, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  'Viewport',
                                  style: TextStyle(fontSize: 11, color: color),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

// ── LEFT PANE ─────────────────────────────────────────────────────────────────

class _LeftPane extends StatelessWidget {
  const _LeftPane({required this.vm});

  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    const width = 320.0;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          // Tab-Bar
          _LeftTabBar(vm: vm, C: C),
          // Inhalt
          Expanded(
            child: switch (vm.leftTab) {
              DmBuchLeftTab.karte   => _KarteTab(vm: vm),
              DmBuchLeftTab.quests  => _QuestsTab(vm: vm),
              DmBuchLeftTab.spieler => _SpielerTab(vm: vm),
              DmBuchLeftTab.verlauf => _VerlaufTab(vm: vm),
            },
          ),
          // Audio Mixer — immer sichtbar
          Divider(height: 1, thickness: 1, color: C.border),
          AtmosphereQuadrant(),
        ],
      ),
    );
  }
}

class _LeftTabBar extends StatelessWidget {
  const _LeftTabBar({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                _LeftTabPill(
                  label: 'Karte',
                  active: vm.leftTab == DmBuchLeftTab.karte,
                  C: C,
                  onTap: () => vm.setLeftTab(DmBuchLeftTab.karte),
                ),
                const SizedBox(width: 6),
                _LeftTabPill(
                  label: 'Quests',
                  active: vm.leftTab == DmBuchLeftTab.quests,
                  C: C,
                  onTap: () => vm.setLeftTab(DmBuchLeftTab.quests),
                ),
                const SizedBox(width: 6),
                _LeftTabPill(
                  label: 'Spieler',
                  active: vm.leftTab == DmBuchLeftTab.spieler,
                  C: C,
                  onTap: () => vm.setLeftTab(DmBuchLeftTab.spieler),
                ),
                const SizedBox(width: 6),
                _LeftTabPill(
                  label: 'Verlauf',
                  active: vm.leftTab == DmBuchLeftTab.verlauf,
                  C: C,
                  onTap: () => vm.setLeftTab(DmBuchLeftTab.verlauf),
                ),
                const Spacer(),
                const SizedBox(width: 4),
                // Karte-Button
                Tooltip(
                  message: 'Karte',
                  child: _TopBarIconBtn(
                    icon: AppIconName.map,
                    C: C,
                    onTap: () => _navigateTo(
                      context,
                      const LoreKeeperScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: C.border),
        ],
      );

  void _navigateTo(BuildContext context, Widget screen) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
}

class _LeftTabPill extends StatelessWidget {
  const _LeftTabPill({
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? C.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? C.accent.withValues(alpha: 0.3) : Colors.transparent,
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

// ── KARTE TAB ─────────────────────────────────────────────────────────────────

class _KarteTab extends StatefulWidget {
  const _KarteTab({required this.vm});

  final DmBuchViewModel vm;

  @override
  State<_KarteTab> createState() => _KarteTabState();
}

class _KarteTabState extends State<_KarteTab> {
  bool _verlaufsSort = false;

  // Builds the ordered list when Verlauf sort is active.
  // Each Verlaufsplan Ort entry becomes its own row (duplicates kept),
  // then remaining Orte not in the plan follow at the bottom.
  List<({Ort ort, int? stepIndex, bool stepDone, String? stepEntryId})> _verlaufsSorted() {
    final vm = widget.vm;
    final allOrte = vm.orte;
    final sorted = <({Ort ort, int? stepIndex, bool stepDone, String? stepEntryId})>[];
    final inPlanOrtIds = <String>{};

    for (var i = 0; i < vm.verlaufsplan.length; i++) {
      final entry = vm.verlaufsplan[i];
      if (entry.type != VerlaufsEintragType.ort || entry.refId == null) continue;
      final ort = allOrte.where((o) => o.id == entry.refId).firstOrNull;
      if (ort == null) continue;
      inPlanOrtIds.add(ort.id);
      sorted.add((ort: ort, stepIndex: i, stepDone: entry.isDone, stepEntryId: entry.id));
    }

    for (final ort in vm.orte) {
      if (!inPlanOrtIds.contains(ort.id)) {
        sorted.add((ort: ort, stepIndex: null, stepDone: false, stepEntryId: null));
      }
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final vm = widget.vm;
    final orte = vm.currentLevelOrte;
    final onSubMap = vm.currentMapParentId != null;

    return Column(
      children: [
        // Breadcrumb wenn auf Subkarte
        if (onSubMap)
          _MapBreadcrumb(vm: vm, C: C),

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Text(
                '${orte.length} Marker',
                style: TextStyle(fontSize: 11, color: C.textSoft),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _verlaufsSort = !_verlaufsSort),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _verlaufsSort ? C.accent.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _verlaufsSort ? C.accent.withValues(alpha: 0.4) : C.border,
                    ),
                  ),
                  child: Text(
                    'Verlauf',
                    style: TextStyle(
                      fontSize: 10,
                      color: _verlaufsSort ? C.accent : C.textMid,
                      fontWeight: _verlaufsSort ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _LoreKeeperBtn(
                onTap: () async {
                  final wikiVm = context.read<WikiViewModel>();
                  if (wikiVm.allEntries.isEmpty) await wikiVm.loadEntries();
                  if (!context.mounted) return;
                  final entry = await LoreKeeperPickerDialog.show(
                    context,
                    entries: wikiVm.allEntries,
                    title: 'Marker aus LoreKeeper',
                  );
                  if (entry != null && context.mounted) {
                    await vm.createOrtFromWikiEntry(entry, parentOrtId: vm.currentMapParentId);
                  }
                },
                C: C,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _CreateOrtDialog(vm: vm),
                ),
                child: Text('Neu', style: TextStyle(fontSize: 11, color: C.accent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: orte.isEmpty
              ? Center(
                  child: Text(
                    onSubMap ? 'Noch keine Marker auf dieser Subkarte' : 'Noch keine Marker',
                    style: TextStyle(fontSize: 13, color: C.textSoft),
                  ),
                )
              : _verlaufsSort
                  ? _VerlaufsSortedList(items: _verlaufsSorted(), vm: vm)
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                      buildDefaultDragHandles: false,
                      itemCount: orte.length,
                      onReorder: vm.reorderOrte,
                      proxyDecorator: (child, _, __) =>
                          Material(color: Colors.transparent, child: child),
                      itemBuilder: (ctx, i) => ReorderableDragStartListener(
                        key: ValueKey(orte[i].id),
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _OrtCard(
                            ort: orte[i],
                            selected: vm.selectedOrt?.id == orte[i].id,
                            vm: vm,
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── KARTE BREADCRUMB ──────────────────────────────────────────────────────────

class _MapBreadcrumb extends StatelessWidget {
  const _MapBreadcrumb({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final crumbs = vm.mapBreadcrumb;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 12, color: C.textSoft),
              ),
            GestureDetector(
              onTap: i < crumbs.length - 1 ? () => vm.drillTo(i) : null,
              child: Text(
                crumbs[i].name,
                style: TextStyle(
                  fontSize: 11,
                  color: i < crumbs.length - 1 ? C.accent : C.text,
                  fontWeight: i == crumbs.length - 1 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerlaufsSortedList extends StatelessWidget {
  const _VerlaufsSortedList({required this.items, required this.vm});

  final List<({Ort ort, int? stepIndex, bool stepDone, String? stepEntryId})> items;
  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final inPlan  = items.where((e) => e.stepIndex != null).toList();
    final notPlan = items.where((e) => e.stepIndex == null).toList();
    final C = context.appColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      children: [
        ...inPlan.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final eintrag = e.stepEntryId != null
              ? vm.verlaufsplan.where((v) => v.id == e.stepEntryId).firstOrNull
              : null;
          final isLast = i == inPlan.length - 1;
          return Column(
            key: ValueKey(e.stepEntryId ?? e.ort.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 6 : 0),
                child: _OrtCard(
                  ort: e.ort,
                  selected: vm.selectedOrt?.id == e.ort.id,
                  vm: vm,
                  stepIndex: e.stepIndex,
                  stepDone: e.stepDone,
                  onToggleDone: e.stepEntryId != null
                      ? () => vm.toggleVerlaufsEintrag(e.stepEntryId!)
                      : null,
                  showPathHint: true,
                  onTap: e.ort.parentOrtId != vm.currentMapParentId
                      ? () => vm.navigateToOrt(e.ort)
                      : null,
                ),
              ),
              if (!isLast && eintrag != null)
                _VerlaufsConnector(
                  eintrag: eintrag,
                  vm: vm,
                  editable: false,
                  C: context.appColors,
                ),
            ],
          );
        }),
        if (notPlan.isNotEmpty) ...[
          if (inPlan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Row(
                children: [
                  Expanded(child: Divider(height: 1, color: C.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Nicht im Plan', style: TextStyle(fontSize: 10, color: C.textSoft)),
                  ),
                  Expanded(child: Divider(height: 1, color: C.border)),
                ],
              ),
            ),
          ...notPlan.map((e) => Padding(
                key: ValueKey(e.ort.id),
                padding: const EdgeInsets.only(bottom: 6),
                child: _OrtCard(
                  ort: e.ort,
                  selected: vm.selectedOrt?.id == e.ort.id,
                  vm: vm,
                  showPathHint: true,
                  onTap: e.ort.parentOrtId != vm.currentMapParentId
                      ? () => vm.navigateToOrt(e.ort)
                      : null,
                ),
              )),
        ],
      ],
    );
  }
}

class _OrtCard extends StatefulWidget {
  const _OrtCard({
    required this.ort,
    required this.selected,
    required this.vm,
    this.stepIndex,
    this.stepDone = false,
    this.onToggleDone,
    this.showPathHint = false,
    this.onTap,
  });

  final Ort ort;
  final bool selected;
  final DmBuchViewModel vm;
  final int? stepIndex;
  final bool stepDone;
  final VoidCallback? onToggleDone;
  final bool showPathHint;
  final VoidCallback? onTap;

  @override
  State<_OrtCard> createState() => _OrtCardState();
}

class _OrtCardState extends State<_OrtCard> {
  bool _hovered = false;

  Color _typeColor(AppColorsExtension C) {
    switch (widget.ort.type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final color = _typeColor(C);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap != null ? widget.onTap!() : widget.vm.selectOrt(widget.ort),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? C.accent.withValues(alpha: 0.08)
                : _hovered
                    ? C.bgHover
                    : C.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected ? C.accent.withValues(alpha: 0.4) : C.border,
            ),
          ),
          child: Row(
            children: [
              // Schritt-Badge (Verlaufsplan-Modus) oder Typ-Punkt
              if (widget.stepIndex != null)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.stepDone
                        ? C.green.withValues(alpha: 0.1)
                        : C.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.stepDone
                          ? C.green.withValues(alpha: 0.35)
                          : C.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: widget.stepDone
                        ? Icon(Icons.check, size: 11, color: C.green)
                        : Text(
                            '${widget.stepIndex! + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: C.accent,
                            ),
                          ),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ort.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: widget.stepDone ? C.textSoft : C.text,
                        decoration: widget.stepDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.ort.type.label,
                      style: TextStyle(fontSize: 11, color: C.textSoft),
                    ),
                    if (widget.showPathHint && widget.ort.parentOrtId != widget.vm.currentMapParentId)
                      Text(
                        widget.vm.ortPath(widget.ort.id),
                        style: TextStyle(fontSize: 10, color: C.textSoft.withValues(alpha: 0.65)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Gedächtnis-Indikator
              if (widget.ort.hasBeenVisited)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: C.amber, shape: BoxShape.circle),
                ),
              // Verlaufsplan-Checkmark
              if (widget.onToggleDone != null)
                GestureDetector(
                  onTap: widget.onToggleDone,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      widget.stepDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 17,
                      color: widget.stepDone ? C.green : C.textSoft,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FOKUS LEER ────────────────────────────────────────────────────────────────

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus({required this.message, required this.C});

  final String message;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 36, color: C.textSoft),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 14, color: C.textSoft)),
          ],
        ),
      );
}

// ── QUEST DETAIL PANE ─────────────────────────────────────────────────────────

class _QuestDetailPane extends StatelessWidget {
  const _QuestDetailPane({required this.quest, required this.vm});

  final Quest quest;
  final DmBuchViewModel vm;

  Color _typeColor(AppColorsExtension C) {
    switch (quest.questType) {
      case QuestType.main:     return C.accent;
      case QuestType.side:     return C.green;
      case QuestType.personal: return C.amber;
      case QuestType.faction:  return C.red;
    }
  }

  Color _statusColor(AppColorsExtension C) {
    switch (quest.status) {
      case QuestStatus.active:    return C.accent;
      case QuestStatus.completed: return C.green;
      case QuestStatus.failed:    return C.red;
      case QuestStatus.abandoned: return C.textSoft;
      case QuestStatus.onHold:    return C.amber;
    }
  }

  String _statusLabel() {
    switch (quest.status) {
      case QuestStatus.active:    return 'Aktiv';
      case QuestStatus.completed: return 'Abgeschlossen';
      case QuestStatus.failed:    return 'Gescheitert';
      case QuestStatus.abandoned: return 'Abgebrochen';
      case QuestStatus.onHold:    return 'Pausiert';
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final typeColor = _typeColor(C);
    final statusColor = _statusColor(C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TagPill(quest.questTypeDescription, typeColor, C),
                        const SizedBox(width: 6),
                        _TagPill(_statusLabel(), statusColor, C),
                        const SizedBox(width: 6),
                        _TagPill(quest.difficultyDescription, C.textMid, C),
                      ],
                    ),
                  ],
                ),
              ),
              _TopBarIconBtn(
                icon: AppIconName.edit,
                C: C,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(
                      builder: (_) => EditQuestScreen(quest: quest),
                    ))
                    .then((_) => vm.reloadQuests()),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              if (quest.description.isNotEmpty) ...[
                Text('Beschreibung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(quest.description, style: TextStyle(fontSize: 13, color: C.textMid, height: 1.6)),
                const SizedBox(height: 20),
              ],
              if (quest.location != null && quest.location!.isNotEmpty) ...[
                _DetailRow(label: 'Ort', value: quest.location!, C: C),
                const SizedBox(height: 10),
              ],
              if (quest.recommendedLevel != null) ...[
                _DetailRow(label: 'Empf. Level', value: 'Lvl ${quest.recommendedLevel}', C: C),
                const SizedBox(height: 10),
              ],
              if (quest.estimatedDurationHours != null) ...[
                _DetailRow(label: 'Dauer', value: '${quest.estimatedDurationHours}h', C: C),
                const SizedBox(height: 10),
              ],
              if (quest.tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Tags', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: quest.tags.map((t) => _TagPill(t, C.textMid, C)).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (quest.totalXP > 0 || quest.totalGoldAmount > 0) ...[
                Text('Belohnungen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                if (quest.totalXP > 0) _DetailRow(label: 'EP', value: '${quest.totalXP}', C: C),
                if (quest.totalGoldAmount > 0) ...[const SizedBox(height: 6), _DetailRow(label: 'Gold', value: '${quest.totalGoldAmount}', C: C)],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── SPIELER DETAIL PANE ───────────────────────────────────────────────────────

class _SpielerDetailPane extends StatelessWidget {
  const _SpielerDetailPane({required this.character, required this.vm});

  final PlayerCharacter character;
  final DmBuchViewModel vm;

  Color _classColor(AppColorsExtension C) {
    final lower = character.className.toLowerCase();
    if (lower.contains('barbar') || lower.contains('krieger') || lower.contains('fighter')) return C.red;
    if (lower.contains('magier') || lower.contains('wizard') || lower.contains('warlock') || lower.contains('sorcerer') || lower.contains('hexenmeister')) return C.accent;
    if (lower.contains('kleriker') || lower.contains('cleric') || lower.contains('paladin')) return C.amber;
    if (lower.contains('schurke') || lower.contains('rogue') || lower.contains('bard') || lower.contains('barde')) return C.amber;
    if (lower.contains('ranger') || lower.contains('waldläufer') || lower.contains('druide') || lower.contains('druid') || lower.contains('monk')) return C.green;
    return C.textMid;
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final classColor = _classColor(C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.playerName.isNotEmpty ? '${character.playerName} · ${character.raceName}' : character.raceName,
                      style: TextStyle(fontSize: 12, color: C.textSoft),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TagPill('${character.className}', classColor, C),
                        const SizedBox(width: 6),
                        _TagPill('Level ${character.level}', C.textMid, C),
                      ],
                    ),
                  ],
                ),
              ),
              _TopBarIconBtn(
                icon: AppIconName.edit,
                C: C,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(
                      builder: (_) => EditPCScreen(
                        campaignId: character.campaignId,
                        pcToEdit: character,
                      ),
                    ))
                    .then((_) => vm.reloadCharacters()),
              ),
            ],
          ),
        ),
        // Kernwerte
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BigStat('HP', '${character.maxHp}', C.green, C),
              _BigStat('RK', '${character.armorClass}', C.accent, C),
              _BigStat('INI', '${character.initiativeBonus >= 0 ? '+' : ''}${character.initiativeBonus}', C.amber, C),
            ],
          ),
        ),
        // Attribute
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text('Attribute', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _AttributeGrid(character: character, C: C),
              if (character.description != null && character.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Hintergrund', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(character.description!, style: TextStyle(fontSize: 13, color: C.textMid, height: 1.6)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat(this.label, this.value, this.color, this.C);

  final String label;
  final String value;
  final Color color;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.4)),
        ],
      );
}

class _AttributeGrid extends StatelessWidget {
  const _AttributeGrid({required this.character, required this.C});

  final PlayerCharacter character;
  final AppColorsExtension C;

  int _modifier(int score) => ((score - 10) / 2).floor();
  String _mod(int score) {
    final m = _modifier(score);
    return m >= 0 ? '+$m' : '$m';
  }

  @override
  Widget build(BuildContext context) {
    final attrs = [
      ('STR', character.strength),
      ('DEX', character.dexterity),
      ('KON', character.constitution),
      ('INT', character.intelligence),
      ('WEI', character.wisdom),
      ('CHA', character.charisma),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: attrs.map((a) => Container(
            decoration: BoxDecoration(
              color: C.bgHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(a.$1, style: TextStyle(fontSize: 9, color: C.textSoft, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text('${a.$2}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text)),
                Text(_mod(a.$2), style: TextStyle(fontSize: 10, color: C.textMid)),
              ],
            ),
          )).toList(),
    );
  }
}

// ── VERLAUF DETAIL PANE ───────────────────────────────────────────────────────

class _VerlaufsDetailPane extends StatelessWidget {
  const _VerlaufsDetailPane({required this.eintrag, required this.vm});

  final VerlaufsEintrag eintrag;
  final DmBuchViewModel vm;

  Color _typeColor(AppColorsExtension C) {
    switch (eintrag.type) {
      case VerlaufsEintragType.ort:      return C.accent;
      case VerlaufsEintragType.quest:    return C.amber;
      case VerlaufsEintragType.ereignis: return C.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final color = _typeColor(C);
    final isVorbereitung = vm.mode == DmBuchMode.vorbereitung;

    // Resolve referenced Ort or Quest
    final referencedOrt = eintrag.type == VerlaufsEintragType.ort && eintrag.refId != null
        ? vm.orte.where((o) => o.id == eintrag.refId).cast<Ort?>().firstOrNull
        : null;
    final referencedQuest = eintrag.type == VerlaufsEintragType.quest && eintrag.refId != null
        ? vm.quests.where((q) => q.id.toString() == eintrag.refId).cast<Quest?>().firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: 14, top: 2),
                decoration: BoxDecoration(
                  color: eintrag.isDone ? color.withValues(alpha: 0.3) : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eintrag.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: eintrag.isDone ? C.textSoft : C.text,
                        decoration: eintrag.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TagPill(eintrag.type.label, color, C),
                        if (eintrag.isDone) ...[
                          const SizedBox(width: 6),
                          _TagPill('Erledigt', C.green, C),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (vm.mode == DmBuchMode.live)
                GestureDetector(
                  onTap: () => vm.toggleVerlaufsEintrag(eintrag.id),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      eintrag.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: eintrag.isDone ? C.green : C.textSoft,
                    ),
                  ),
                ),
              if (isVorbereitung)
                GestureDetector(
                  onTap: () {
                    vm.removeVerlaufsEintrag(eintrag.id);
                    vm.deselectVerlaufsEintrag();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.delete_outline, size: 16, color: C.textSoft),
                  ),
                ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              if (eintrag.note != null && eintrag.note!.isNotEmpty) ...[
                Text('Notiz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(eintrag.note!, style: TextStyle(fontSize: 13, color: C.textMid, height: 1.6)),
                const SizedBox(height: 20),
              ],
              if (referencedOrt != null) ...[
                Text('Verknüpfter Marker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.bgHover,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(referencedOrt.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
                      const SizedBox(height: 4),
                      Text(referencedOrt.type.label, style: TextStyle(fontSize: 11, color: C.textSoft)),
                      if (referencedOrt.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(referencedOrt.description, style: TextStyle(fontSize: 12, color: C.textMid), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
              if (referencedQuest != null) ...[
                Text('Verknüpfte Quest', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.bgHover,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(referencedQuest.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
                      const SizedBox(height: 4),
                      Text(referencedQuest.questTypeDescription, style: TextStyle(fontSize: 11, color: C.textSoft)),
                      if (referencedQuest.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(referencedQuest.description, style: TextStyle(fontSize: 12, color: C.textMid), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── SHARED DETAIL HELPERS ─────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  const _TagPill(this.label, this.color, this.C);

  final String label;
  final Color color;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.C});

  final String label;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: C.textSoft)),
          ),
          Text(value, style: TextStyle(fontSize: 12, color: C.text)),
        ],
      );
}

// ── QUESTS TAB ────────────────────────────────────────────────────────────────

class _QuestsTab extends StatelessWidget {
  const _QuestsTab({required this.vm});

  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final quests = vm.quests;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Text(
                '${quests.length} Quest${quests.length != 1 ? "s" : ""}',
                style: TextStyle(fontSize: 11, color: C.textSoft),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final libraryQuests = await vm.loadLibraryQuests();
                  if (!context.mounted) return;
                  final picked = await QuestPickerDialog.show(
                    context,
                    quests: libraryQuests,
                  );
                  if (picked != null && context.mounted) {
                    await vm.addQuestFromLibrary(picked);
                  }
                },
                child: Text('Bibliothek', style: TextStyle(fontSize: 11, color: C.accent)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(
                      builder: (_) => EditQuestScreen(campaignId: vm.campaign.id),
                    ))
                    .then((_) => vm.reloadQuests()),
                child: Text('Neu', style: TextStyle(fontSize: 11, color: C.accent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: quests.isEmpty
              ? Center(
                  child: Text(
                    'Noch keine Quests',
                    style: TextStyle(fontSize: 13, color: C.textSoft),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  itemCount: quests.length,
                  itemBuilder: (ctx, i) => _QuestRow(
                    quest: quests[i],
                    C: C,
                    selected: vm.selectedQuest?.id == quests[i].id,
                    onTap: () => vm.selectQuest(quests[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuestRow extends StatefulWidget {
  const _QuestRow({required this.quest, required this.C, required this.onTap, this.selected = false});

  final Quest quest;
  final AppColorsExtension C;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_QuestRow> createState() => _QuestRowState();
}

class _QuestRowState extends State<_QuestRow> {
  bool _hovered = false;

  Color _statusColor(AppColorsExtension C) {
    switch (widget.quest.status) {
      case QuestStatus.active:    return C.accent;
      case QuestStatus.completed: return C.green;
      case QuestStatus.failed:    return C.red;
      case QuestStatus.abandoned: return C.textSoft;
      case QuestStatus.onHold:    return C.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    final dot = _statusColor(C);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? C.accent.withValues(alpha: 0.08)
                : _hovered
                    ? C.bgHover
                    : C.bgPanel,
            border: Border.all(
              color: widget.selected ? C.accent.withValues(alpha: 0.4) : C.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.quest.title,
                  style: TextStyle(fontSize: 12, color: C.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── RIGHT PANE ────────────────────────────────────────────────────────────────

class _RightPane extends StatelessWidget {
  const _RightPane({required this.vm});

  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final ort = vm.selectedOrt;

    // Karte-Tab: Graph nimmt immer die volle Breite, Detail-Panel liegt darüber
    if (vm.leftTab == DmBuchLeftTab.karte) {
      return Stack(
        children: [
          Positioned.fill(child: _KarteGraphView(vm: vm)),
          if (ort != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 341,
              child: Container(
                decoration: BoxDecoration(
                  color: C.bgPanel,
                  border: Border(left: BorderSide(color: C.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrtHeader(ort: ort, vm: vm),
                    if (ort.hasBeenVisited) _MemoryBanner(ort: ort, vm: vm, C: C),
                    Expanded(child: _OrtDetail(ort: ort, vm: vm)),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Quests-Tab
    if (vm.leftTab == DmBuchLeftTab.quests) {
      final quest = vm.selectedQuest;
      if (quest == null) {
        return _EmptyFocus(message: 'Wähle eine Quest aus der Liste', C: C);
      }
      return _QuestDetailPane(quest: quest, vm: vm);
    }

    // Spieler-Tab
    if (vm.leftTab == DmBuchLeftTab.spieler) {
      final character = vm.selectedCharacter;
      if (character == null) {
        return _EmptyFocus(message: 'Wähle einen Helden aus der Liste', C: C);
      }
      return _SpielerDetailPane(character: character, vm: vm);
    }

    // Verlauf-Tab: Graphen-Karte + optionales Detail-Panel
    if (vm.leftTab == DmBuchLeftTab.verlauf) {
      final eintrag = vm.selectedVerlaufsEintrag;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _VerlaufsGraphView(vm: vm)),
          if (eintrag != null) ...[
            VerticalDivider(width: 1, thickness: 1, color: C.border),
            SizedBox(
              width: 340,
              child: _VerlaufsDetailPane(eintrag: eintrag, vm: vm),
            ),
          ],
        ],
      );
    }

    // Karte-Tab ohne Auswahl / Fallback
    if (ort == null) {
      return _EmptyFocus(message: 'Wähle einen Marker aus der Karte', C: C);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrtHeader(ort: ort, vm: vm),
        if (ort.hasBeenVisited) _MemoryBanner(ort: ort, vm: vm, C: C),
        Expanded(child: _OrtDetail(ort: ort, vm: vm)),
      ],
    );
  }
}

// ── ORT HEADER ────────────────────────────────────────────────────────────────

class _OrtHeader extends StatelessWidget {
  const _OrtHeader({required this.ort, required this.vm});

  final Ort ort;
  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ort.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _TypeTag(type: ort.type, C: C),
                    const SizedBox(width: 8),
                    Text(
                      '${vm.selectedOrtSessions.length} Session${vm.selectedOrtSessions.length != 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 11, color: C.textSoft),
                    ),
                  ],
                ),
                if (ort.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ort.description,
                    style: TextStyle(fontSize: 12, color: C.textMid, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          _TopBarIconBtn(
            icon: AppIconName.edit,
            C: C,
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => _EditOrtDialog(ort: ort, vm: vm),
            ),
          ),
          _TopBarIconBtn(
            iconData: Icons.map_outlined,
            iconColor: C.accent,
            C: C,
            tooltip: vm.hasChildren(ort.id) ? 'Subkarte öffnen' : 'Subkarte erstellen',
            onTap: () => vm.drillInto(ort),
          ),
          _TopBarIconBtn(
            iconData: ort.mapPositionLocked ? Icons.lock_outline : Icons.lock_open_outlined,
            iconColor: ort.mapPositionLocked ? C.amber : C.textSoft,
            C: C,
            tooltip: ort.mapPositionLocked ? 'Position entsperren' : 'Position sperren',
            onTap: () => vm.toggleOrtPositionLock(ort),
          ),
          _TopBarIconBtn(
            icon: AppIconName.close,
            C: C,
            onTap: vm.deselectOrt,
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.type, required this.C});

  final OrtType type;
  final AppColorsExtension C;

  Color get _color {
    switch (type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _color,
              ),
            ),
          ],
        ),
      );
}

// ── MEMORY BANNER ─────────────────────────────────────────────────────────────

class _MemoryBanner extends StatelessWidget {
  const _MemoryBanner({required this.ort, required this.vm, required this.C});

  final Ort ort;
  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: C.amber.withValues(alpha: 0.08),
          border: Border(bottom: BorderSide(color: C.amber.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: C.amber, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ort.hasMemory
                    ? ort.memory!
                    : 'Dieser Marker wurde bereits besucht.',
                style: TextStyle(fontSize: 12, color: C.amber),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

// ── ORT DETAIL ────────────────────────────────────────────────────────────────

class _OrtDetail extends StatelessWidget {
  const _OrtDetail({required this.ort, required this.vm});

  final Ort ort;
  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    final sceneCount = vm.selectedOrtScenes.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Szenen (primär — was passiert hier)
        _SectionHeader(
          title: sceneCount > 0 ? 'Szenen ($sceneCount)' : 'Szenen',
          C: C,
          action: 'Neue Szene',
          onAction: () => _showCreateSceneDialog(context),
        ),
        const SizedBox(height: 8),
        if (vm.selectedOrtScenes.isEmpty)
          _EmptyHint('Noch keine Szenen für diesen Marker.', C)
        else
          ...vm.selectedOrtScenes.map((scene) => Padding(
                key: ValueKey(scene.id),
                padding: const EdgeInsets.only(bottom: 6),
                child: _SceneMarkerCard(
                  scene: scene,
                  campaign: vm.campaign,
                  C: C,
                  onEdit: () => _openSceneEditor(context, scene),
                  onToggleDone: () => vm.toggleSceneCompleted(scene),
                  onDelete: () => vm.deleteScene(scene),
                ),
              )),
        const SizedBox(height: 14),

        // Verlaufsplan
        _SectionHeader(
          title: 'Verlaufsplan',
          C: C,
          action: 'Hinzufügen',
          onAction: () => vm.addVerlaufsEintrag(
            VerlaufsEintrag.create(
              type: VerlaufsEintragType.ort,
              refId: ort.id,
              label: ort.name,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final steps = vm.verlaufsplan
              .asMap()
              .entries
              .where((e) => e.value.type == VerlaufsEintragType.ort && e.value.refId == ort.id)
              .toList();
          if (steps.isEmpty) return _EmptyHint('Dieser Marker ist noch nicht im Verlaufsplan.', C);
          return Column(
            children: steps.map((e) => _OrtVerlaufsRow(
              index: e.key,
              eintrag: e.value,
              C: C,
              onTap: () {
                vm.setLeftTab(DmBuchLeftTab.verlauf);
                vm.selectVerlaufsEintrag(e.value);
              },
            )).toList(),
          );
        }),
        const SizedBox(height: 14),

        // Sessions
        _SectionHeader(
          title: 'Sessions',
          C: C,
          action: 'Session hinzufügen',
          onAction: () => showDialog<void>(
            context: context,
            builder: (_) => _CreateSessionDialog(ort: ort, vm: vm),
          ),
        ),
        const SizedBox(height: 8),
        if (vm.selectedOrtSessions.isEmpty)
          _EmptyHint('Noch keine Sessions für diesen Marker.', C)
        else
          ...vm.selectedOrtSessions.map((session) => Padding(
                key: ValueKey(session.id),
                padding: const EdgeInsets.only(bottom: 6),
                child: _SessionRow(session: session, vm: vm),
              )),
        const SizedBox(height: 14),

        // Verbindungen zu anderen Orten
        _SectionHeader(
          title: 'Verbindungen',
          C: C,
          action: 'Verbinden',
          onAction: () => _showConnectOrtDialog(context),
        ),
        const SizedBox(height: 8),
        if (ort.connectedOrtIds.isEmpty)
          _EmptyHint('Noch keine Verbindungen zu anderen Markern.', C)
        else
          ...ort.connectedOrtIds.map((targetId) {
            final target = vm.orte.where((o) => o.id == targetId).firstOrNull;
            if (target == null) return const SizedBox.shrink();
            return _ConnectedOrtRow(
              target: target,
              onRemove: () => vm.disconnectOrte(ort, target),
              onSelect: () => vm.navigateToOrt(target),
              C: C,
            );
          }),
        const SizedBox(height: 14),

        // Wiki-Verknüpfungen
        _SectionHeader(
          title: 'Wiki-Einträge',
          C: C,
          action: 'Hinzufügen',
          onAction: () => _showWikiPickerDialog(context),
        ),
        const SizedBox(height: 8),
        if (ort.linkedWikiEntryIds.isEmpty)
          _EmptyHint('Noch keine Wiki-Einträge verknüpft.', C)
        else
          ...ort.linkedWikiEntryIds.map((wikiId) {
            final entry = vm.wikiEntries.where((w) => w.id == wikiId).firstOrNull;
            if (entry == null) {
              return _WikiEntryRow.orphan(
                onRemove: () => vm.unlinkWikiEntry(ort, wikiId),
                C: C,
              );
            }
            return _WikiEntryRow(entry: entry, onRemove: () => vm.unlinkWikiEntry(ort, wikiId), C: C);
          }),
        const SizedBox(height: 14),

        // Live-Modus Aktionen
        if (vm.mode == DmBuchMode.live) ...[
          _SectionHeader(title: 'Live-Aktionen', C: C),
          const SizedBox(height: 8),
          _LiveActionBtn(
            label: 'Als besucht markieren',
            icon: Icons.check_circle_outline,
            color: C.green,
            C: C,
            onTap: () => vm.markOrtVisited(ort),
          ),
          const SizedBox(height: 6),
          _LiveActionBtn(
            label: 'Gedächtnis bearbeiten',
            icon: Icons.edit_note,
            color: C.amber,
            C: C,
            onTap: () => _showMemoryDialog(context),
          ),
        ],
      ],
    );
  }

  void _showMemoryDialog(BuildContext context) {
    final C = context.appColors;
    final ctrl = TextEditingController(text: ort.memory ?? '');
    showDialog<void>(
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
              Text('Gedächtnis — ${ort.name}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 5,
                style: TextStyle(fontSize: 13, color: C.text),
                decoration: InputDecoration(
                  hintText: 'Was passierte beim letzten Besuch?',
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
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      vm.saveMemory(ort, ctrl.text.trim());
                      Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWikiPickerDialog(BuildContext context) async {
    if (vm.wikiEntries.isEmpty) {
      await vm.reloadWikiEntries();
      if (!context.mounted) return;
    }
    final C = context.appColors;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _WikiPickerDialog(ort: ort, vm: vm, C: C),
    );
  }

  void _showConnectOrtDialog(BuildContext context) {
    final C = context.appColors;
    final available = vm.orte
        .where((o) => o.id != ort.id && !ort.connectedOrtIds.contains(o.id))
        .toList();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marker verbinden',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Keine weiteren Marker verfügbar.',
                        style: TextStyle(fontSize: 12, color: C.textSoft)),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final target = available[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: _ortTypeColor(target.type, C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(target.name,
                              style: TextStyle(fontSize: 13, color: C.text)),
                          subtitle: Text(target.type.label,
                              style: TextStyle(fontSize: 11, color: C.textSoft)),
                          onTap: () {
                            vm.connectOrte(ort, target);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Schließen', style: TextStyle(color: C.textMid)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _ortTypeColor(OrtType type, AppColorsExtension C) {
    switch (type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  void _showCreateSceneDialog(BuildContext context) {
    final C = context.appColors;
    final nameCtrl = TextEditingController();
    SceneType selectedType = SceneType.Exploration;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: C.bgPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: C.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Neue Szene', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: TextStyle(fontSize: 13, color: C.text),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: C.textSoft),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Typ', style: TextStyle(fontSize: 11, color: C.textSoft)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: SceneType.values.map((type) {
                      final isSelected = selectedType == type;
                      return GestureDetector(
                        onTap: () => setState(() => selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? C.accent.withValues(alpha: 0.2) : C.bgHover,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSelected ? C.accent : C.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_sceneTypeIcon(type), style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Text(_sceneTypeLabel(type), style: TextStyle(fontSize: 11, color: isSelected ? C.accent : C.text)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          Navigator.of(ctx).pop();
                          final scene = await vm.createSceneForOrt(
                            ort: ort,
                            name: name,
                            type: selectedType,
                          );
                          if (scene != null && context.mounted) {
                            await _openSceneEditor(context, scene);
                          }
                        },
                        style: FilledButton.styleFrom(backgroundColor: C.accent),
                        child: const Text('Erstellen & Bearbeiten'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _sceneTypeIcon(SceneType type) {
    switch (type) {
      case SceneType.Combat:       return '⚔️';
      case SceneType.Social:       return '💬';
      case SceneType.Exploration:  return '🔍';
      case SceneType.Puzzle:       return '🧩';
      case SceneType.Introduction: return '📖';
      case SceneType.Climax:       return '🔥';
      case SceneType.Resolution:   return '🏆';
    }
  }

  static String _sceneTypeLabel(SceneType type) {
    switch (type) {
      case SceneType.Combat:       return 'Kampf';
      case SceneType.Social:       return 'Sozial';
      case SceneType.Exploration:  return 'Erkundung';
      case SceneType.Puzzle:       return 'Rätsel';
      case SceneType.Introduction: return 'Einführung';
      case SceneType.Climax:       return 'Höhepunkt';
      case SceneType.Resolution:   return 'Auflösung';
    }
  }

  Future<void> _openSceneEditor(BuildContext context, Scene scene) async {
    final db = DatabaseConnection.instance;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => EditSceneViewModel(
                sceneRepository: SceneModelRepository(db),
                creatureRepository: CreatureModelRepository(db),
                playerCharacterRepository: PlayerCharacterModelRepository(db),
                questRepository: QuestModelRepository(db),
                soundRepository: SoundModelRepository(db),
                wikiEntryRepository: WikiEntryModelRepository(db),
                encounterRepository: EncounterModelRepository(db),
              ),
            ),
          ],
          child: EditSceneScreen(scene: scene),
        ),
      ),
    );
    // Immer neu laden — der Editor kann die Szene auch ohne explizites Speichern
    // verändern (z.B. Encounter-Erstellung), daher kein result-Check.
    if (ort.id.isNotEmpty) {
      await vm.reloadScenesForOrt(ort.id);
    }
  }
}

class _SceneMarkerCard extends StatelessWidget {
  const _SceneMarkerCard({
    required this.scene,
    required this.campaign,
    required this.C,
    required this.onEdit,
    required this.onToggleDone,
    required this.onDelete,
  });

  final Scene scene;
  final Campaign campaign;
  final AppColorsExtension C;
  final VoidCallback onEdit;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeColor = _sceneTypeColor(scene.sceneType);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scene.isCompleted ? C.border.withValues(alpha: 0.4) : C.border,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scene.isCompleted ? C.bgPanel.withValues(alpha: 0.5) : C.bgPanel,
          border: Border(left: BorderSide(color: typeColor, width: 3)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.only(left: 9, right: 10, top: 2, bottom: 2),
            leading: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                _sceneTypeIcon(scene.sceneType),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scene.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: scene.isCompleted ? C.textSoft : C.text,
                          decoration: scene.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Wrap(
                        spacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            scene.sceneTypeDisplayName,
                            style: TextStyle(fontSize: 11, color: C.textMid),
                          ),
                          if (scene.linkedEncounterId != null)
                            _SceneBadge(Icons.gavel, C.red),
                          if (scene.linkedQuestIds.isNotEmpty)
                            _SceneBadge(Icons.flag_outlined, C.amber,
                                count: scene.linkedQuestIds.length),
                          if (scene.linkedWikiEntryIds.isNotEmpty)
                            _SceneBadge(Icons.menu_book_outlined, C.accent,
                                count: scene.linkedWikiEntryIds.length),
                          if (scene.linkedCharacterIds.isNotEmpty)
                            _SceneBadge(Icons.person_outline, C.textMid,
                                count: scene.linkedCharacterIds.length),
                          if (scene.linkedSoundIds.isNotEmpty)
                            _SceneBadge(Icons.music_note_outlined, C.accent,
                                count: scene.linkedSoundIds.length),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons (icon-only to avoid overflow)
                _IconBtn(
                  icon: scene.isCompleted ? Icons.replay : Icons.radio_button_unchecked,
                  color: scene.isCompleted ? C.textSoft : C.textMid,
                  onTap: onToggleDone,
                ),
                _IconBtn(icon: Icons.edit_outlined, color: C.accent, onTap: onEdit),
                _IconBtn(icon: Icons.close, color: C.textSoft, onTap: onDelete),
              ],
            ),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: C.textMid,
            collapsedIconColor: C.textMid,
            children: [_SceneExpandedContent(scene: scene, campaign: campaign, C: C)],
          ),
        ),
      ),
    );
  }

  static Color _sceneTypeColor(SceneType type) => switch (type) {
    SceneType.Introduction => const Color(0xFF2F6FEB),
    SceneType.Exploration  => const Color(0xFF1A7F4B),
    SceneType.Combat       => const Color(0xFFC93A3A),
    SceneType.Social       => const Color(0xFF7C3AED),
    SceneType.Puzzle       => const Color(0xFFB45309),
    SceneType.Climax       => const Color(0xFF0891B2),
    SceneType.Resolution   => const Color(0xFF6B6B66),
  };

  static String _sceneTypeIcon(SceneType type) => switch (type) {
    SceneType.Combat       => '⚔️',
    SceneType.Social       => '💬',
    SceneType.Exploration  => '🔍',
    SceneType.Puzzle       => '🧩',
    SceneType.Introduction => '📖',
    SceneType.Climax       => '🔥',
    SceneType.Resolution   => '🏆',
  };
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}

class _SceneBadge extends StatelessWidget {
  const _SceneBadge(this.icon, this.color, {this.count});

  final IconData icon;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.75)),
          if (count != null) ...[
            const SizedBox(width: 2),
            Text(
              '$count',
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.75)),
            ),
          ],
        ],
      );
}

// ── Data container for resolved linked items ──────────────────────────────────
class _ResolvedSceneData {
  const _ResolvedSceneData({
    this.encounter,
    this.quests = const [],
    this.wikiEntries = const [],
    this.sounds = const [],
    this.characters = const [],
  });

  final Encounter? encounter;
  final List<Quest> quests;
  final List<WikiEntry> wikiEntries;
  final List<Sound> sounds;
  // each entry: (name, subtitle e.g. "Lvl 3" / "CR 2", isPC)
  final List<({String name, String? subtitle, bool isPC})> characters;
}

class _SceneExpandedContent extends StatefulWidget {
  const _SceneExpandedContent({required this.scene, required this.campaign, required this.C});

  final Scene scene;
  final Campaign campaign;
  final AppColorsExtension C;

  @override
  State<_SceneExpandedContent> createState() => _SceneExpandedContentState();
}

class _SceneExpandedContentState extends State<_SceneExpandedContent> {
  _ResolvedSceneData? _data;
  final _soundService = MultiStreamSoundService();
  final _soundPlaying = <String>{};

  Scene get _scene => widget.scene;
  AppColorsExtension get C => widget.C;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _soundService.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(Sound sound) async {
    if (_soundPlaying.contains(sound.id)) {
      await _soundService.stopSound(sound.id);
      if (mounted) setState(() => _soundPlaying.remove(sound.id));
    } else {
      final channelId = await _soundService.addSound(sound, autoPlay: true, isLooping: true);
      if (channelId != null && mounted) setState(() => _soundPlaying.add(sound.id));
    }
  }

  Future<void> _startCombat() async {
    final scene = _scene;
    String? title;
    String? description;
    final characterIds = List<String>.from(scene.linkedCharacterIds);
    List<String> monsterIds = const [];

    if (scene.linkedEncounterId != null) {
      final db = DatabaseConnection.instance;
      final encounter = await EncounterModelRepository(db).findById(scene.linkedEncounterId!);
      if (encounter != null) {
        title = encounter.title;
        description = encounter.description;
        final participants =
            await EncounterParticipantModelRepository(db).findByEncounter(encounter.id);
        for (final p in participants.where((p) => p.characterId != null)) {
          if (!characterIds.contains(p.characterId!)) characterIds.add(p.characterId!);
        }
        monsterIds =
            participants.where((p) => p.creatureId != null).map((p) => p.creatureId!).toList();
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => EncounterSetupScreen(
          campaign: widget.campaign,
          scene: scene,
          encounterTitle: title,
          preselectedDescription: description,
          preselectedCharacterIds: characterIds,
          preselectedMonsterIds: monsterIds,
        ),
      ),
    );
  }

  Future<void> _load() async {
    final db = DatabaseConnection.instance;
    final scene = _scene;

    // Load all in parallel using typed futures
    final results = await (
      _loadEncounter(db, scene.linkedEncounterId),
      _loadQuests(db, scene.linkedQuestIds),
      _loadWikiEntries(db, scene.linkedWikiEntryIds),
      _loadSounds(db, scene.linkedSoundIds),
      _loadCharacters(db, scene.linkedCharacterIds),
    ).wait;

    if (!mounted) return;
    setState(() {
      _data = _ResolvedSceneData(
        encounter: results.$1,
        quests: results.$2,
        wikiEntries: results.$3,
        sounds: results.$4,
        characters: results.$5,
      );
    });
  }

  static Future<Encounter?> _loadEncounter(DatabaseConnection db, String? id) async {
    if (id == null) return null;
    try { return await EncounterModelRepository(db).findById(id); } catch (_) { return null; }
  }

  static Future<List<Quest>> _loadQuests(DatabaseConnection db, List<String> ids) async {
    final repo = QuestModelRepository(db);
    final result = <Quest>[];
    for (final id in ids) {
      try { final q = await repo.findById(id); if (q != null) result.add(q); } catch (_) {}
    }
    return result;
  }

  static Future<List<WikiEntry>> _loadWikiEntries(DatabaseConnection db, List<String> ids) async {
    final repo = WikiEntryModelRepository(db);
    final result = <WikiEntry>[];
    for (final id in ids) {
      try { final e = await repo.findById(id); if (e != null) result.add(e); } catch (_) {}
    }
    return result;
  }

  static Future<List<Sound>> _loadSounds(DatabaseConnection db, List<String> ids) async {
    final repo = SoundModelRepository(db);
    final result = <Sound>[];
    for (final id in ids) {
      try { final s = await repo.findById(id); if (s != null) result.add(s); } catch (_) {}
    }
    return result;
  }

  static Future<List<({String name, String? subtitle, bool isPC})>> _loadCharacters(
    DatabaseConnection db,
    List<String> ids,
  ) async {
    final pcRepo = PlayerCharacterModelRepository(db);
    final creatureRepo = CreatureModelRepository(db);
    final result = <({String name, String? subtitle, bool isPC})>[];
    for (final id in ids) {
      try {
        final pc = await pcRepo.findById(id);
        if (pc != null) {
          result.add((name: pc.name, subtitle: 'Lvl ${pc.level}', isPC: true));
          continue;
        }
      } catch (_) {}
      try {
        final creature = await creatureRepo.findById(id);
        if (creature != null) {
          result.add((
            name: creature.name,
            subtitle: creature.challengeRating != null ? 'CR ${creature.challengeRating}' : null,
            isPC: false,
          ));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> _updateQuestStatus(Quest quest, QuestStatus newStatus) async {
    if (quest.status == newStatus) return;
    try {
      final repo = QuestModelRepository(DatabaseConnection.instance);
      final updated = await repo.updateStatus(quest.id, newStatus);
      if (!mounted) return;
      setState(() {
        _data = _data == null
            ? null
            : _ResolvedSceneData(
                encounter: _data!.encounter,
                quests: _data!.quests.map((q) => q.id == quest.id ? updated : q).toList(),
                wikiEntries: _data!.wikiEntries,
                sounds: _data!.sounds,
                characters: _data!.characters,
              );
      });
    } catch (e) {
      debugPrint('[_SceneExpandedContent] Quest status update failed: $e');
    }
  }

  Widget _buildQuestCard(Quest quest) {
    final statusColor = _questStatusColor(quest.status, C);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Expanded(child: Text(quest.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.text))),
              Text(_questStatusLabel(quest.status), style: TextStyle(fontSize: 10, color: statusColor)),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _QuestStatusBtn(label: 'Aktiv',       icon: Icons.play_circle_outline,   color: C.green,  isSelected: quest.status == QuestStatus.active,    onTap: () => _updateQuestStatus(quest, QuestStatus.active)),
              const SizedBox(width: 4),
              _QuestStatusBtn(label: 'Erledigt',    icon: Icons.check_circle_outline,  color: C.accent, isSelected: quest.status == QuestStatus.completed, onTap: () => _updateQuestStatus(quest, QuestStatus.completed)),
              const SizedBox(width: 4),
              _QuestStatusBtn(label: 'Aufgegeben',  icon: Icons.remove_circle_outline, color: C.red, isSelected: quest.status == QuestStatus.abandoned,  onTap: () => _updateQuestStatus(quest, QuestStatus.abandoned)),
            ],
          ),
        ],
      ),
    );
  }

  static Color _questStatusColor(QuestStatus status, AppColorsExtension C) => switch (status) {
    QuestStatus.active    => C.green,
    QuestStatus.completed => C.accent,
    QuestStatus.failed    => C.red,
    QuestStatus.abandoned => C.red,
    QuestStatus.onHold    => C.amber,
  };

  static String _questStatusLabel(QuestStatus status) => switch (status) {
    QuestStatus.active    => 'Aktiv',
    QuestStatus.completed => 'Erledigt',
    QuestStatus.failed    => 'Fehlgeschlagen',
    QuestStatus.abandoned => 'Aufgegeben',
    QuestStatus.onHold    => 'Pausiert',
  };

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: C.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description ──────────────────────────────────────────────────
          if (_scene.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('BESCHREIBUNG'),
            const SizedBox(height: 4),
            Text(_scene.description, style: TextStyle(fontSize: 12, color: C.textMid, height: 1.6)),
          ],

          // ── Encounter ────────────────────────────────────────────────────
          if (_scene.linkedEncounterId != null) ...[
            const SizedBox(height: 10),
            _sectionLabel('ENCOUNTER'),
            const SizedBox(height: 6),
            data == null
                ? _loadingDot()
                : data.encounter != null
                    ? _LinkChip(icon: Icons.gavel, label: data.encounter!.title, color: C.red)
                    : _LinkChip(icon: Icons.gavel, label: 'Encounter', color: C.red),
          ],

          // ── Characters ───────────────────────────────────────────────────
          if (_scene.linkedCharacterIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('CHARAKTERE & NPCS'),
            const SizedBox(height: 6),
            data == null
                ? _loadingDot()
                : data.characters.isEmpty
                    ? Text('${_scene.linkedCharacterIds.length} verknüpft',
                        style: TextStyle(fontSize: 11, color: C.textSoft))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: data.characters.map((c) => _LinkChip(
                          icon: c.isPC ? Icons.person : Icons.smart_toy_outlined,
                          label: c.subtitle != null ? '${c.name} (${c.subtitle})' : c.name,
                          color: c.isPC ? C.accent : C.textMid,
                        )).toList(),
                      ),
          ],

          // ── Quests ───────────────────────────────────────────────────────
          if (_scene.linkedQuestIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('QUESTS'),
            const SizedBox(height: 6),
            data == null
                ? _loadingDot()
                : data.quests.isEmpty
                    ? Text('${_scene.linkedQuestIds.length} verknüpft',
                        style: TextStyle(fontSize: 11, color: C.textSoft))
                    : Column(
                        children: data.quests
                            .map((q) => _buildQuestCard(q))
                            .toList(),
                      ),
          ],

          // ── Wiki entries ─────────────────────────────────────────────────
          if (_scene.linkedWikiEntryIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('WIKI-EINTRÄGE'),
            const SizedBox(height: 6),
            data == null
                ? _loadingDot()
                : data.wikiEntries.isEmpty
                    ? Text('${_scene.linkedWikiEntryIds.length} verknüpft',
                        style: TextStyle(fontSize: 11, color: C.textSoft))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: data.wikiEntries
                            .map((e) => _LinkChip(icon: Icons.menu_book_outlined, label: e.title, color: C.accent))
                            .toList(),
                      ),
          ],

          // ── Sounds ───────────────────────────────────────────────────────
          if (_scene.linkedSoundIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('SOUNDS'),
            const SizedBox(height: 6),
            data == null
                ? _loadingDot()
                : data.sounds.isEmpty
                    ? Text('${_scene.linkedSoundIds.length} verknüpft',
                        style: TextStyle(fontSize: 11, color: C.textSoft))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: data.sounds.map((s) {
                          final isPlaying = _soundPlaying.contains(s.id);
                          final color = isPlaying ? C.green : C.accent;
                          return GestureDetector(
                            onTap: () => _toggleSound(s),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: color.withValues(alpha: 0.30)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                      size: 10,
                                      color: color,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        s.name,
                                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ],

          // ── Meta (complexity / duration) ─────────────────────────────────
          if (_scene.complexity != null || _scene.estimatedDuration != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (_scene.complexity != null)
                  _LinkChip(icon: Icons.trending_up, label: _scene.complexityDisplayName, color: C.accent),
                if (_scene.estimatedDuration != null)
                  _LinkChip(
                    icon: Icons.schedule,
                    label: _formatDuration(_scene.estimatedDuration!),
                    color: C.accent,
                  ),
              ],
            ),
          ],

          // ── Kampf starten ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _startCombat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: C.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: C.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel, size: 13, color: C.red),
                  const SizedBox(width: 5),
                  Text(
                    'Kampf starten',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: C.textSoft, letterSpacing: 0.5),
      );

  Widget _loadingDot() => SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: C.textSoft),
      );

  static String _formatDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}

class _QuestStatusBtn extends StatelessWidget {
  const _QuestStatusBtn({required this.label, required this.icon, required this.color, required this.isSelected, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: isSelected ? color : color.withValues(alpha: 0.6)),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? color : color.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _WikiEntryRow extends StatelessWidget {
  const _WikiEntryRow({required this.entry, required this.onRemove, required this.C});
  const _WikiEntryRow.orphan({required this.onRemove, required this.C})
      : entry = null;

  final WikiEntry? entry;
  final VoidCallback onRemove;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final orphaned = entry == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: orphaned ? C.border.withValues(alpha: 0.5) : C.border),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 13, color: orphaned ? C.textSoft : C.accent),
          const SizedBox(width: 8),
          Expanded(
            child: orphaned
                ? Text('Eintrag nicht gefunden',
                    style: TextStyle(fontSize: 12, color: C.textSoft, fontStyle: FontStyle.italic))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry!.title,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.text),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(entry!.entryType.name,
                          style: TextStyle(fontSize: 10, color: C.textSoft)),
                    ],
                  ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 13, color: C.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _WikiPickerDialog extends StatelessWidget {
  const _WikiPickerDialog({required this.ort, required this.vm, required this.C});

  final Ort ort;
  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final available = vm.wikiEntries
        .where((w) => !ort.linkedWikiEntryIds.contains(w.id))
        .toList();

    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wiki-Eintrag verknüpfen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 12),
              if (vm.wikiEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Keine Wiki-Einträge in dieser Kampagne vorhanden.',
                      style: TextStyle(fontSize: 12, color: C.textSoft)),
                )
              else if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Alle Wiki-Einträge bereits verknüpft.',
                      style: TextStyle(fontSize: 12, color: C.textSoft)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (_, i) {
                      final entry = available[i];
                      return ListTile(
                        dense: true,
                        title: Text(entry.title,
                            style: TextStyle(fontSize: 13, color: C.text)),
                        subtitle: Text(entry.entryType.name,
                            style: TextStyle(fontSize: 11, color: C.textSoft)),
                        onTap: () {
                          vm.linkWikiEntry(ort, entry.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Schließen', style: TextStyle(color: C.textMid)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedOrtRow extends StatelessWidget {
  const _ConnectedOrtRow({
    required this.target, required this.onRemove,
    required this.onSelect, required this.C,
  });
  final Ort target;
  final VoidCallback onRemove;
  final VoidCallback onSelect;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _typeColor(C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: onSelect,
                child: Text(target.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            Text(target.type.label,
                style: TextStyle(fontSize: 10, color: C.textSoft)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 13, color: C.textSoft),
              ),
            ),
          ],
        ),
      );

  Color _typeColor(AppColorsExtension C) {
    switch (target.type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }
}

class _SessionRow extends StatefulWidget {
  const _SessionRow({required this.session, required this.vm});

  final Session session;
  final DmBuchViewModel vm;

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
  bool _hovered = false;

  Color _statusColor(AppColorsExtension C) {
    if (widget.session.isCompleted) return C.amber;
    if (widget.session.isActive) return C.green;
    return C.textSoft;
  }

  String _statusLabel() {
    if (widget.session.isCompleted) return 'Abgeschlossen';
    if (widget.session.isActive) return 'Aktiv';
    return 'Geplant';
  }

  String _formattedDate() {
    final d = widget.session.createdAt;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final statusColor = _statusColor(C);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openSession(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? statusColor.withValues(alpha: 0.45) : C.border,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _hovered ? C.bgHover : C.bgPanel,
              border: Border(left: BorderSide(color: statusColor, width: 3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.session.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: C.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(),
                            style: TextStyle(fontSize: 10, color: C.textSoft),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formattedDate(),
                            style: TextStyle(fontSize: 10, color: C.textSoft),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_hovered)
                  GestureDetector(
                    onTap: () => _confirmDelete(context, C),
                    child: Icon(Icons.delete_outline, size: 13, color: C.red),
                  )
                else
                  Icon(Icons.play_arrow_rounded, size: 14,
                      color: statusColor.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSession(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveSessionScreen(
          session: widget.session,
          campaign: widget.vm.campaign,
        ),
      ),
    );
    if (context.mounted) widget.vm.reloadSessions();
  }

  void _confirmDelete(BuildContext context, AppColorsExtension C) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        title: Text('Session löschen?',
            style: TextStyle(fontSize: 15, color: C.text)),
        content: Text(
          '"${widget.session.title}" wird unwiderruflich gelöscht.',
          style: TextStyle(fontSize: 13, color: C.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
          ),
          FilledButton(
            onPressed: () {
              widget.vm.deleteOrtSession(widget.session.id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: C.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _OrtVerlaufsRow extends StatefulWidget {
  const _OrtVerlaufsRow({required this.index, required this.eintrag, required this.C, required this.onTap});

  final int index;
  final VerlaufsEintrag eintrag;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_OrtVerlaufsRow> createState() => _OrtVerlaufsRowState();
}

class _OrtVerlaufsRowState extends State<_OrtVerlaufsRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    final e = widget.eintrag;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? C.bgHover : C.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.border),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: e.isDone ? 0.05 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: C.accent.withValues(alpha: e.isDone ? 0.2 : 0.4)),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: e.isDone ? C.textSoft : C.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: e.isDone ? C.textSoft : C.text,
                    decoration: e.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (e.isDone)
                Icon(Icons.check_circle, size: 13, color: C.green)
              else
                Icon(Icons.chevron_right, size: 13, color: C.textSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.C,
    this.action,
    this.onAction,
  });

  final String title;
  final AppColorsExtension C;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text),
          ),
          const Spacer(),
          if (action != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: TextStyle(fontSize: 11, color: C.accent),
              ),
            ),
        ],
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text, this.C);

  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: TextStyle(fontSize: 12, color: C.textSoft)),
      );
}

class _LiveActionBtn extends StatelessWidget {
  const _LiveActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.C,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

// ── CREATE ORT DIALOG ─────────────────────────────────────────────────────────

class _CreateOrtDialog extends StatefulWidget {
  const _CreateOrtDialog({required this.vm});

  final DmBuchViewModel vm;

  @override
  State<_CreateOrtDialog> createState() => _CreateOrtDialogState();
}

class _CreateOrtDialogState extends State<_CreateOrtDialog> {
  final _nameCtrl = TextEditingController();
  OrtType _type = OrtType.other;
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Dialog(
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
            Text('Neuer Marker',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
            const SizedBox(height: 16),
            _field(context, C, controller: _nameCtrl, hint: 'Name des Markers', autofocus: true),
            const SizedBox(height: 10),
            _TypeDropdown(
              value: _type,
              C: C,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 10),
            _field(context, C, controller: _descCtrl, hint: 'Beschreibung (optional)', maxLines: 3),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final ort = await widget.vm.createOrt(
                      name: name,
                      type: _type,
                      description: _descCtrl.text.trim(),
                      parentOrtId: widget.vm.currentMapParentId,
                    );
                    if (context.mounted) Navigator.of(context).pop(ort);
                  },
                  style: FilledButton.styleFrom(backgroundColor: C.accent),
                  child: const Text('Erstellen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    AppColorsExtension C, {
    required TextEditingController controller,
    required String hint,
    bool autofocus = false,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        style: TextStyle(fontSize: 13, color: C.text),
        decoration: InputDecoration(
          hintText: hint,
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
      );
}

// ── EDIT ORT DIALOG ───────────────────────────────────────────────────────────

class _EditOrtDialog extends StatefulWidget {
  const _EditOrtDialog({required this.ort, required this.vm});

  final Ort ort;
  final DmBuchViewModel vm;

  @override
  State<_EditOrtDialog> createState() => _EditOrtDialogState();
}

class _EditOrtDialogState extends State<_EditOrtDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late OrtType _type;
  String? _tokenImagePath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ort.name);
    _descCtrl = TextEditingController(text: widget.ort.description);
    _type = widget.ort.type;
    _tokenImagePath = widget.ort.tokenImagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Dialog(
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
            Row(
              children: [
                Expanded(
                  child: Text('Marker bearbeiten',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context, C),
                  child: Tooltip(
                    message: 'Marker löschen',
                    child: AppIcon(AppIconName.trash, size: 15, color: C.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: C.text),
              decoration: _inputDeco(C, 'Name'),
            ),
            const SizedBox(height: 10),
            _TypeDropdown(
              value: _type,
              C: C,
              onChanged: (t) => setState(() => _type = t),
            ),
            if (_type == OrtType.token) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: C.bgHover,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.border),
                      ),
                      child: Text(
                        _tokenImagePath != null
                            ? ResourceService.isResourceRef(_tokenImagePath)
                                ? ResourceService.filenameFromRef(_tokenImagePath!)
                                : _tokenImagePath!.split(r'\').last.split('/').last
                            : 'Kein Bild',
                        style: TextStyle(fontSize: 12, color: _tokenImagePath != null ? C.text : C.textSoft),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final ref = await pickResource(context);
                      if (ref != null) setState(() => _tokenImagePath = ref);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: C.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.accent.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.image_outlined, size: 16, color: C.accent),
                    ),
                  ),
                  if (_tokenImagePath != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _tokenImagePath = null),
                      child: Icon(Icons.close, size: 16, color: C.textSoft),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: C.text),
              decoration: _inputDeco(C, 'Beschreibung'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await widget.vm.updateOrt(widget.ort.copyWith(
                      name: name,
                      type: _type,
                      description: _descCtrl.text.trim(),
                      tokenImagePath: _tokenImagePath,
                    ));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(backgroundColor: C.accent),
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(AppColorsExtension C, String hint) => InputDecoration(
        hintText: hint,
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
      );

  void _confirmDelete(BuildContext context, AppColorsExtension C) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        title: Text('Marker löschen?',
            style: TextStyle(fontSize: 15, color: C.text)),
        content: Text(
          '"${widget.ort.name}" und alle zugeordneten Szenen werden unwiderruflich gelöscht.',
          style: TextStyle(fontSize: 13, color: C.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              widget.vm.deleteOrt(widget.ort.id);
            },
            style: FilledButton.styleFrom(backgroundColor: C.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// ── CREATE SESSION DIALOG ─────────────────────────────────────────────────────

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog({required this.ort, required this.vm});

  final Ort ort;
  final DmBuchViewModel vm;

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _titleCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Dialog(
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
              'Session für ${widget.ort.name}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: C.text),
              decoration: _inputDeco(C, 'Titel der Session'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final title = _titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    await widget.vm.createSessionForOrt(widget.ort, title: title);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(backgroundColor: C.accent),
                  child: const Text('Erstellen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(AppColorsExtension C, String hint) => InputDecoration(
        hintText: hint,
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
      );
}

// ── TYPE DROPDOWN ─────────────────────────────────────────────────────────────

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.C, required this.onChanged});

  final OrtType value;
  final AppColorsExtension C;
  final void Function(OrtType) onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<OrtType>(
        value: value,
        dropdownColor: C.bgPanel,
        style: TextStyle(fontSize: 13, color: C.text),
        decoration: InputDecoration(
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
        items: OrtType.values
            .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.label),
                ))
            .toList(),
        onChanged: (t) { if (t != null) onChanged(t); },
      );
}

// ── LIVE VIEW DIALOG ─────────────────────────────────────────────────────────

class _LiveViewDialog extends StatelessWidget {
  const _LiveViewDialog({required this.lanVm});

  final LanMapViewModel lanVm;

  Offset get _norm => lanVm.viewportNorm ?? const Offset(0.5, 0.5);

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ListenableBuilder(
      listenable: lanVm,
      builder: (context, _) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: C.border),
        ),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, C),
              Divider(height: 1, color: C.border),
              _buildConnection(context, C),
              Divider(height: 1, color: C.border),
              _buildMapArea(C),
              Divider(height: 1, color: C.border),
              _buildPaintModeRow(C),
              Divider(height: 1, color: C.border),
              _buildFogRow(C),
              Divider(height: 1, color: C.border),
              _buildZoomRow(C),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension C) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
        child: Row(
          children: [
            Icon(Icons.wifi_tethering, size: 14, color: C.accent),
            const SizedBox(width: 8),
            Text('Karte teilen',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
            const Spacer(),
            GestureDetector(
              onTap: () => lanVm.isRunning ? lanVm.stopServer() : lanVm.startServer(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: lanVm.isRunning
                      ? C.green.withValues(alpha: 0.12)
                      : C.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: lanVm.isRunning
                        ? C.green.withValues(alpha: 0.40)
                        : C.accent.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lanVm.isRunning ? C.green : C.textSoft,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      lanVm.isRunning ? 'Aktiv' : 'Starten',
                      style: TextStyle(
                        fontSize: 11,
                        color: lanVm.isRunning ? C.green : C.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 15, color: C.textSoft),
              ),
            ),
          ],
        ),
      );

  Widget _buildConnection(BuildContext context, AppColorsExtension C) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // QR code
            if (lanVm.isRunning)
              QrImageView(
                data: lanVm.lanUrl,
                size: 64,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              )
            else
              const SizedBox(
                width: 64,
                height: 64,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!lanVm.isRunning) return;
                      Clipboard.setData(ClipboardData(text: lanVm.lanUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('URL kopiert'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.bgHover,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: C.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lanVm.isRunning ? lanVm.lanUrl : 'Server startet…',
                              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy, size: 11, color: C.textSoft),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: lanVm.clientCount > 0 ? C.green : C.textSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${lanVm.clientCount} Zuschauer verbunden',
                          style: TextStyle(fontSize: 11, color: C.textMid)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // Interactive map: tap/drag paints fog cells (reveal/cover mode) or moves viewport.
  Widget _buildMapArea(AppColorsExtension C) {
    if (lanVm.imagePath == null) {
      return Container(
        height: 160,
        color: C.bgHover,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 36, color: C.textSoft),
              const SizedBox(height: 8),
              Text('Keine Karte geladen', style: TextStyle(fontSize: 12, color: C.textSoft)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 220.0;
        final isPaintMode = lanVm.paintMode == 'reveal' || lanVm.paintMode == 'cover';
        final norm = _norm;

        void paintAt(Offset localPos) {
          final col = (localPos.dx / w * 20).floor().clamp(0, 19);
          final row = (localPos.dy / h * 20).floor().clamp(0, 19);
          lanVm.paintCell(row * 20 + col);
        }

        return SizedBox(
          height: h,
          child: GestureDetector(
            onTapUp: (d) {
              if (isPaintMode) {
                paintAt(d.localPosition);
              } else {
                lanVm.moveViewportTo(Offset(
                  (d.localPosition.dx / w).clamp(0.0, 1.0),
                  (d.localPosition.dy / h).clamp(0.0, 1.0),
                ));
              }
            },
            onPanUpdate: (d) {
              if (isPaintMode) {
                paintAt(d.localPosition);
              } else {
                lanVm.moveViewportTo(Offset(
                  (_norm.dx + d.delta.dx / w).clamp(0.0, 1.0),
                  (_norm.dy + d.delta.dy / h).clamp(0.0, 1.0),
                ));
              }
            },
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(lanVm.imagePath!),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DialogFogPainter(
                      revealedCells: Set.unmodifiable(lanVm.revealedCells),
                      fogEnabled: lanVm.fogEnabled,
                    ),
                  ),
                ),
                if (!isPaintMode) ...[
                  // Crosshair — vertical line
                  Positioned(
                    left: norm.dx * w - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  // Crosshair — horizontal line
                  Positioned(
                    top: norm.dy * h - 1,
                    left: 0,
                    right: 0,
                    child: Container(height: 1, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  // Centre dot
                  Positioned(
                    left: norm.dx * w - 5,
                    top: norm.dy * h - 5,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        border: Border.all(color: Colors.black45),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaintModeRow(AppColorsExtension C) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Text('Modus:', style: TextStyle(fontSize: 11, color: C.textMid)),
            const SizedBox(width: 8),
            _ZoomPill(
              label: 'Viewport',
              active: lanVm.paintMode != 'reveal' && lanVm.paintMode != 'cover',
              C: C,
              onTap: () => lanVm.setPaintMode('token'),
            ),
            const SizedBox(width: 4),
            _ZoomPill(
              label: 'Enthüllen',
              active: lanVm.paintMode == 'reveal',
              C: C,
              onTap: () => lanVm.setPaintMode('reveal'),
            ),
            const SizedBox(width: 4),
            _ZoomPill(
              label: 'Decken',
              active: lanVm.paintMode == 'cover',
              C: C,
              onTap: () => lanVm.setPaintMode('cover'),
            ),
          ],
        ),
      );

  Widget _buildFogRow(AppColorsExtension C) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Text('Nebel:', style: TextStyle(fontSize: 11, color: C.textMid)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: lanVm.toggleFog,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                  color: lanVm.fogEnabled ? C.accent : C.bgHover,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: lanVm.fogEnabled ? C.accent : C.border),
                ),
                child: Align(
                  alignment: lanVm.fogEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: lanVm.revealAll,
              child: Text('Alles', style: TextStyle(fontSize: 11, color: C.textMid)),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: lanVm.coverAll,
              child: Text('Alles decken', style: TextStyle(fontSize: 11, color: C.textMid)),
            ),
          ],
        ),
      );

  Widget _buildZoomRow(AppColorsExtension C) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text('Zoom:', style: TextStyle(fontSize: 11, color: C.textMid)),
            const SizedBox(width: 8),
            for (final z in [0.5, 1.0, 2.0, 4.0]) ...[
              _ZoomPill(
                label: z < 1 ? '${(z * 100).toInt()}%' : '${z.toInt()}×',
                active: lanVm.broadcastScale == z,
                C: C,
                onTap: () {
                  if (lanVm.viewportNorm == null) {
                    lanVm.moveViewportTo(const Offset(0.5, 0.5));
                  }
                  lanVm.setBroadcastScale(z);
                },
              ),
              const SizedBox(width: 4),
            ],
            const Spacer(),
            GestureDetector(
              onTap: lanVm.clearViewport,
              child: Text('Reset', style: TextStyle(fontSize: 11, color: C.textSoft)),
            ),
          ],
        ),
      );
}

class _ZoomPill extends StatelessWidget {
  const _ZoomPill({
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: active ? C.accent.withValues(alpha: 0.12) : C.bgHover,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: active ? C.accent.withValues(alpha: 0.4) : C.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? C.accent : C.textMid,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}

class _DialogFogPainter extends CustomPainter {
  const _DialogFogPainter({required this.revealedCells, required this.fogEnabled});

  final Set<int> revealedCells;
  final bool fogEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    if (!fogEnabled) return;
    const cols = 20;
    const rows = 20;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final paint = Paint()..color = const Color(0xD9000000);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!revealedCells.contains(r * cols + c)) {
          canvas.drawRect(Rect.fromLTWH(c * cw, r * ch, cw, ch), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DialogFogPainter old) =>
      old.revealedCells != revealedCells || old.fogEnabled != fogEnabled;
}

// ── DM-TOOLS MENÜ BUTTON ─────────────────────────────────────────────────────

class _DmBuchMenuBtn extends StatelessWidget {
  const _DmBuchMenuBtn({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return PopupMenuButton<int>(
      offset: const Offset(0, 36),
      color: C.bgPanel,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: C.border),
      ),
      tooltip: '',
      itemBuilder: (ctx) => _buildMenuItems(ctx, themeNotifier),
      onSelected: (value) => _onSelected(context, value, themeNotifier),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: C.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: C.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_tethering, size: 12, color: C.accent),
            const SizedBox(width: 4),
            Text('Teilen', style: TextStyle(fontSize: 11, color: C.accent)),
            const SizedBox(width: 3),
            Icon(Icons.expand_more, size: 12, color: C.accent),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<int>> _buildMenuItems(BuildContext ctx, ThemeNotifier themeNotifier) {
    final lanVm = ctx.read<LanMapViewModel>();
    final scale = lanVm.broadcastScale;
    final scaleLabel = '${scale.toStringAsFixed(1)}×';
    return [
      _item(1, Icons.wifi_tethering, 'Karte teilen'),
      const PopupMenuDivider(height: 8),
      _item(2, Icons.edit_calendar_outlined, 'Modus: Vorbereitung',
          active: vm.mode == DmBuchMode.vorbereitung),
      _item(3, Icons.play_circle_outline, 'Modus: Live',
          active: vm.mode == DmBuchMode.live),
      const PopupMenuDivider(height: 8),
      _item(4, Icons.zoom_in, 'Zoom +', subtitle: scaleLabel),
      _item(5, Icons.zoom_out, 'Zoom −', subtitle: scaleLabel),
      _item(6, Icons.center_focus_strong_outlined, 'Karte zentrieren'),
      _item(7, Icons.location_disabled_outlined, 'Viewport zurücksetzen'),
      const PopupMenuDivider(height: 8),
      _item(
        8,
        themeNotifier.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        themeNotifier.isDark ? 'Helles Design' : 'Dunkles Design',
      ),
      if (vm.campaign.templateId != null) ...[
        const PopupMenuDivider(height: 8),
        _item(9, Icons.sync, 'Vorlage übernehmen', loading: vm.isSyncing),
      ],
      if (vm.canSyncToCloud) ...[
        const PopupMenuDivider(height: 8),
        _item(10, Icons.cloud_upload_outlined, 'In Cloud speichern', loading: vm.isSyncing),
      ],
    ];
  }

  PopupMenuItem<int> _item(
    int value,
    IconData icon,
    String label, {
    bool active = false,
    bool loading = false,
    String? subtitle,
  }) =>
      PopupMenuItem<int>(
        value: value,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: C.bgHover,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 9,
                    color: C.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: C.textMid),
              )
            else
              Icon(icon, size: 14, color: active ? C.accent : C.textMid),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? C.accent : C.text,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(fontSize: 10, color: C.textSoft)),
            if (active)
              Icon(Icons.check, size: 12, color: C.accent),
          ],
        ),
      );

  void _onSelected(BuildContext context, int value, ThemeNotifier themeNotifier) {
    final lanVm = context.read<LanMapViewModel>();
    switch (value) {
      case 1:
        final lanVm = context.read<LanMapViewModel>();
        showDialog<void>(
          context: context,
          builder: (_) => _LiveViewDialog(lanVm: lanVm),
        );
      case 2:
        vm.setMode(DmBuchMode.vorbereitung);
      case 3:
        vm.setMode(DmBuchMode.live);
      case 4:
        _zoomIn(lanVm);
      case 5:
        _zoomOut(lanVm);
      case 6:
        lanVm.moveViewportTo(const Offset(0.5, 0.5));
      case 7:
        lanVm.clearViewport();
      case 8:
        themeNotifier.toggle();
      case 9:
        _syncFromTemplate(context);
      case 10:
        _syncToCloud(context);
    }
  }

  void _zoomIn(LanMapViewModel lanVm) {
    if (lanVm.viewportNorm == null) lanVm.moveViewportTo(const Offset(0.5, 0.5));
    lanVm.setBroadcastScale(lanVm.broadcastScale + 1.0);
  }

  void _zoomOut(LanMapViewModel lanVm) {
    if (lanVm.viewportNorm == null) lanVm.moveViewportTo(const Offset(0.5, 0.5));
    lanVm.setBroadcastScale(lanVm.broadcastScale - 1.0);
  }

  Future<void> _syncFromTemplate(BuildContext context) async {
    final result = await vm.syncFromTemplate();
    if (!context.mounted) return;
    final ok = result != null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? result.summary : 'Sync fehlgeschlagen'),
      duration: const Duration(seconds: 3),
      backgroundColor: ok ? C.green : C.red,
    ));
  }

  Future<void> _syncToCloud(BuildContext context) async {
    final ok = await vm.syncToCloud();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Erfolgreich in Cloud gespeichert' : 'Cloud-Sync fehlgeschlagen'),
      duration: const Duration(seconds: 3),
      backgroundColor: ok ? C.green : C.red,
    ));
  }
}

// ── SPIELER TAB ───────────────────────────────────────────────────────────────

class _SpielerTab extends StatefulWidget {
  const _SpielerTab({required this.vm});
  final DmBuchViewModel vm;

  @override
  State<_SpielerTab> createState() => _SpielerTabState();
}

class _SpielerTabState extends State<_SpielerTab> {
  late final PlayerCharacterModelRepository _pcRepo;
  late final PlayerModelRepository _playerRepo;

  @override
  void initState() {
    super.initState();
    _pcRepo = PlayerCharacterModelRepository(DatabaseConnection.instance);
    _playerRepo = PlayerModelRepository(DatabaseConnection.instance);
  }

  Future<void> _createNewHero(BuildContext context) async {
    final C = context.appColors;
    final players = await _playerRepo.findAllSorted();
    if (!mounted) return;

    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Erst Spieler anlegen (Heimatbildschirm → Spieler)'),
        backgroundColor: C.red,
      ));
      return;
    }

    final picked = await _showPlayerPickerSheet(context, players);
    if (!mounted) return;
    if (picked == null) return; // dismissed

    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EditPCScreen(
        campaignId: widget.vm.campaign.id,
        initialPlayerId: picked,
      ),
    ));
    if (mounted) widget.vm.reloadCharacters();
  }

  Future<String?> _showPlayerPickerSheet(
      BuildContext context, List<Player> players) {
    final C = context.appColors;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Für welchen Spieler?',
                      style: TextStyle(
                          color: C.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Pflichtfeld — jeder Held braucht einen Spieler.',
                      style: TextStyle(color: C.textSoft, fontSize: 12)),
                ],
              ),
            ),
            Divider(color: C.border, height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...players.map((p) {
                    final color = _hexColor(p.color);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      title: Text(p.name,
                          style: TextStyle(
                              color: C.text, fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.pop(ctx, p.id),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lendHero(BuildContext context) async {
    final C = context.appColors;
    final all = await _pcRepo.findAll();
    final available = all
        .where((pc) =>
            pc.campaignId == null ||
            pc.campaignId!.isEmpty ||
            pc.campaignId != widget.vm.campaign.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Keine verfügbaren Helden — zuerst im Spieler-Profil anlegen'),
        backgroundColor: C.textMid,
      ));
      return;
    }

    final players = await _playerRepo.findAllSorted();
    if (!mounted) return;
    final playerById = {for (final p in players) p.id: p};

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _LendHeroDialog(
        available: available,
        playerById: playerById,
        campaignTitle: widget.vm.campaign.title,
      ),
    );

    if (selected == null || selected.isEmpty || !mounted) return;

    for (final id in selected) {
      try {
        await _pcRepo.assignToCampaign(id, widget.vm.campaign.id);
      } catch (_) {}
    }

    widget.vm.reloadCharacters();
  }

  Future<void> _removeFromCampaign(BuildContext context, PlayerCharacter pc) async {
    final C = context.appColors;
    try {
      await _pcRepo.removeFromCampaign(pc.id);
      widget.vm.reloadCharacters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${pc.name} aus der Kampagne abgezogen'),
          backgroundColor: C.amber,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: C.red,
        ));
      }
    }
  }

  Future<void> _showHeroContextMenu(
      BuildContext context, PlayerCharacter pc, Offset globalPosition) async {
    final C = context.appColors;
    final result = await showMenu<String>(
      context: context,
      color: C.bgPanel,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.link_off, color: C.amber, size: 18),
              const SizedBox(width: 8),
              Text('Aus Kampagne abziehen', style: TextStyle(color: C.amber)),
            ],
          ),
        ),
      ],
    );
    if (result == 'remove' && mounted) {
      await _removeFromCampaign(context, pc);
    }
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF6B6B66);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final characters = widget.vm.characters;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Text(
                '${characters.length} Held${characters.length != 1 ? "en" : ""}',
                style: TextStyle(fontSize: 11, color: C.textSoft),
              ),
              const Spacer(),
              // Held ausleihen
              _AddHeldChip(
                label: 'Ausleihen',
                icon: Icons.link,
                color: C.accent,
                onTap: () => _lendHero(context),
                C: C,
              ),
              const SizedBox(width: 6),
              // Neuer Held (mit Spieler-Auswahl)
              _AddHeldChip(
                label: 'Neu',
                icon: Icons.add,
                color: C.green,
                onTap: () => _createNewHero(context),
                C: C,
              ),
            ],
          ),
        ),
        Expanded(
          child: characters.isEmpty
              ? Center(
                  child: Text(
                    'Noch keine Helden',
                    style: TextStyle(fontSize: 13, color: C.textSoft),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  itemCount: characters.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onSecondaryTapUp: (details) => _showHeroContextMenu(
                          context, characters[i], details.globalPosition),
                      child: _HeldCard(
                        character: characters[i],
                        selected:
                            widget.vm.selectedCharacter?.id == characters[i].id,
                        onTap: () => widget.vm.selectCharacter(characters[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HeldCard extends StatefulWidget {
  const _HeldCard({required this.character, required this.onTap, this.selected = false});

  final PlayerCharacter character;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_HeldCard> createState() => _HeldCardState();
}

class _HeldCardState extends State<_HeldCard> {
  bool _hovered = false;

  Color _classColor(AppColorsExtension C) {
    final lower = widget.character.className.toLowerCase();
    if (lower.contains('barbar') || lower.contains('krieger') || lower.contains('fighter')) return C.red;
    if (lower.contains('magier') || lower.contains('wizard') || lower.contains('warlock') || lower.contains('sorcerer') || lower.contains('hexenmeister')) return C.accent;
    if (lower.contains('kleriker') || lower.contains('cleric') || lower.contains('paladin')) return C.amber;
    if (lower.contains('schurke') || lower.contains('rogue') || lower.contains('bard') || lower.contains('barde')) return C.amber;
    if (lower.contains('ranger') || lower.contains('waldläufer') || lower.contains('druide') || lower.contains('druid') || lower.contains('monk')) return C.green;
    return C.textMid;
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final color = _classColor(C);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? C.accent.withValues(alpha: 0.08)
                : _hovered
                    ? C.bgHover
                    : C.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected ? C.accent.withValues(alpha: 0.4) : C.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.character.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: C.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.character.className} · Lvl ${widget.character.level}',
                      style: TextStyle(fontSize: 11, color: C.textSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatPill('RK ${widget.character.armorClass}', C.accent, C),
              const SizedBox(width: 4),
              _StatPill('${widget.character.maxHp} HP', C.green, C),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddHeldChip extends StatefulWidget {
  const _AddHeldChip({
    required this.onTap,
    required this.C,
    required this.label,
    required this.icon,
    required this.color,
  });

  final VoidCallback onTap;
  final AppColorsExtension C;
  final String label;
  final IconData icon;
  final Color color;

  @override
  State<_AddHeldChip> createState() => _AddHeldChipState();
}

class _AddHeldChipState extends State<_AddHeldChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.5)
                  : widget.C.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12,
                  color: _hovered ? color : widget.C.textSoft),
              const SizedBox(width: 4),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 10,
                      color: _hovered ? color : widget.C.textSoft,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.label, this.color, this.C);

  final String label;
  final Color color;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500),
        ),
      );
}

// ── VERLAUF TAB ───────────────────────────────────────────────────────────────

class _VerlaufTab extends StatelessWidget {
  const _VerlaufTab({required this.vm});

  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final plan = vm.verlaufsplan;
    final isVorbereitung = vm.mode == DmBuchMode.vorbereitung;

    final inPlanOrtIds = plan
        .where((e) => e.type == VerlaufsEintragType.ort && e.refId != null)
        .map((e) => e.refId!)
        .toSet();
    final notInPlan = vm.orte.where((o) => !inPlanOrtIds.contains(o.id)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Text(
                '${plan.length} Eintr${plan.length != 1 ? "äge" : "ag"}',
                style: TextStyle(fontSize: 11, color: C.textSoft),
              ),
              const Spacer(),
              if (isVorbereitung)
                GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _AddVerlaufsEintragDialog(vm: vm),
                  ),
                  child: Text('Hinzufügen', style: TextStyle(fontSize: 11, color: C.accent)),
                ),
            ],
          ),
        ),
        Expanded(
          child: plan.isEmpty && notInPlan.isEmpty
              ? Center(
                  child: Text(
                    'Noch kein Verlaufsplan',
                    style: TextStyle(fontSize: 13, color: C.textSoft),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    if (plan.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                        sliver: SliverReorderableList(
                          itemCount: plan.length,
                          onReorder: isVorbereitung ? vm.reorderVerlaufsplan : (_, __) {},
                          itemBuilder: (ctx, i) => _VerlaufsRow(
                            key: ValueKey(plan[i].id),
                            index: i,
                            eintrag: plan[i],
                            vm: vm,
                            isVorbereitung: isVorbereitung,
                            selected: vm.selectedVerlaufsEintrag?.id == plan[i].id,
                            showConnector: i < plan.length - 1,
                          ),
                        ),
                      ),
                    if (notInPlan.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                          child: Row(
                            children: [
                              Expanded(child: Divider(height: 1, color: C.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Nicht im Plan (${notInPlan.length})',
                                  style: TextStyle(fontSize: 10, color: C.textSoft),
                                ),
                              ),
                              Expanded(child: Divider(height: 1, color: C.border)),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        sliver: SliverList.builder(
                          itemCount: notInPlan.length,
                          itemBuilder: (ctx, i) => _NotInPlanOrtRow(
                            ort: notInPlan[i],
                            vm: vm,
                            C: C,
                            isVorbereitung: isVorbereitung,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _VerlaufsRow extends StatefulWidget {
  const _VerlaufsRow({
    super.key,
    required this.index,
    required this.eintrag,
    required this.vm,
    required this.isVorbereitung,
    this.selected = false,
    this.showConnector = false,
  });

  final int index;
  final VerlaufsEintrag eintrag;
  final DmBuchViewModel vm;
  final bool isVorbereitung;
  final bool selected;
  final bool showConnector;

  @override
  State<_VerlaufsRow> createState() => _VerlaufsRowState();
}

class _VerlaufsRowState extends State<_VerlaufsRow> {
  bool _hovered = false;

  Color _typeColor(AppColorsExtension C) {
    switch (widget.eintrag.type) {
      case VerlaufsEintragType.ort:      return C.accent;
      case VerlaufsEintragType.quest:    return C.amber;
      case VerlaufsEintragType.ereignis: return C.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final e = widget.eintrag;
    final color = _typeColor(C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
      MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.vm.selectVerlaufsEintragOnMap(widget.eintrag),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: widget.selected
                ? C.accent.withValues(alpha: 0.08)
                : e.isDone
                    ? C.bgHover.withValues(alpha: 0.5)
                    : _hovered
                        ? C.bgHover
                        : C.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? C.accent.withValues(alpha: 0.4)
                  : e.isDone
                      ? C.border.withValues(alpha: 0.5)
                      : C.border,
            ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Farb-Streifen
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: e.isDone ? color.withValues(alpha: 0.3) : color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            // Nummer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: e.isDone ? C.textSoft : color,
                ),
              ),
            ),
            // Inhalt
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: e.isDone ? C.textSoft : C.text,
                        decoration: e.isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (e.type == VerlaufsEintragType.ort && e.refId != null)
                      Text(
                        widget.vm.ortPath(e.refId!),
                        style: TextStyle(fontSize: 10, color: C.textSoft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (e.note != null && e.note!.isNotEmpty)
                      Text(
                        e.note!,
                        style: TextStyle(fontSize: 10, color: C.textSoft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        e.type.label,
                        style: TextStyle(fontSize: 10, color: C.textSoft),
                      ),
                    if (e.type == VerlaufsEintragType.ort && e.note != null && e.note!.isNotEmpty)
                      Text(
                        e.note!,
                        style: TextStyle(fontSize: 10, color: C.textSoft.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            // Aktionen
            if (widget.vm.mode == DmBuchMode.live)
              GestureDetector(
                onTap: () => widget.vm.toggleVerlaufsEintrag(e.id),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    e.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: e.isDone ? C.green : C.textSoft,
                  ),
                ),
              ),
            if (widget.isVorbereitung) ...[
              ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle, size: 14, color: C.textSoft),
                ),
              ),
              GestureDetector(
                onTap: () => widget.vm.removeVerlaufsEintrag(e.id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  child: Icon(Icons.close, size: 13, color: C.textSoft),
                ),
              ),
            ],
          ],
          ),
        ),
        ),
      ),
      ),
      // Connector to next step
      if (widget.showConnector)
        _VerlaufsConnector(
          eintrag: e,
          vm: widget.vm,
          editable: widget.isVorbereitung,
          C: C,
        ),
      ],
    );
  }
}

// ── NICHT IM PLAN ─────────────────────────────────────────────────────────────

class _NotInPlanOrtRow extends StatefulWidget {
  const _NotInPlanOrtRow({
    required this.ort,
    required this.vm,
    required this.C,
    required this.isVorbereitung,
  });

  final Ort ort;
  final DmBuchViewModel vm;
  final AppColorsExtension C;
  final bool isVorbereitung;

  @override
  State<_NotInPlanOrtRow> createState() => _NotInPlanOrtRowState();
}

class _NotInPlanOrtRowState extends State<_NotInPlanOrtRow> {
  bool _hovered = false;

  Color _typeColor() {
    final C = widget.C;
    switch (widget.ort.type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    final color = _typeColor();
    final path = widget.vm.ortPath(widget.ort.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.vm.navigateToOrt(widget.ort),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? C.bgHover : C.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ort.name,
                      style: TextStyle(fontSize: 12, color: C.textMid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      path,
                      style: TextStyle(fontSize: 10, color: C.textSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.isVorbereitung)
                GestureDetector(
                  onTap: () => widget.vm.addVerlaufsEintrag(
                    VerlaufsEintrag.create(
                      type: VerlaufsEintragType.ort,
                      refId: widget.ort.id,
                      label: widget.ort.name,
                    ),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
                    child: Icon(Icons.add, size: 14, color: C.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── VERLAUFS CONNECTOR ────────────────────────────────────────────────────────

class _VerlaufsConnector extends StatelessWidget {
  const _VerlaufsConnector({
    required this.eintrag,
    required this.vm,
    required this.editable,
    required this.C,
  });

  final VerlaufsEintrag eintrag;
  final DmBuchViewModel vm;
  final bool editable;
  final AppColorsExtension C;

  void _edit(BuildContext context) {
    final ctrl = TextEditingController(text: eintrag.connectionNote ?? '');
    showDialog<void>(
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
                'Verbindungsnotiz',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
              ),
              const SizedBox(height: 4),
              Text(
                'Was passiert auf dem Weg zum nächsten Schritt?',
                style: TextStyle(fontSize: 11, color: C.textSoft),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: C.text),
                decoration: InputDecoration(
                  hintText: 'z.B. "3-tägiger Marsch durch den Wald…"',
                  hintStyle: TextStyle(color: C.textSoft),
                  filled: true,
                  fillColor: C.bgHover,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.accent)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      await vm.saveConnectionNote(eintrag.id, ctrl.text.trim());
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = eintrag.connectionNote != null && eintrag.connectionNote!.isNotEmpty;

    return GestureDetector(
      onTap: editable ? () => _edit(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const SizedBox(width: 18),
            // Vertical line
            Container(width: 1.5, height: hasNote ? 10 : 8, color: C.border),
            const SizedBox(width: 10),
            if (hasNote)
              Expanded(
                child: Text(
                  eintrag.connectionNote!,
                  style: TextStyle(fontSize: 10, color: C.textSoft, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (editable)
              Text(
                '+ Verbindung hinzufügen',
                style: TextStyle(fontSize: 10, color: C.border),
              ),
            if (hasNote && editable) ...[
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 10, color: C.border),
            ],
            // Vertical line continuation
            const SizedBox(width: 10),
            Container(width: 1.5, height: hasNote ? 10 : 8, color: C.border),
          ],
        ),
      ),
    );
  }
}

// ── ADD VERLAUFS EINTRAG DIALOG ───────────────────────────────────────────────

class _AddVerlaufsEintragDialog extends StatefulWidget {
  const _AddVerlaufsEintragDialog({required this.vm});

  final DmBuchViewModel vm;

  @override
  State<_AddVerlaufsEintragDialog> createState() => _AddVerlaufsEintragDialogState();
}

class _AddVerlaufsEintragDialogState extends State<_AddVerlaufsEintragDialog> {
  VerlaufsEintragType _type = VerlaufsEintragType.ort;
  String? _selectedRefId;
  final _labelCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final vm = widget.vm;

    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verlaufseintrag', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 14),
              // Typ-Auswahl
              Row(
                children: VerlaufsEintragType.values.map((t) {
                  final active = _type == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = t;
                        _selectedRefId = null;
                        _labelCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: active ? C.accent.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: active ? C.accent.withValues(alpha: 0.4) : C.border,
                          ),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? C.accent : C.textMid,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Referenz-Picker (Ort / Quest) oder Label-Feld (Ereignis)
              if (_type == VerlaufsEintragType.ort)
                _RefPicker<Ort>(
                  items: vm.orte,
                  selectedId: _selectedRefId,
                  labelOf: (o) => o.name,
                  idOf: (o) => o.id,
                  hint: 'Marker auswählen',
                  C: C,
                  onChanged: (o) => setState(() {
                    _selectedRefId = o.id;
                    _labelCtrl.text = o.name;
                  }),
                )
              else if (_type == VerlaufsEintragType.quest)
                _RefPicker<Quest>(
                  items: vm.quests,
                  selectedId: _selectedRefId,
                  labelOf: (q) => q.title,
                  idOf: (q) => q.id.toString(),
                  hint: 'Quest auswählen',
                  C: C,
                  onChanged: (q) => setState(() {
                    _selectedRefId = q.id.toString();
                    _labelCtrl.text = q.title;
                  }),
                )
              else
                _inputField(C, _labelCtrl, 'Beschreibung des Ereignisses', autofocus: true),
              const SizedBox(height: 10),
              _inputField(C, _noteCtrl, 'Notiz (optional)'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canSave ? () => _save(context) : null,
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Hinzufügen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave {
    if (_type == VerlaufsEintragType.ereignis) return _labelCtrl.text.trim().isNotEmpty;
    return _selectedRefId != null;
  }

  void _save(BuildContext context) {
    final eintrag = VerlaufsEintrag.create(
      type: _type,
      refId: _selectedRefId,
      label: _labelCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    widget.vm.addVerlaufsEintrag(eintrag);
    Navigator.of(context).pop();
  }

  Widget _inputField(AppColorsExtension C, TextEditingController ctrl, String hint, {bool autofocus = false}) =>
      TextField(
        controller: ctrl,
        autofocus: autofocus,
        style: TextStyle(fontSize: 13, color: C.text),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: C.textSoft),
          filled: true,
          fillColor: C.bgHover,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.accent)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class _RefPicker<T> extends StatelessWidget {
  const _RefPicker({
    required this.items,
    required this.selectedId,
    required this.labelOf,
    required this.idOf,
    required this.hint,
    required this.C,
    required this.onChanged,
  });

  final List<T> items;
  final String? selectedId;
  final String Function(T) labelOf;
  final String Function(T) idOf;
  final String hint;
  final AppColorsExtension C;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = items.where((i) => idOf(i) == selectedId).firstOrNull;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected != null ? labelOf(selected) : hint,
                style: TextStyle(fontSize: 13, color: selected != null ? C.text : C.textSoft),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.unfold_more, size: 14, color: C.textSoft),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: C.border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340, maxHeight: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hint, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final isSelected = idOf(item) == selectedId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedColor: C.accent,
                        title: Text(labelOf(item), style: TextStyle(fontSize: 13, color: C.text)),
                        onTap: () {
                          onChanged(item);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── LORE KEEPER BTN ──────────────────────────────────────────────────────────

class _LoreKeeperBtn extends StatefulWidget {
  const _LoreKeeperBtn({required this.onTap, required this.C});
  final VoidCallback onTap;
  final AppColorsExtension C;

  @override
  State<_LoreKeeperBtn> createState() => _LoreKeeperBtnState();
}

class _LoreKeeperBtnState extends State<_LoreKeeperBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _hovered ? widget.C.accent.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _hovered ? widget.C.accent.withValues(alpha: 0.4) : widget.C.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 11, color: widget.C.accent),
                const SizedBox(width: 4),
                Text('LoreKeeper', style: TextStyle(fontSize: 11, color: widget.C.accent)),
              ],
            ),
          ),
        ),
      );
}

// ── VERLAUFS GRAPH VIEW ───────────────────────────────────────────────────────

class _VerlaufsGraphView extends StatefulWidget {
  const _VerlaufsGraphView({required this.vm});

  final DmBuchViewModel vm;

  @override
  State<_VerlaufsGraphView> createState() => _VerlaufsGraphViewState();
}

class _VerlaufsGraphViewState extends State<_VerlaufsGraphView> {
  static const double _cW = 4000;
  static const double _cH = 2500;
  static const double _nodeW = 130;
  static const double _nodeH = 46;

  final TransformationController _tc = TransformationController();
  final Map<String, Offset> _dragPos = {};

  bool _connectMode = false;
  String? _connectSource;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _pickMap(BuildContext ctx) async {
    final ref = await pickResource(ctx);
    if (ref != null && ctx.mounted) {
      await widget.vm.setVerlaufsKarteImage(ref);
    }
  }

  Offset _nodePos(VerlaufsEintrag e, Ort ort) =>
      _dragPos[e.id] ?? Offset(ort.mapX! * _cW, ort.mapY! * _cH);

  void _onPanUpdate(VerlaufsEintrag e, Ort ort, DragUpdateDetails d) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final cur = _nodePos(e, ort);
    setState(() {
      _dragPos[e.id] = Offset(
        (cur.dx + d.delta.dx / scale).clamp(0.0, _cW),
        (cur.dy + d.delta.dy / scale).clamp(0.0, _cH),
      );
    });
  }

  Future<void> _onPanEnd(VerlaufsEintrag e, Ort ort) async {
    final pos = _dragPos.remove(e.id);
    if (pos == null) return;
    setState(() {});
    await widget.vm.updateOrt(ort.copyWith(
      mapX: (pos.dx / _cW).clamp(0.0, 1.0),
      mapY: (pos.dy / _cH).clamp(0.0, 1.0),
    ));
  }

  Future<void> _onNodeTap(VerlaufsEintrag e) async {
    final vm = widget.vm;
    if (_connectMode) {
      if (_connectSource == null) {
        setState(() => _connectSource = e.id);
      } else if (_connectSource == e.id) {
        setState(() => _connectSource = null);
      } else {
        final srcId = _connectSource!;
        setState(() => _connectSource = null);
        final src = vm.verlaufsplan.where((x) => x.id == srcId).firstOrNull;
        if (src != null) {
          if (src.connections.contains(e.id)) {
            await vm.removeVerlaufsConnection(srcId, e.id);
          } else {
            await vm.addVerlaufsConnection(srcId, e.id);
          }
        }
      }
    } else {
      await vm.selectVerlaufsEintragOnMap(e);
    }
  }

  Future<void> _placeAtCenter(VerlaufsEintrag e, Ort ort, Size viewSize) async {
    final inv = Matrix4.inverted(_tc.value);
    final screenCenter = Offset(viewSize.width / 2, viewSize.height / 2);
    final canvas = MatrixUtils.transformPoint(inv, screenCenter);
    await widget.vm.updateOrt(ort.copyWith(
      mapX: (canvas.dx / _cW).clamp(0.0, 1.0),
      mapY: (canvas.dy / _cH).clamp(0.0, 1.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final C = context.appColors;
    final isVorbereitung = vm.mode == DmBuchMode.vorbereitung;

    final ortEintraege = vm.verlaufsplan
        .where((e) => e.type == VerlaufsEintragType.ort && e.refId != null)
        .toList();

    final ortMap = <String, Ort>{};
    for (final e in ortEintraege) {
      final ort = vm.orte.where((o) => o.id == e.refId).firstOrNull;
      if (ort != null) ortMap[e.id] = ort;
    }

    final positioned = ortEintraege.where((e) => ortMap[e.id]?.isOnMap == true).toList();
    final unpositioned = ortEintraege.where((e) => ortMap[e.id]?.isOnMap != true).toList();

    final positions = <String, Offset>{};
    for (final e in positioned) {
      final ort = ortMap[e.id]!;
      positions[e.id] = _dragPos[e.id] ?? Offset(ort.mapX! * _cW, ort.mapY! * _cH);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final viewSize = Size(constraints.maxWidth, constraints.maxHeight);

      return Stack(
        children: [
          InteractiveViewer(
            transformationController: _tc,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.03,
            maxScale: 5.0,
            panEnabled: _dragPos.isEmpty,
            child: SizedBox(
              width: _cW,
              height: _cH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Hintergrund: Karte oder Dot-Grid
                  if (vm.verlaufsKarteImagePath != null &&
                      ResourceService.resolveLocalPath(vm.verlaufsKarteImagePath) != null)
                    Positioned.fill(
                      child: Image.file(
                        File(ResourceService.resolveLocalPath(vm.verlaufsKarteImagePath)!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: C.bgPanel),
                      ),
                    )
                  else
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GraphGridPainter(C),
                      ),
                    ),

                  // Kanten (Pfeile)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _VerlaufsEdgePainter(
                        eintraege: positioned,
                        positions: positions,
                        connectSource: _connectSource,
                        lineColor: C.accent.withValues(alpha: 0.75),
                        sourceColor: C.amber,
                      ),
                      isComplex: true,
                    ),
                  ),

                  // Knoten
                  for (final e in positioned)
                    Builder(builder: (_) {
                      final ort = ortMap[e.id]!;
                      final pos = positions[e.id]!;

                      Widget node = _VerlaufsMapNode(
                        eintrag: e,
                        ort: ort,
                        selected: vm.selectedVerlaufsEintrag?.id == e.id,
                        isConnectSource: _connectSource == e.id,
                        C: C,
                      );

                      node = GestureDetector(
                        onTap: () => _onNodeTap(e),
                        onPanUpdate: (isVorbereitung && !_connectMode)
                            ? (d) => _onPanUpdate(e, ort, d)
                            : null,
                        onPanEnd: (isVorbereitung && !_connectMode)
                            ? (_) => _onPanEnd(e, ort)
                            : null,
                        child: node,
                      );

                      return Positioned(
                        left: pos.dx - _nodeW / 2,
                        top: pos.dy - _nodeH / 2,
                        width: _nodeW,
                        height: _nodeH,
                        child: node,
                      );
                    }),
                ],
              ),
            ),
          ),

          // Toolbar
          Positioned(
            right: 10,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _GraphMapBtn(
                  icon: Icons.map_outlined,
                  label: vm.verlaufsKarteImagePath == null
                      ? 'Karte laden'
                      : 'Karte wechseln',
                  onTap: () => _pickMap(context),
                  C: C,
                ),
                if (vm.verlaufsKarteImagePath != null) ...[
                  const SizedBox(height: 4),
                  _GraphMapBtn(
                    icon: Icons.close,
                    label: 'Karte entfernen',
                    onTap: () => vm.setVerlaufsKarteImage(null),
                    C: C,
                  ),
                ],
                if (isVorbereitung) ...[
                  const SizedBox(height: 8),
                  _GraphMapBtn(
                    icon: _connectMode ? Icons.link_off : Icons.link,
                    label: _connectMode
                        ? 'Verbindungs-Modus beenden'
                        : 'Verbindungen bearbeiten',
                    active: _connectMode,
                    onTap: () => setState(() {
                      _connectMode = !_connectMode;
                      _connectSource = null;
                    }),
                    C: C,
                  ),
                ],
              ],
            ),
          ),

          // Unpositionierte Orte
          if (unpositioned.isNotEmpty)
            Positioned(
              left: 10,
              top: 8,
              child: _UnpositionedPanel(
                eintraege: unpositioned,
                ortMap: ortMap,
                isVorbereitung: isVorbereitung,
                onPlace: isVorbereitung
                    ? (e, ort) => _placeAtCenter(e, ort, viewSize)
                    : null,
                C: C,
              ),
            ),

          // Verbindungs-Modus Hinweis
          if (_connectMode)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: C.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _connectSource == null
                        ? 'Tippe auf einen Ort als Ausgangspunkt'
                        : 'Tippe auf den Ziel-Ort  •  Nochmals tippen zum Abbrechen',
                    style: TextStyle(fontSize: 11, color: C.amber),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ── VERLAUFS EDGE PAINTER ────────────────────────────────────────────────────

class _VerlaufsEdgePainter extends CustomPainter {
  const _VerlaufsEdgePainter({
    required this.eintraege,
    required this.positions,
    required this.connectSource,
    required this.lineColor,
    required this.sourceColor,
  });

  final List<VerlaufsEintrag> eintraege;
  final Map<String, Offset> positions;
  final String? connectSource;
  final Color lineColor;
  final Color sourceColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in eintraege) {
      final from = positions[e.id];
      if (from == null || e.connections.isEmpty) continue;

      final isSource = connectSource == e.id;
      final paint = Paint()
        ..color = isSource ? sourceColor.withValues(alpha: 0.85) : lineColor
        ..strokeWidth = isSource ? 2.5 : 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (final toId in e.connections) {
        final to = positions[toId];
        if (to == null) continue;
        _drawArrow(canvas, from, to, paint);
      }
    }
  }

  static void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dir = to - from;
    if (dir.distance < 2) return;

    const nodeR = 28.0;
    const arrowLen = 13.0;
    const arrowAngle = 0.42;

    final unit = dir / dir.distance;
    final start = from + unit * nodeR;
    final end = to - unit * nodeR;

    if ((end - start).distance < nodeR) return;

    canvas.drawLine(start, end, paint);

    final angle = atan2(dir.dy, dir.dx);
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowLen * cos(angle - arrowAngle),
        end.dy - arrowLen * sin(angle - arrowAngle),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowLen * cos(angle + arrowAngle),
        end.dy - arrowLen * sin(angle + arrowAngle),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VerlaufsEdgePainter old) =>
      old.eintraege != eintraege ||
      old.positions != positions ||
      old.connectSource != connectSource;
}

// ── VERLAUFS MAP NODE ─────────────────────────────────────────────────────────

class _VerlaufsMapNode extends StatefulWidget {
  const _VerlaufsMapNode({
    required this.eintrag,
    required this.ort,
    required this.selected,
    required this.isConnectSource,
    required this.C,
  });

  final VerlaufsEintrag eintrag;
  final Ort ort;
  final bool selected;
  final bool isConnectSource;
  final AppColorsExtension C;

  @override
  State<_VerlaufsMapNode> createState() => _VerlaufsMapNodeState();
}

class _VerlaufsMapNodeState extends State<_VerlaufsMapNode> {
  bool _hovered = false;

  Color _typeColor(AppColorsExtension C) {
    switch (widget.ort.type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    final e = widget.eintrag;
    final accentColor = widget.isConnectSource ? C.amber : _typeColor(C);
    final isActive = widget.selected || widget.isConnectSource;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.14)
              : _hovered
                  ? C.bgHover
                  : C.bgPanel.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isActive ? accentColor : C.border,
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.22 : 0.12),
              blurRadius: isActive ? 12 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: e.isDone
                    ? accentColor.withValues(alpha: 0.4)
                    : accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  bottomLeft: Radius.circular(9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: e.isDone
                          ? C.textSoft
                          : (isActive ? accentColor : C.text),
                      decoration:
                          e.isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.ort.type.label,
                        style: TextStyle(fontSize: 9, color: C.textSoft),
                      ),
                      if (widget.ort.parentOrtId != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.subdirectory_arrow_right, size: 9, color: C.textSoft),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (e.isDone)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, size: 11, color: C.green),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ── UNPOSITIONED PANEL ────────────────────────────────────────────────────────

class _UnpositionedPanel extends StatelessWidget {
  const _UnpositionedPanel({
    required this.eintraege,
    required this.ortMap,
    required this.isVorbereitung,
    required this.onPlace,
    required this.C,
  });

  final List<VerlaufsEintrag> eintraege;
  final Map<String, Ort> ortMap;
  final bool isVorbereitung;
  final Future<void> Function(VerlaufsEintrag, Ort)? onPlace;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190, maxHeight: 260),
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${eintraege.length} Ort${eintraege.length != 1 ? "e" : ""} ohne Position',
            style: TextStyle(fontSize: 10, color: C.textSoft),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: eintraege.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final e = eintraege[i];
                final ort = ortMap[e.id];
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.label,
                        style: TextStyle(fontSize: 11, color: C.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onPlace != null && ort != null)
                      GestureDetector(
                        onTap: () => onPlace!(e, ort),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.add_location_alt_outlined,
                            size: 14,
                            color: C.accent,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── GRAPH GRID PAINTER ────────────────────────────────────────────────────────

class _GraphGridPainter extends CustomPainter {
  const _GraphGridPainter(this.C);

  final AppColorsExtension C;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = C.border.withValues(alpha: 0.35);
    const spacing = 60.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;
    for (int x = 0; x <= cols; x++) {
      for (int y = 0; y <= rows; y++) {
        canvas.drawCircle(Offset(x * spacing, y * spacing), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GraphGridPainter old) => false;
}

// ── GRAPH MAP BUTTON ──────────────────────────────────────────────────────────

class _GraphMapBtn extends StatefulWidget {
  const _GraphMapBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.C,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AppColorsExtension C;
  final bool active;

  @override
  State<_GraphMapBtn> createState() => _GraphMapBtnState();
}

class _GraphMapBtnState extends State<_GraphMapBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? C.amber.withValues(alpha: 0.15)
                : (_hovered && widget.onTap != null)
                    ? C.bgHover
                    : C.bgPanel.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: widget.active
                  ? C.amber.withValues(alpha: 0.5)
                  : C.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.active ? C.amber : C.textMid,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.active ? C.amber : C.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SHARED ICON BTN ───────────────────────────────────────────────────────────

class _TopBarIconBtn extends StatefulWidget {
  const _TopBarIconBtn({
    this.icon,
    this.iconData,
    this.iconColor,
    required this.C,
    required this.onTap,
    this.tooltip,
  }) : assert(icon != null || iconData != null, 'Provide icon or iconData');

  final AppIconName? icon;
  final IconData? iconData;
  final Color? iconColor;
  final AppColorsExtension C;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_TopBarIconBtn> createState() => _TopBarIconBtnState();
}

class _TopBarIconBtnState extends State<_TopBarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget btn = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
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
            child: widget.iconData != null
                ? Icon(widget.iconData!, size: 14, color: widget.iconColor ?? widget.C.textMid)
                : AppIcon(widget.icon!, size: 14, color: widget.C.textMid),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) btn = Tooltip(message: widget.tooltip!, child: btn);
    return btn;
  }
}

// ── LEND HERO DIALOG (DM-Buch) ────────────────────────────────────────────────

class _LendHeroDialog extends StatefulWidget {
  const _LendHeroDialog({
    required this.available,
    required this.playerById,
    required this.campaignTitle,
  });
  final List<PlayerCharacter> available;
  final Map<String, Player> playerById;
  final String campaignTitle;

  @override
  State<_LendHeroDialog> createState() => _LendHeroDialogState();
}

class _LendHeroDialogState extends State<_LendHeroDialog> {
  final Set<String> _selected = {};

  Color _hexColor(String hex) {
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
    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Held ausleihen',
                      style: TextStyle(
                          color: C.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Für: ${widget.campaignTitle}',
                      style: TextStyle(color: C.textSoft, fontSize: 12)),
                ],
              ),
            ),
            Divider(color: C.border, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.available.length,
                itemBuilder: (ctx, i) {
                  final pc = widget.available[i];
                  final isSelected = _selected.contains(pc.id);
                  final player = pc.playerId != null
                      ? widget.playerById[pc.playerId]
                      : null;
                  final playerColor = player != null
                      ? _hexColor(player.color)
                      : const Color(0xFF6B6B66);
                  final ownerName = player?.name ??
                      (pc.playerName.isNotEmpty ? pc.playerName : null);
                  final hasCampaign =
                      pc.campaignId != null && pc.campaignId!.isNotEmpty;

                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: C.accent,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(pc.id);
                      } else {
                        _selected.remove(pc.id);
                      }
                    }),
                    secondary: CircleAvatar(
                      backgroundColor: playerColor.withValues(alpha: 0.15),
                      radius: 18,
                      child: Text(
                        pc.name.isNotEmpty ? pc.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: playerColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    title: Text(pc.name,
                        style: TextStyle(
                            color: C.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    subtitle: Text(
                      [
                        'Lvl ${pc.level} ${pc.className}',
                        if (ownerName != null) ownerName,
                        if (hasCampaign) 'aktuell anderswo',
                      ].join(' · '),
                      style: TextStyle(color: C.textSoft, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            Divider(color: C.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_selected.isEmpty
                        ? 'Auswählen'
                        : '${_selected.length} hinzufügen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KARTE GRAPH VIEW ─────────────────────────────────────────────────────────

class _KarteGraphView extends StatefulWidget {
  const _KarteGraphView({required this.vm});

  final DmBuchViewModel vm;

  @override
  State<_KarteGraphView> createState() => _KarteGraphViewState();
}

class _KarteGraphViewState extends State<_KarteGraphView>
    with TickerProviderStateMixin {
  // Canvas = Viewport-Größe (wird in LayoutBuilder gesetzt)
  double _cW = 800;
  double _cH = 600;
  static const double _nodeW = 110;
  static const double _nodeH = 28;
  static const double _detailPanelW = 341.0;

  final TransformationController _tc    = TransformationController();
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _dragPos = {};

  bool _connectMode = false;
  String? _connectSource;
  bool _scenePlaceMode = false;
  bool _showLayerPanel = false;

  // Local copy of the last synced layers list — needed because old.vm and
  // widget.vm point to the same ViewModel object in didUpdateWidget, so
  // direct comparison of old.vm.currentLevelLayers always returns equal.
  List<MapLayer> _syncedLayers = const [];

  String? _lastSelectedOrtId;
  BoxConstraints? _constraints;
  late final AnimationController _flyAnim;
  late Animation<Offset> _flyAnimation;
  double _flyScale = 1.0;

  int _lastMapDepth = 1;
  double _pinScale = 1.0;
  String _lastTokenSig = '';

  @override
  void initState() {
    super.initState();
    _lastMapDepth = widget.vm.mapStackDepth;
    _initPositions(widget.vm.currentLevelOrte);
    _flyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onFlyTick);
    _tc.addListener(_onGraphTcChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lanVm = context.read<LanMapViewModel>();
      final path = widget.vm.currentMapImagePath;
      if (path != null) lanVm.setImage(path);
      _syncTokenOrte(lanVm);
      _syncLayers(lanVm);
    });
  }

  void _syncLayers(LanMapViewModel lanVm) {
    final layers = widget.vm.currentLevelLayers;
    _syncedLayers = layers;
    lanVm.setLayers(layers);
    _precacheLayers(layers);
  }

  void _precacheLayers(List<MapLayer> layers) {
    for (final layer in layers) {
      final resolved = ResourceService.resolveLocalPath(layer.imagePath);
      if (resolved == null) continue;
      precacheImage(FileImage(File(resolved)), context);
    }
  }

  // Triggers rebuild of viewport rect when DM pans/zooms the graph view
  void _onGraphTcChange() {
    if (!mounted) return;
    if (context.read<LanMapViewModel>().viewportNorm != null) setState(() {});
  }

  String _tokenSig(List<Ort> orte) => orte
      .where((o) => o.type == OrtType.token && o.mapX != null && o.mapY != null)
      .map((o) => '${o.id}:${o.mapX}:${o.mapY}:${o.name}')
      .join('|');

  void _syncTokenOrte(LanMapViewModel lanVm) {
    final tokenOrte = widget.vm.currentLevelOrte
        .where((o) => o.type == OrtType.token)
        .toList();
    final sig = _tokenSig(tokenOrte);
    if (sig == _lastTokenSig) return;
    _lastTokenSig = sig;
    // Defer so notifyListeners() doesn't fire during a build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) lanVm.syncOrtTokens(tokenOrte);
    });
  }

  @override
  void didUpdateWidget(_KarteGraphView old) {
    super.didUpdateWidget(old);

    if (old.vm.currentMapImagePath != widget.vm.currentMapImagePath) {
      final path = widget.vm.currentMapImagePath;
      if (path != null) context.read<LanMapViewModel>().setImage(path);
    }

    // Compare against local _syncedLayers because old.vm == widget.vm (same object).
    if (!identical(_syncedLayers, widget.vm.currentLevelLayers)) {
      _syncLayers(context.read<LanMapViewModel>());
    }

    // Wenn die Kartenebene gewechselt hat, Positionen neu initialisieren
    if (widget.vm.mapStackDepth != _lastMapDepth) {
      _lastMapDepth = widget.vm.mapStackDepth;
      _lastSelectedOrtId = null;
      _lastTokenSig = '';
      _dragPos.clear();
      _initPositions(widget.vm.currentLevelOrte);
      final lanVm = context.read<LanMapViewModel>();
      _syncTokenOrte(lanVm);
      _syncLayers(lanVm);
      return;
    }

    final orte = widget.vm.currentLevelOrte;
    final n = orte.length;
    for (int i = 0; i < n; i++) {
      final ort = orte[i];
      if (_dragPos.containsKey(ort.id)) continue;
      if (ort.mapX != null && ort.mapY != null) {
        _positions[ort.id] = Offset(ort.mapX!, ort.mapY!);
      } else if (!_positions.containsKey(ort.id)) {
        _positions[ort.id] = _autoPos(i, n);
      }
    }
    _positions.removeWhere((id, _) => !orte.any((o) => o.id == id));

    final sel = widget.vm.selectedOrt;
    if (sel != null && sel.id != _lastSelectedOrtId) {
      _lastSelectedOrtId = sel.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flyTo(sel);
      });
    } else if (sel == null) {
      _lastSelectedOrtId = null;
    }

    _syncTokenOrte(context.read<LanMapViewModel>());
  }

  void _initPositions(List<Ort> orte) {
    _positions.clear();
    for (int i = 0; i < orte.length; i++) {
      final ort = orte[i];
      if (ort.mapX != null && ort.mapY != null) {
        _positions[ort.id] = Offset(ort.mapX!, ort.mapY!);
      } else {
        _positions[ort.id] = _autoPos(i, orte.length);
      }
    }
  }

  // _positions stores fractions [0,1] relative to canvas (= viewport)
  Offset _autoPos(int i, int n) {
    if (n <= 1) return const Offset(0.5, 0.5);
    const radiusX = 0.28;
    const radiusY = 0.28;
    final angle = (2 * pi * i) / n - pi / 2;
    return Offset(
      (0.5 + radiusX * cos(angle)).clamp(0.0, 1.0),
      (0.5 + radiusY * sin(angle)).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _flyAnim.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _onFlyTick() {
    final t = _flyAnimation.value;
    final m = Matrix4.identity()
      ..translate(t.dx, t.dy)
      ..scale(_flyScale, _flyScale, 1.0);
    _tc.value = m;
  }

  void _flyTo(Ort ort) {
    final constraints = _constraints;
    if (constraints == null) return;
    final frac = _positions[ort.id];
    if (frac == null) return;

    final vpW = constraints.maxWidth;
    final vpH = constraints.maxHeight;
    // Convert fraction to canvas pixel
    final canvasX = frac.dx * _cW;
    final canvasY = frac.dy * _cH;
    _flyScale = _tc.value.getMaxScaleOnAxis();
    final from = MatrixUtils.transformPoint(_tc.value, Offset.zero);
    // Center in the visible area left of the detail panel overlay.
    final visibleCenterX = (vpW - _detailPanelW) / 2;
    final to = Offset(visibleCenterX - canvasX * _flyScale, vpH / 2 - canvasY * _flyScale);

    _flyAnimation = Tween<Offset>(begin: from, end: to).animate(
      CurvedAnimation(parent: _flyAnim, curve: Curves.easeInOut),
    );
    _flyAnim.forward(from: 0);
  }

  Future<void> _pickMap(BuildContext ctx) async {
    final ref = await pickResource(ctx);
    if (ref != null && ctx.mounted) {
      await widget.vm.setCurrentLevelMapImage(ref);
    }
  }

  // Returns fraction [0,1]
  Offset _nodePos(Ort ort) =>
      _dragPos[ort.id] ?? _positions[ort.id] ?? const Offset(0.5, 0.5);

  void _onPanUpdate(Ort ort, DragUpdateDetails d) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final cur = _nodePos(ort);
    final next = Offset(
      (cur.dx + d.delta.dx / scale / _cW).clamp(0.0, 1.0),
      (cur.dy + d.delta.dy / scale / _cH).clamp(0.0, 1.0),
    );
    setState(() {
      _dragPos[ort.id] = next;
      _positions[ort.id] = next;
    });
  }

  Future<void> _onPanEnd(Ort ort) async {
    final pos = _dragPos.remove(ort.id);
    if (pos == null) return;
    setState(() {});
    // pos is already a fraction [0,1]
    await widget.vm.updateOrt(ort.copyWith(mapX: pos.dx, mapY: pos.dy));
  }

  Future<void> _onCanvasDoubleTap(BuildContext ctx, Offset localPos) async {
    final vm = widget.vm;
    final inv = Matrix4.inverted(_tc.value);
    final canvas = MatrixUtils.transformPoint(inv, localPos);
    final fracX = (canvas.dx / _cW).clamp(0.0, 1.0);
    final fracY = (canvas.dy / _cH).clamp(0.0, 1.0);

    if (vm.currentMapParentId != null) {
      // Auf Subkarte: neuen Ort direkt erstellen
      final ort = await showDialog<Ort>(
        context: ctx,
        builder: (_) => _CreateOrtDialog(vm: vm),
      );
      if (ort == null || !ctx.mounted) return;
      setState(() => _positions[ort.id] = Offset(fracX, fracY));
      await vm.updateOrt(ort.copyWith(mapX: fracX, mapY: fracY));
    } else {
      // Auf Weltkarte: vorhandenen Ort platzieren
      final ort = await showDialog<Ort>(
        context: ctx,
        builder: (_) => _KarteOrtPickerDialog(orte: vm.currentLevelOrte),
      );
      if (ort == null || !ctx.mounted) return;
      setState(() => _positions[ort.id] = Offset(fracX, fracY));
      await vm.updateOrt(ort.copyWith(mapX: fracX, mapY: fracY));
    }
  }

  Future<void> _onCanvasScenePlaceTap(BuildContext ctx, Offset localPos) async {
    final vm = widget.vm;
    final inv = Matrix4.inverted(_tc.value);
    final canvas = MatrixUtils.transformPoint(inv, localPos);
    final fracX = (canvas.dx / _cW).clamp(0.0, 1.0);
    final fracY = (canvas.dy / _cH).clamp(0.0, 1.0);

    final result = await showDialog<({String name, SceneType type})>(
      context: ctx,
      builder: (_) => const _PlaceSceneDialog(),
    );
    if (result == null || !ctx.mounted) return;

    final created = await vm.createSceneAndOrtAt(
      fracX: fracX,
      fracY: fracY,
      name: result.name,
      sceneType: result.type,
    );
    if (created != null) {
      setState(() => _positions[created.ort.id] = Offset(fracX, fracY));
    }
  }

  // ── Camera view ─────────────────────────────────────────────────────────

  // Returns the Rect where the image is displayed when using BoxFit.contain.
  static Rect _camContainRect(Size imageSize, Size canvas) {
    final imgAr = imageSize.width / imageSize.height;
    final canAr = canvas.width  / canvas.height;
    final double w, h;
    if (imgAr > canAr) {
      w = canvas.width;
      h = canvas.width / imgAr;
    } else {
      h = canvas.height;
      w = canvas.height * imgAr;
    }
    return Rect.fromLTWH(
      (canvas.width  - w) / 2,
      (canvas.height - h) / 2,
      w, h,
    );
  }

  Widget _buildServerChip(BuildContext context, LanMapViewModel lanVm, AppColorsExtension C) {
    if (!lanVm.isRunning) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _QrDialog(
          lanUrl:   lanVm.lanUrl,
          localUrl: lanVm.localhostUrl,
          emuUrl:   lanVm.emulatorUrl,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_tethering, size: 13, color: C.green),
            const SizedBox(width: 6),
            Text(
              lanVm.serverUrl,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white),
            ),
            const SizedBox(width: 8),
            Icon(Icons.people_outline, size: 13, color: C.textSoft),
            const SizedBox(width: 3),
            Text('${lanVm.clientCount}', style: TextStyle(fontSize: 11, color: C.textSoft)),
            const SizedBox(width: 8),
            Icon(Icons.qr_code, size: 13, color: C.textMid),
          ],
        ),
      ),
    );
  }

  Future<void> _onNodeTap(Ort ort) async {
    final vm = widget.vm;
    if (_scenePlaceMode) {
      // Szene zu bestehendem Ort hinzufügen
      final result = await showDialog<({String name, SceneType type})>(
        context: context,
        builder: (_) => const _PlaceSceneDialog(),
      );
      if (result == null || !mounted) return;
      await vm.createSceneForOrt(ort: ort, name: result.name, type: result.type);
      return;
    }
    if (_connectMode) {
      if (_connectSource == null) {
        setState(() => _connectSource = ort.id);
      } else if (_connectSource == ort.id) {
        setState(() => _connectSource = null);
      } else {
        final srcId = _connectSource!;
        setState(() => _connectSource = null);
        final src = vm.orte.where((o) => o.id == srcId).firstOrNull;
        if (src != null) {
          if (src.connectedOrtIds.contains(ort.id)) {
            await vm.disconnectOrte(src, ort);
          } else {
            await vm.connectOrte(src, ort);
          }
        }
      }
    } else {
      await vm.selectOrt(ort);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm    = widget.vm;
    final lanVm = context.watch<LanMapViewModel>();
    final C = context.appColors;
    final isVorbereitung = vm.mode == DmBuchMode.vorbereitung;
    final orte = vm.currentLevelOrte;
    final onSubMap = vm.currentMapParentId != null;

    return LayoutBuilder(builder: (context, constraints) {
      _constraints = constraints;
      _cW = constraints.maxWidth;
      _cH = constraints.maxHeight;


      // Bruchteile → Canvas-Pixel für Anzeige
      final positions = <String, Offset>{
        for (final ort in orte) ort.id: (() {
          final frac = _dragPos[ort.id] ?? _positions[ort.id] ?? const Offset(0.5, 0.5);
          return Offset(frac.dx * _cW, frac.dy * _cH);
        })(),
      };

      return Stack(
        children: [
          // Gesamter Canvas (Hintergrund + Kanten + Pins) im InteractiveViewer
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTapDown: (isVorbereitung && !_connectMode && !_scenePlaceMode)
                ? (d) => _onCanvasDoubleTap(context, d.localPosition)
                : null,
            onTapDown: _scenePlaceMode
                ? (d) => _onCanvasScenePlaceTap(context, d.localPosition)
                : null,
            child: InteractiveViewer(
              transformationController: _tc,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 8.0,
              child: SizedBox(
                width: _cW,
                height: _cH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Hintergrund (Karte + Layer oder Dot-Grid)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ResourceService.resolveLocalPath(vm.currentMapImagePath) != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(ResourceService.resolveLocalPath(vm.currentMapImagePath)!),
                                    fit: BoxFit.contain,
                                    frameBuilder: (ctx, child, frame, sync) =>
                                        (sync || frame != null) ? child : CustomPaint(painter: _GraphGridPainter(C)),
                                    errorBuilder: (_, __, ___) => ColoredBox(color: C.bgPanel),
                                  ),
                                  for (final layer in vm.currentLevelLayers)
                                    if (layer.isVisible && ResourceService.resolveLocalPath(layer.imagePath) != null)
                                      Image.file(
                                        File(ResourceService.resolveLocalPath(layer.imagePath)!),
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                ],
                              )
                            : CustomPaint(painter: _GraphGridPainter(C)),
                      ),
                    ),

                    // Kanten
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _KarteEdgePainter(
                            orte: orte,
                            positions: positions,
                            connectSource: _connectSource,
                            lineColor: C.accent.withValues(alpha: 0.75),
                            sourceColor: C.amber,
                          ),
                          isComplex: true,
                        ),
                      ),
                    ),

                    // Pins — im selben Koordinatensystem wie der Canvas
                    for (final ort in orte.where((o) => o.type != OrtType.token))
                      Positioned(
                        left: positions[ort.id]!.dx - _nodeW * _pinScale / 2,
                        top: positions[ort.id]!.dy - _nodeH * _pinScale / 2,
                        width: _nodeW * _pinScale,
                        height: _nodeH * _pinScale,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onNodeTap(ort),
                          onPanUpdate: (isVorbereitung && !_connectMode && !ort.mapPositionLocked)
                              ? (d) => _onPanUpdate(ort, d)
                              : null,
                          onPanEnd: (isVorbereitung && !_connectMode && !ort.mapPositionLocked)
                              ? (_) => _onPanEnd(ort)
                              : null,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                              width: _nodeW,
                              height: _nodeH,
                              child: _KarteMapNode(
                                ort: ort,
                                selected: vm.selectedOrt?.id == ort.id,
                                isConnectSource: _connectSource == ort.id,
                                hasChildren: vm.hasChildren(ort.id),
                                sceneCount: vm.ortSceneCount(ort.id),
                                C: C,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Token-Ort-Pins — kleiner Kreis-Marker, direkt auf der Karte
                    for (final ort in orte.where((o) => o.type == OrtType.token && positions.containsKey(o.id)))
                      ...() {
                        const tokenColor = Color(0xFF9b59b6);
                        const pinD = 22.0;
                        final scaled = pinD * _pinScale;
                        final isSelected = vm.selectedOrt?.id == ort.id;
                        final label = ort.name.length > 2
                            ? ort.name.substring(0, 2).toUpperCase()
                            : ort.name.toUpperCase();
                        final cx = positions[ort.id]!.dx;
                        final cy = positions[ort.id]!.dy;
                        return [
                          // Circle pin
                          Positioned(
                            left: cx - scaled / 2,
                            top:  cy - scaled / 2,
                            width: scaled,
                            height: scaled,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onNodeTap(ort),
                              onPanUpdate: (isVorbereitung && !_connectMode && !ort.mapPositionLocked)
                                  ? (d) => _onPanUpdate(ort, d)
                                  : null,
                              onPanEnd: (isVorbereitung && !_connectMode && !ort.mapPositionLocked)
                                  ? (_) => _onPanEnd(ort)
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                  color: ort.tokenImagePath != null
                                      ? Colors.transparent
                                      : tokenColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                    if (isSelected)
                                      BoxShadow(
                                        color: tokenColor.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                  ],
                                ),
                                child: ResourceService.resolveLocalPath(ort.tokenImagePath) != null
                                    ? ClipOval(
                                        child: Image.file(
                                          File(ResourceService.resolveLocalPath(ort.tokenImagePath)!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => ColoredBox(
                                            color: tokenColor,
                                            child: Center(child: Text(label,
                                              style: TextStyle(color: Colors.white, fontSize: 8 * _pinScale, fontWeight: FontWeight.w700, height: 1.0))),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(label,
                                          style: TextStyle(color: Colors.white, fontSize: 8 * _pinScale, fontWeight: FontWeight.w700, height: 1.0)),
                                      ),
                              ),
                            ),
                          ),
                          // Size slider — appears below the circle when selected
                          if (isSelected)
                            Positioned(
                              left: cx - 50 * _pinScale,
                              top:  cy + scaled / 2 + 4,
                              width:  100 * _pinScale,
                              height:  28 * _pinScale,
                              child: _TokenSizeSlider(
                                key: ValueKey(ort.id),
                                initialSize: lanVm.tokenOrtSize(ort.id),
                                onSizeChanged: (v) => lanVm.setTokenOrtSize(ort.id, v),
                              ),
                            ),
                        ];
                      }(),
                  ],
                ),
              ),
            ),
          ),

          // Tokens aus dem LAN-Server — über den Pins, im Bildschirmkoordinatenraum
          // ort_-prefixed tokens are rendered as map pins above; skip them here.
          ...() {
            final imgSize = lanVm.imageNaturalSize;
            final tokens  = lanVm.tokens.where((t) => !t.id.startsWith('ort_')).toList();
            if (imgSize == null || tokens.isEmpty) return <Widget>[];
            final canvasSize = Size(_cW, _cH);
            final imgRect = _camContainRect(imgSize, canvasSize);
            const cols = 20, rows = 20;
            final cw = imgRect.width  / cols;
            final ch = imgRect.height / rows;
            // Convert from content coords → screen coords via the TC matrix
            return tokens.map((t) {
              final contentPt = Offset(imgRect.left + t.x * cw + cw / 2, imgRect.top + t.y * ch + ch / 2);
              final screenPt  = MatrixUtils.transformPoint(_tc.value, contentPt);
              final size = cw * _pinScale * 0.7;
              return Positioned(
                left: screenPt.dx - size / 2,
                top:  screenPt.dy - size / 2,
                width: size, height: size,
                child: IgnorePointer(child: _CamTokenDot(token: t, size: size)),
              );
            }).toList();
          }(),

          // Viewport-Rechteck — zeigt Spieler-Sichtfeld auf der Karte
          if (lanVm.viewportNorm != null && lanVm.imageNaturalSize != null &&
              vm.currentMapImagePath != null)
            () {
              final imgSize    = lanVm.imageNaturalSize!;
              final norm       = lanVm.viewportNorm!;
              final canvasSize = Size(_cW, _cH);
              final imgRect    = _camContainRect(imgSize, canvasSize);

              // Größe des Spieler-Sichtfelds in Content-Pixeln
              // Nutzt die echte Browser-Canvas-Größe (per WS gemeldet, Default 1280×720)
              final playerSize = lanVm.playerCanvasSize;
              final s  = lanVm.broadcastScale;
              final rW = (playerSize.width  / s) * (imgRect.width  / imgSize.width);
              final rH = (playerSize.height / s) * (imgRect.height / imgSize.height);

              final contentCenter = Offset(
                imgRect.left + norm.dx * imgRect.width,
                imgRect.top  + norm.dy * imgRect.height,
              );
              final contentRect = Rect.fromCenter(
                center: contentCenter, width: rW, height: rH,
              );

              // Content → Screen-Koordinaten via TC-Matrix
              final tl  = MatrixUtils.transformPoint(_tc.value, contentRect.topLeft);
              final br  = MatrixUtils.transformPoint(_tc.value, contentRect.bottomRight);
              final scr = Rect.fromPoints(tl, br);
              final tcS = _tc.value.getMaxScaleOnAxis();

              return Positioned(
                left:   scr.left,
                top:    scr.top,
                width:  scr.width.abs(),
                height: scr.height.abs(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: lanVm.paintMode == 'viewport' ? (d) {
                    final newNorm = Offset(
                      (norm.dx + d.delta.dx / (tcS * imgRect.width)).clamp(0.0, 1.0),
                      (norm.dy + d.delta.dy / (tcS * imgRect.height)).clamp(0.0, 1.0),
                    );
                    lanVm.moveViewportTo(newNorm);
                  } : null,
                  onSecondaryTapUp: (d) {
                    final pos = d.globalPosition;
                    showMenu<int>(
                      context: context,
                      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
                      items: [
                        PopupMenuItem<int>(
                          value: 1,
                          child: Row(
                            children: [
                              const Icon(Icons.zoom_in, size: 14),
                              const SizedBox(width: 8),
                              Text('Zoom +  →  ${(lanVm.broadcastScale + 0.5).toStringAsFixed(1)}×'),
                            ],
                          ),
                        ),
                        PopupMenuItem<int>(
                          value: 2,
                          enabled: lanVm.broadcastScale > 0.5,
                          child: Row(
                            children: [
                              const Icon(Icons.zoom_out, size: 14),
                              const SizedBox(width: 8),
                              Text('Zoom −  →  ${(lanVm.broadcastScale - 0.5).clamp(0.5, 10.0).toStringAsFixed(1)}×'),
                            ],
                          ),
                        ),
                      ],
                    ).then((value) {
                      if (value == 1) lanVm.setBroadcastScale(lanVm.broadcastScale + 0.5);
                      if (value == 2) lanVm.setBroadcastScale(lanVm.broadcastScale - 0.5);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: lanVm.paintMode == 'viewport'
                            ? Colors.blueAccent
                            : Colors.blueAccent.withValues(alpha: 0.6),
                        width: lanVm.paintMode == 'viewport' ? 2.5 : 1.5,
                      ),
                      color: Colors.blueAccent.withValues(
                        alpha: lanVm.paintMode == 'viewport' ? 0.12 : 0.05,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Spieler',
                              style: TextStyle(fontSize: 9, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }(),

          // Server-Chip (oben mittig)
          Positioned(
            top: 8, left: 0, right: 0,
            child: Center(child: _buildServerChip(context, lanVm, C)),
          ),

          // UI-Overlays (Bildschirmkoordinaten, außerhalb des Viewers)
          if (onSubMap)
            Positioned(
              left: 10,
              top: 8,
              child: _MapBreadcrumb(vm: vm, C: C),
            ),

          if (isVorbereitung && !_connectMode)
            Positioned(
              right: 12,
              bottom: 10,
              child: Text(
                'Doppelklick → Ort platzieren',
                style: TextStyle(fontSize: 10, color: C.textSoft.withValues(alpha: 0.5)),
              ),
            ),

          Positioned(
            right: 10,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _GraphMapBtn(
                  icon: Icons.map_outlined,
                  label: vm.currentMapImagePath == null ? 'Karte laden' : 'Karte wechseln',
                  onTap: () => _pickMap(context),
                  C: C,
                ),
                if (vm.currentMapImagePath != null) ...[
                  const SizedBox(height: 4),
                  _GraphMapBtn(
                    icon: Icons.close,
                    label: 'Karte entfernen',
                    onTap: () => vm.setCurrentLevelMapImage(null),
                    C: C,
                  ),
                  const SizedBox(height: 4),
                  _GraphMapBtn(
                    icon: Icons.layers_outlined,
                    label: 'Layer',
                    active: _showLayerPanel,
                    onTap: () => setState(() => _showLayerPanel = !_showLayerPanel),
                    C: C,
                  ),
                  if (lanVm.paintMode == 'viewport') ...[
                    const SizedBox(height: 4),
                    _GraphMapBtn(
                      icon: Icons.zoom_in,
                      label: 'Spieler-Zoom +',
                      onTap: () => lanVm.setBroadcastScale(lanVm.broadcastScale + 0.5),
                      C: C,
                    ),
                    const SizedBox(height: 2),
                    _GraphMapBtn(
                      icon: Icons.zoom_out,
                      label: 'Spieler-Zoom −',
                      onTap: lanVm.broadcastScale > 0.5
                          ? () => lanVm.setBroadcastScale(lanVm.broadcastScale - 0.5)
                          : null,
                      C: C,
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                _GraphMapBtn(
                  icon: Icons.add,
                  label: 'Pins größer',
                  onTap: _pinScale < 3.0
                      ? () => setState(() => _pinScale = (_pinScale + 0.25).clamp(0.5, 3.0))
                      : null,
                  C: C,
                ),
                const SizedBox(height: 4),
                _GraphMapBtn(
                  icon: Icons.remove,
                  label: 'Pins kleiner',
                  onTap: _pinScale > 0.5
                      ? () => setState(() => _pinScale = (_pinScale - 0.25).clamp(0.5, 3.0))
                      : null,
                  C: C,
                ),
                if (isVorbereitung) ...[
                  const SizedBox(height: 8),
                  _GraphMapBtn(
                    icon: _connectMode ? Icons.link_off : Icons.link,
                    label: _connectMode
                        ? 'Verbindungs-Modus beenden'
                        : 'Verbindungen bearbeiten',
                    active: _connectMode,
                    onTap: () => setState(() {
                      _connectMode = !_connectMode;
                      _connectSource = null;
                      _scenePlaceMode = false;
                    }),
                    C: C,
                  ),
                  const SizedBox(height: 4),
                  _GraphMapBtn(
                    icon: _scenePlaceMode
                        ? Icons.close
                        : Icons.add_location_alt_outlined,
                    label: _scenePlaceMode
                        ? 'Platzieren beenden'
                        : 'Szene platzieren',
                    active: _scenePlaceMode,
                    onTap: () => setState(() {
                      _scenePlaceMode = !_scenePlaceMode;
                      _connectMode = false;
                      _connectSource = null;
                    }),
                    C: C,
                  ),
                ],
              ],
            ),
          ),

          if (_connectMode)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: C.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _connectSource == null
                        ? 'Tippe auf einen Ort als Ausgangspunkt'
                        : 'Tippe auf den Ziel-Ort  •  Nochmals tippen zum Abbrechen',
                    style: TextStyle(fontSize: 11, color: C.amber),
                  ),
                ),
              ),
            ),

          if (_scenePlaceMode)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: C.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Tippe auf die Karte, um eine Szene zu platzieren',
                    style: TextStyle(fontSize: 11, color: C.accent),
                  ),
                ),
              ),
            ),

          // Layer-Panel
          if (_showLayerPanel)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _LayerPanel(vm: vm, C: C),
            ),
        ],
      );
    });
  }
}

// ── LAYER PANEL ───────────────────────────────────────────────────────────────

class _LayerPanel extends StatelessWidget {
  const _LayerPanel({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final layers = vm.currentLevelLayers;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(right: BorderSide(color: C.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: C.bgHover,
              border: Border(bottom: BorderSide(color: C.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.layers_outlined, size: 15, color: C.accent),
                const SizedBox(width: 8),
                Text('Karten-Layer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
                const Spacer(),
                Tooltip(
                  message: 'Layer hinzufügen',
                  child: GestureDetector(
                    onTap: () => _addLayer(context),
                    child: Icon(Icons.add, size: 18, color: C.accent),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: layers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Noch keine Layer.\nTippe auf + um einen hinzuzufügen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: C.textSoft),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: layers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: C.border),
                    itemBuilder: (_, i) => _LayerRow(layer: layers[i], vm: vm, C: C),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addLayer(BuildContext context) async {
    final nameController = TextEditingController();
    final C = this.C;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Neuer Layer', style: TextStyle(color: C.text, fontSize: 15)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: C.text),
          decoration: InputDecoration(
            hintText: 'Layer-Name',
            hintStyle: TextStyle(color: C.textSoft),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: C.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: C.accent)),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Abbrechen', style: TextStyle(color: C.textSoft))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Erstellen', style: TextStyle(color: C.accent)),
          ),
        ],
      ),
    );
    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      await vm.createLayer(nameController.text.trim());
    }
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({required this.layer, required this.vm, required this.C});

  final MapLayer layer;
  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => vm.toggleLayerVisibility(layer),
            child: Icon(
              layer.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 18,
              color: layer.isVisible ? C.accent : C.textSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickImage(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layer.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (layer.imagePath != null)
                    Text(
                      layer.imagePath!.split(Platform.pathSeparator).last,
                      style: TextStyle(fontSize: 10, color: C.textSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text('Kein Bild – tippen zum Laden', style: TextStyle(fontSize: 10, color: C.textSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Icon(Icons.delete_outline, size: 16, color: C.textSoft),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final ref = await pickResource(context);
    if (ref != null) await vm.setLayerImage(layer, ref);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final C = this.C;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Layer löschen?', style: TextStyle(color: C.text, fontSize: 15)),
        content: Text('"${layer.name}" wird unwiderruflich entfernt.', style: TextStyle(color: C.textSoft, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Abbrechen', style: TextStyle(color: C.textSoft))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Löschen', style: TextStyle(color: C.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await vm.deleteLayer(layer);
  }
}

// ── KARTE EDGE PAINTER ────────────────────────────────────────────────────────

class _KarteEdgePainter extends CustomPainter {
  const _KarteEdgePainter({
    required this.orte,
    required this.positions,
    required this.connectSource,
    required this.lineColor,
    required this.sourceColor,
  });

  final List<Ort> orte;
  final Map<String, Offset> positions;
  final String? connectSource;
  final Color lineColor;
  final Color sourceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final seen = <String>{};
    for (final ort in orte) {
      final from = positions[ort.id];
      if (from == null || ort.connectedOrtIds.isEmpty) continue;

      for (final toId in ort.connectedOrtIds) {
        final edgeKey = ([ort.id, toId]..sort()).join('-');
        if (seen.contains(edgeKey)) continue;
        seen.add(edgeKey);

        final to = positions[toId];
        if (to == null) continue;

        final isHighlighted = connectSource == ort.id || connectSource == toId;
        final paint = Paint()
          ..color = isHighlighted ? sourceColor.withValues(alpha: 0.85) : lineColor
          ..strokeWidth = isHighlighted ? 2.5 : 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        _drawLine(canvas, from, to, paint);
      }
    }
  }

  static void _drawLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dir = to - from;
    if (dir.distance < 2) return;
    const nodeR = 28.0;
    final unit = dir / dir.distance;
    final start = from + unit * nodeR;
    final end = to - unit * nodeR;
    if ((end - start).distance < nodeR) return;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(_KarteEdgePainter old) =>
      old.orte != orte ||
      old.positions != positions ||
      old.connectSource != connectSource;
}

// ── KARTE MAP NODE ────────────────────────────────────────────────────────────

class _KarteMapNode extends StatefulWidget {
  const _KarteMapNode({
    required this.ort,
    required this.selected,
    required this.isConnectSource,
    required this.hasChildren,
    required this.sceneCount,
    required this.C,
  });

  final Ort ort;
  final bool selected;
  final bool isConnectSource;
  final bool hasChildren;
  final int sceneCount;
  final AppColorsExtension C;

  @override
  State<_KarteMapNode> createState() => _KarteMapNodeState();
}

class _KarteMapNodeState extends State<_KarteMapNode> {
  bool _hovered = false;

  Color _typeColor(AppColorsExtension C) {
    switch (widget.ort.type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    final ort = widget.ort;
    final dotColor = widget.isConnectSource ? C.amber : _typeColor(C);
    final isActive = widget.selected || widget.isConnectSource;
    final dotSize = isActive ? 12.0 : 9.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? Color.alphaBlend(dotColor.withValues(alpha: 0.22), C.bgPanel)
              : _hovered
                  ? C.bgPanel.withValues(alpha: 0.92)
                  : C.bgPanel.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? dotColor.withValues(alpha: 0.6) : C.border.withValues(alpha: 0.7),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
            if (isActive)
              BoxShadow(
                color: dotColor.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: ort.hasBeenVisited
                    ? dotColor.withValues(alpha: 0.5)
                    : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                ort.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? dotColor : C.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.hasChildren) ...[
              const SizedBox(width: 3),
              Icon(Icons.map_outlined, size: 9, color: dotColor.withValues(alpha: 0.8)),
            ],
            if (widget.ort.mapPositionLocked) ...[
              const SizedBox(width: 3),
              Icon(Icons.lock_outline, size: 9, color: C.textSoft.withValues(alpha: 0.7)),
            ],
            if (ort.type == OrtType.token) ...[
              const SizedBox(width: 3),
              Icon(Icons.wifi_tethering, size: 9, color: dotColor.withValues(alpha: 0.9)),
            ],
            if (widget.sceneCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.sceneCount}',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: C.bgPanel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── PLACE SCENE DIALOG ────────────────────────────────────────────────────────

class _PlaceSceneDialog extends StatefulWidget {
  const _PlaceSceneDialog();

  @override
  State<_PlaceSceneDialog> createState() => _PlaceSceneDialogState();
}

class _PlaceSceneDialogState extends State<_PlaceSceneDialog> {
  final _nameCtrl = TextEditingController();
  SceneType _type = SceneType.Combat;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = Theme.of(context).extension<AppColorsExtension>()!;
    return AlertDialog(
      backgroundColor: C.bgPanel,
      title: const Text('Szene platzieren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'z.B. Goblin-Hinterhalt',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Typ:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SceneType.values.map((t) {
              final selected = t == _type;
              return ChoiceChip(
                label: Text('${_sceneTypeEmoji(t)} ${_sceneTypeLabel(t)}'),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: C.accent.withValues(alpha: 0.25),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name: name, type: _type));
          },
          style: FilledButton.styleFrom(backgroundColor: C.accent),
          child: const Text('Platzieren'),
        ),
      ],
    );
  }

  String _sceneTypeLabel(SceneType t) => switch (t) {
    SceneType.Combat       => 'Kampf',
    SceneType.Social       => 'Sozial',
    SceneType.Exploration  => 'Erkundung',
    SceneType.Puzzle       => 'Rätsel',
    SceneType.Introduction => 'Einführung',
    SceneType.Climax       => 'Höhepunkt',
    SceneType.Resolution   => 'Auflösung',
  };

  String _sceneTypeEmoji(SceneType t) => switch (t) {
    SceneType.Combat       => '⚔️',
    SceneType.Social       => '💬',
    SceneType.Exploration  => '🔍',
    SceneType.Puzzle       => '🧩',
    SceneType.Introduction => '📖',
    SceneType.Climax       => '🔥',
    SceneType.Resolution   => '🏆',
  };
}

// ── KARTE ORT PICKER DIALOG ───────────────────────────────────────────────────

class _KarteOrtPickerDialog extends StatefulWidget {
  const _KarteOrtPickerDialog({required this.orte});

  final List<Ort> orte;

  @override
  State<_KarteOrtPickerDialog> createState() => _KarteOrtPickerDialogState();
}

class _KarteOrtPickerDialogState extends State<_KarteOrtPickerDialog> {
  String _search = '';

  Color _typeColor(OrtType type, AppColorsExtension C) {
    switch (type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    // Unpositioned first, then sorted by name
    final sorted = [...widget.orte]..sort((a, b) {
        final aPos = a.mapX != null && a.mapX! >= 0 && a.mapX! <= 1;
        final bPos = b.mapX != null && b.mapX! >= 0 && b.mapX! <= 1;
        if (aPos != bPos) return aPos ? 1 : -1;
        return a.name.compareTo(b.name);
      });

    final filtered = _search.isEmpty
        ? sorted
        : sorted.where((o) => o.name.toLowerCase().contains(_search.toLowerCase())).toList();

    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_location_alt_outlined, size: 16, color: C.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Ort hier platzieren',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Suchen…',
                  hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
                  prefixIcon: Icon(Icons.search, size: 16, color: C.textSoft),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: C.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: C.accent),
                  ),
                  filled: true,
                  fillColor: C.bgHover,
                ),
                style: TextStyle(fontSize: 12, color: C.text),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Keine Orte gefunden', style: TextStyle(fontSize: 12, color: C.textSoft)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: C.border.withValues(alpha: 0.5)),
                    itemBuilder: (_, i) {
                      final ort = filtered[i];
                      final color = _typeColor(ort.type, C);
                      final isPositioned = ort.mapX != null && ort.mapX! >= 0 && ort.mapX! <= 1;
                      return InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => Navigator.pop(context, ort),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ort.name,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      ort.type.label,
                                      style: TextStyle(fontSize: 10, color: C.textSoft),
                                    ),
                                  ],
                                ),
                              ),
                              if (isPositioned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(Icons.location_on, size: 13, color: C.textSoft),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CamTokenDot extends StatelessWidget {
  final MapToken token;
  final double size;

  const _CamTokenDot({required this.token, required this.size});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(int.parse('0xFF${token.color.replaceFirst('#', '')}'));
    } catch (_) {
      color = Colors.red;
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          token.label.length > 2
              ? token.label.substring(0, 2).toUpperCase()
              : token.label.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _QrDialog extends StatelessWidget {
  const _QrDialog({
    required this.lanUrl,
    required this.localUrl,
    required this.emuUrl,
  });
  final String lanUrl;
  final String localUrl;
  final String emuUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lanUrl.isNotEmpty) ...[
              QrImageView(
                data: lanUrl,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                lanUrl,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              Text(
                'WLAN-Gäste – QR-Code scannen',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 24, color: Color(0xFFDDDDDD)),
            ],
            _QrUrlRow(label: 'Gleicher PC', url: localUrl),
            const SizedBox(height: 6),
            _QrUrlRow(label: 'Android-Emulator', url: emuUrl),
          ],
        ),
      ),
    );
  }
}

class _QrUrlRow extends StatelessWidget {
  const _QrUrlRow({required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
        SelectableText(
          url,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87),
        ),
      ],
    );
  }
}

// ── TOKEN SIZE SLIDER ─────────────────────────────────────────────────────────
// StatefulWidget keeps local drag state so rebuilds from Provider don't interrupt
// the gesture. Only broadcasts to ViewModel on drag end.

class _TokenSizeSlider extends StatefulWidget {
  const _TokenSizeSlider({
    super.key,
    required this.initialSize,
    required this.onSizeChanged,
  });

  final double initialSize;
  final ValueChanged<double> onSizeChanged;

  @override
  State<_TokenSizeSlider> createState() => _TokenSizeSliderState();
}

class _TokenSizeSliderState extends State<_TokenSizeSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialSize;
  }

  @override
  void didUpdateWidget(_TokenSizeSlider old) {
    super.didUpdateWidget(old);
    // Sync when the selected ort changes (key forces new instance, but guard anyway)
    if (old.initialSize != widget.initialSize) _value = widget.initialSize;
  }

  void _step(double delta) {
    final v = (_value + delta).clamp(0.5, 4.0);
    setState(() => _value = v);
    widget.onSizeChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 5)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _step(-0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.remove, size: 11, color: C.textSoft),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: const Color(0xFF9b59b6),
                inactiveTrackColor: const Color(0xFF9b59b6).withValues(alpha: 0.25),
                thumbColor: const Color(0xFF9b59b6),
                overlayColor: const Color(0xFF9b59b6).withValues(alpha: 0.15),
              ),
              child: Slider(
                value: _value,
                min: 0.5,
                max: 4.0,
                divisions: 7,
                onChanged: (v) => setState(() => _value = v),
                onChangeEnd: widget.onSizeChanged,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _step(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.add, size: 11, color: C.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}
