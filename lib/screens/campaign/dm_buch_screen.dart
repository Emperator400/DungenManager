import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../models/ort.dart';
import '../../models/player.dart';
import '../../models/player_character.dart';
import '../../models/quest.dart';
import '../../models/session.dart';
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
import '../quests/edit_quest_screen.dart';
import '../session/active_session_screen.dart';

// ── ENTRY POINT ───────────────────────────────────────────────────────────────

class DmBuchScreen extends StatelessWidget {
  const DmBuchScreen({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DmBuchViewModel(campaign: campaign)..init(),
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
    final themeNotifier = context.watch<ThemeNotifier>();

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

                  // Logo + Kampagnen-Name
                  const AppLogo(size: 18),
                  const SizedBox(width: 8),
                  Expanded(
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

                  // Modus-Toggle
                  _ModeToggle(vm: vm, C: C),
                  const SizedBox(width: 8),

                  // Sync-Button (nur für Kopie-Kampagnen)
                  if (vm.campaign.templateId != null) ...[
                    _SyncBtn(vm: vm, C: C),
                    const SizedBox(width: 4),
                  ],

                  // Dark/Light Toggle
                  _TopBarIconBtn(
                    icon: themeNotifier.isDark
                        ? AppIconName.sun
                        : AppIconName.moon,
                    C: C,
                    onTap: () => themeNotifier.toggle(),
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeBtn(
            label: 'Vorbereitung',
            active: vm.mode == DmBuchMode.vorbereitung,
            C: C,
            onTap: () => vm.setMode(DmBuchMode.vorbereitung),
          ),
          _ModeBtn(
            label: 'Live',
            active: vm.mode == DmBuchMode.live,
            C: C,
            onTap: () => vm.setMode(DmBuchMode.live),
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  const _ModeBtn({
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? C.bgPanel : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: active ? Border.all(color: C.border) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? C.text : C.textMid,
            ),
          ),
        ),
      );
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
    final sorted = <({Ort ort, int? stepIndex, bool stepDone, String? stepEntryId})>[];
    final inPlanOrtIds = <String>{};

    for (var i = 0; i < vm.verlaufsplan.length; i++) {
      final entry = vm.verlaufsplan[i];
      if (entry.type != VerlaufsEintragType.ort || entry.refId == null) continue;
      final ort = vm.orte.where((o) => o.id == entry.refId).firstOrNull;
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
              // Verlauf-Sort nur auf Weltkarte sinnvoll
              if (!onSubMap)
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
              : (!onSubMap && _verlaufsSort)
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
  });

  final Ort ort;
  final bool selected;
  final DmBuchViewModel vm;
  final int? stepIndex;
  final bool stepDone;
  final VoidCallback? onToggleDone;

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
        onTap: () => widget.vm.selectOrt(widget.ort),
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

    final hasChildren = vm.hasChildren(ort.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Subkarte
        _LiveActionBtn(
          label: hasChildren ? 'Subkarte öffnen' : 'Subkarte erstellen',
          icon: Icons.map_outlined,
          color: C.accent,
          C: C,
          onTap: () => vm.drillInto(ort),
        ),
        const SizedBox(height: 6),
        _LiveActionBtn(
          label: ort.mapPositionLocked ? 'Position entsperren' : 'Position sperren',
          icon: ort.mapPositionLocked ? Icons.lock_open_outlined : Icons.lock_outline,
          color: ort.mapPositionLocked ? C.amber : C.textSoft,
          C: C,
          onTap: () => vm.toggleOrtPositionLock(ort),
        ),
        const SizedBox(height: 16),

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
        const SizedBox(height: 20),

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
            if (entry == null) return const SizedBox.shrink();
            return _WikiEntryRow(entry: entry, onRemove: () => vm.unlinkWikiEntry(ort, wikiId), C: C);
          }),

        const SizedBox(height: 20),

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
              onSelect: () => vm.selectOrt(target),
              C: C,
            );
          }),

        const SizedBox(height: 20),

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

        const SizedBox(height: 20),

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

  void _showWikiPickerDialog(BuildContext context) {
    final C = context.appColors;
    final available = vm.wikiEntries
        .where((w) => !ort.linkedWikiEntryIds.contains(w.id))
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
                Text('Wiki-Eintrag verknüpfen',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 12),
                if (available.isEmpty)
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
    }
  }
}

