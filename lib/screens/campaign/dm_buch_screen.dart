import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../models/ort.dart';
import '../../models/quest.dart';
import '../../models/scene.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/dm_buch_viewmodel.dart';
import '../../widgets/active_session/atmosphere_quadrant.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import '../../widgets/ui_components/shared/app_logo.dart';
import '../quests/edit_quest_screen.dart';
import '../scenes/edit_scene_screen.dart';
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

                  // Session starten (nur im Live-Modus)
                  if (vm.mode == DmBuchMode.live) ...[
                    _StartSessionBtn(vm: vm, C: C),
                    const SizedBox(width: 8),
                  ],

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
            child: vm.leftTab == DmBuchLeftTab.karte
                ? _KarteTab(vm: vm)
                : _QuestsTab(vm: vm),
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
                const Spacer(),
                if (vm.leftTab == DmBuchLeftTab.karte)
                  _TopBarIconBtn(
                    icon: AppIconName.plus,
                    C: C,
                    onTap: () => _showCreateOrtDialog(context),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: C.border),
        ],
      );

  void _showCreateOrtDialog(BuildContext context) =>
      showDialog<void>(
        context: context,
        builder: (ctx) => _CreateOrtDialog(vm: vm),
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

class _KarteTab extends StatelessWidget {
  const _KarteTab({required this.vm});

  final DmBuchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    if (vm.orte.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 32, color: C.textSoft),
            const SizedBox(height: 10),
            Text(
              'Noch keine Orte',
              style: TextStyle(fontSize: 13, color: C.textSoft),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe + um den ersten Ort anzulegen.',
              style: TextStyle(fontSize: 11, color: C.textSoft),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: vm.orte.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _OrtCard(
          ort: vm.orte[i],
          selected: vm.selectedOrt?.id == vm.orte[i].id,
          vm: vm,
        ),
      ),
    );
  }
}

class _OrtCard extends StatefulWidget {
  const _OrtCard({
    required this.ort,
    required this.selected,
    required this.vm,
  });

  final Ort ort;
  final bool selected;
  final DmBuchViewModel vm;

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
              // Typ-Punkt
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
                        color: C.text,
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
                  decoration: BoxDecoration(
                    color: C.amber,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(
                      builder: (_) => EditQuestScreen(campaignId: vm.campaign.id),
                    ))
                    .then((_) => vm.reloadQuests()),
                child: Text(
                  'Quest erstellen',
                  style: TextStyle(fontSize: 11, color: C.accent),
                ),
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
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(
                          builder: (_) => EditQuestScreen(quest: quests[i]),
                        ))
                        .then((_) => vm.reloadQuests()),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuestRow extends StatefulWidget {
  const _QuestRow({required this.quest, required this.C, required this.onTap});

  final Quest quest;
  final AppColorsExtension C;
  final VoidCallback onTap;

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
            color: _hovered ? C.bgHover : C.bgPanel,
            border: Border.all(color: C.border),
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
              const SizedBox(width: 6),
              AppIcon(AppIconName.chevronRight, size: 12, color: C.textSoft),
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

    if (ort == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 36, color: C.textSoft),
            const SizedBox(height: 12),
            Text(
              'Wähle einen Ort aus der Karte',
              style: TextStyle(fontSize: 14, color: C.textSoft),
            ),
          ],
        ),
      );
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
                      '${vm.selectedOrtScenes.length} Szene${vm.selectedOrtScenes.length != 1 ? "n" : ""}',
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
                    : 'Dieser Ort wurde bereits besucht.',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Szenen
        _SectionHeader(
          title: 'Szenen',
          C: C,
          action: 'Szene hinzufügen',
          onAction: () => showDialog<void>(
            context: context,
            builder: (_) => _CreateSceneDialog(ort: ort, vm: vm),
          ),
        ),
        const SizedBox(height: 8),
        if (vm.selectedOrtScenes.isEmpty)
          _EmptyHint('Noch keine Szenen für diesen Ort.', C)
        else
          ...vm.selectedOrtScenes.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SceneRow(scene: s, vm: vm),
              )),
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
}