class _WikiEntryRow extends StatelessWidget {
  const _WikiEntryRow({required this.entry, required this.onRemove, required this.C});
  final WikiEntry entry;
  final VoidCallback onRemove;
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
            Icon(Icons.menu_book_outlined, size: 13, color: C.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(entry.entryType.name,
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ort.name);
    _descCtrl = TextEditingController(text: widget.ort.description);
    _type = widget.ort.type;
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

// ── SYNC BUTTON ───────────────────────────────────────────────────────────────

class _SyncBtn extends StatelessWidget {
  const _SyncBtn({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    if (vm.isSyncing) {
      return SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: C.textMid,
            ),
          ),
        ),
      );
    }
    return Tooltip(
      message: 'Änderungen aus Vorlage übernehmen',
      child: _TopBarIconBtn(
        icon: AppIconName.refresh,
        C: C,
        onTap: () async {
          final count = await vm.syncFromTemplate();
          if (!context.mounted) return;
          final msg = count == null
              ? 'Sync fehlgeschlagen'
              : count == 0
                  ? 'Alles aktuell – keine Änderungen'
                  : '$count Marker aktualisiert';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 3),
              backgroundColor: count == null ? C.red : C.green,
            ),
          );
        },
      ),
    );
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
          child: plan.isEmpty
              ? Center(
                  child: Text(
                    'Noch kein Verlaufsplan',
                    style: TextStyle(fontSize: 13, color: C.textSoft),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  buildDefaultDragHandles: false,
                  onReorder: isVorbereitung ? vm.reorderVerlaufsplan : (_, __) {},
                  itemCount: plan.length,
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
        child: Row(
          children: [
            // Farb-Streifen
            Container(
              width: 4,
              height: 48,
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
                    if (e.note != null && e.note!.isNotEmpty)
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && ctx.mounted) {
      await widget.vm.setVerlaufsKarteImage(result.files.single.path);
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
                  if (vm.verlaufsKarteImagePath != null)
                    Positioned.fill(
                      child: Image.file(
                        File(vm.verlaufsKarteImagePath!),
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
  const _TopBarIconBtn({required this.icon, required this.C, required this.onTap});

  final AppIconName icon;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_TopBarIconBtn> createState() => _TopBarIconBtnState();
}

class _TopBarIconBtnState extends State<_TopBarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
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
              child: AppIcon(widget.icon, size: 14, color: widget.C.textMid),
            ),
          ),
        ),
      );
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

  final TransformationController _tc = TransformationController();
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _dragPos = {};

  bool _connectMode = false;
  String? _connectSource;

  String? _lastSelectedOrtId;
  BoxConstraints? _constraints;
  late final AnimationController _flyAnim;
  late Animation<Offset> _flyAnimation;
  double _flyScale = 1.0;

  int _lastMapDepth = 1;
  double _pinScale = 1.0;

  @override
  void initState() {
    super.initState();
    _lastMapDepth = widget.vm.mapStackDepth;
    _initPositions(widget.vm.currentLevelOrte);
    _flyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onFlyTick);
  }

  @override
  void didUpdateWidget(_KarteGraphView old) {
    super.didUpdateWidget(old);

    // Wenn die Kartenebene gewechselt hat, Positionen neu initialisieren
    if (widget.vm.mapStackDepth != _lastMapDepth) {
      _lastMapDepth = widget.vm.mapStackDepth;
      _lastSelectedOrtId = null;
      _dragPos.clear();
      _initPositions(widget.vm.currentLevelOrte);
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && ctx.mounted) {
      await widget.vm.setCurrentLevelMapImage(result.files.single.path);
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

  Future<void> _onNodeTap(Ort ort) async {
    final vm = widget.vm;
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
    final vm = widget.vm;
    final C = context.appColors;
    final isVorbereitung = vm.mode == DmBuchMode.vorbereitung;
    final orte = vm.currentLevelOrte;
    final onSubMap = vm.currentMapParentId != null;

    return LayoutBuilder(builder: (context, constraints) {
      _constraints = constraints;
      // Canvas = Viewport: proportional wie BoxFit.contain beim Kartenbild
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
            onDoubleTapDown: (isVorbereitung && !_connectMode)
                ? (d) => _onCanvasDoubleTap(context, d.localPosition)
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
                    // Hintergrund (Karte oder Dot-Grid)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: vm.currentMapImagePath != null
                            ? Image.file(
                                File(vm.currentMapImagePath!),
                                fit: BoxFit.contain,
                                frameBuilder: (ctx, child, frame, sync) =>
                                    (sync || frame != null) ? child : CustomPaint(painter: _GraphGridPainter(C)),
                                errorBuilder: (_, __, ___) => ColoredBox(color: C.bgPanel),
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
                    for (final ort in orte)
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
                                C: C,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
        ],
      );
    });
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
    required this.C,
  });

  final Ort ort;
  final bool selected;
  final bool isConnectSource;
  final bool hasChildren;
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
          ],
        ),
      ),
    );
  }
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