class _SceneRow extends StatefulWidget {
  const _SceneRow({required this.scene, required this.vm});

  final Scene scene;
  final DmBuchViewModel vm;

  @override
  State<_SceneRow> createState() => _SceneRowState();
}

class _SceneRowState extends State<_SceneRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(
              builder: (_) => EditSceneScreen(scene: widget.scene),
            ))
            .then((_) => widget.vm.reloadScenes()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? C.bgHover : C.bgPanel,
            border: Border.all(color: C.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.scene.isCompleted ? C.green : C.textSoft,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.scene.name,
                  style: TextStyle(fontSize: 13, color: C.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppIcon(AppIconName.chevronRight, size: 12, color: C.textSoft),
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
            Text('Neuer Ort',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
            const SizedBox(height: 16),
            _field(context, C, controller: _nameCtrl, hint: 'Name des Ortes', autofocus: true),
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
                    await widget.vm.createOrt(
                      name: name,
                      type: _type,
                      description: _descCtrl.text.trim(),
                    );
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
                  child: Text('Ort bearbeiten',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                ),
                IconButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await widget.vm.deleteOrt(widget.ort.id);
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: C.red),
                  tooltip: 'Ort löschen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
}

// ── CREATE SCENE DIALOG ───────────────────────────────────────────────────────

class _CreateSceneDialog extends StatefulWidget {
  const _CreateSceneDialog({required this.ort, required this.vm});

  final Ort ort;
  final DmBuchViewModel vm;

  @override
  State<_CreateSceneDialog> createState() => _CreateSceneDialogState();
}

class _CreateSceneDialogState extends State<_CreateSceneDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  SceneType _type = SceneType.Exploration;

  static const Map<SceneType, String> _labels = {
    SceneType.Introduction: 'Einführung',
    SceneType.Exploration:  'Erforschung',
    SceneType.Combat:       'Kampf',
    SceneType.Social:       'Sozial',
    SceneType.Puzzle:       'Rätsel',
    SceneType.Climax:       'Höhepunkt',
    SceneType.Resolution:   'Auflösung',
  };

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
            Text(
              'Szene für ${widget.ort.name}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: C.text),
              decoration: _inputDeco(C, 'Name der Szene'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<SceneType>(
              value: _type,
              dropdownColor: C.bgPanel,
              style: TextStyle(fontSize: 13, color: C.text),
              decoration: _inputDeco(C, 'Typ'),
              items: SceneType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_labels[t] ?? t.name),
                      ))
                  .toList(),
              onChanged: (t) { if (t != null) setState(() => _type = t); },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: C.text),
              decoration: _inputDeco(C, 'Beschreibung (optional)'),
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
                    await widget.vm.createSceneForOrt(
                      widget.ort,
                      name: name,
                      type: _type,
                      description: _descCtrl.text.trim(),
                    );
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

// ── START SESSION BUTTON ──────────────────────────────────────────────────────

class _StartSessionBtn extends StatefulWidget {
  const _StartSessionBtn({required this.vm, required this.C});

  final DmBuchViewModel vm;
  final AppColorsExtension C;

  @override
  State<_StartSessionBtn> createState() => _StartSessionBtnState();
}

class _StartSessionBtnState extends State<_StartSessionBtn> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final C = widget.C;

    return GestureDetector(
      onTap: _loading ? null : () => _start(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: C.accent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: C.bg,
                ),
              )
            else
              Icon(Icons.play_arrow_rounded, size: 14, color: C.bg),
            const SizedBox(width: 5),
            Text(
              'Session starten',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: C.bg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    setState(() => _loading = true);
    final session = await widget.vm.startSession();
    if (!mounted) return;
    setState(() => _loading = false);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session konnte nicht erstellt werden'),
          backgroundColor: widget.C.red,
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveSessionScreen(
          session: session,
          campaign: widget.vm.campaign,
        ),
      ),
    );
  }
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
                  : '$count Ort${count == 1 ? '' : 'e'} aktualisiert';
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
