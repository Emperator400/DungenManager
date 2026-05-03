import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sound.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/sound_library_viewmodel.dart';
import '../../widgets/sound_scenes_tab.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import '../../viewmodels/edit_sound_viewmodel.dart';
import 'edit_sound_screen.dart';

// ── Category config ───────────────────────────────────────────────────────────

class _KC {
  const _KC({required this.color, required this.lightBg, required this.darkBg});
  final Color color;
  final Color lightBg;
  final Color darkBg;
  Color bg(bool isDark) => isDark ? darkBg : lightBg;
}

const Map<SoundType, _KC> _kc = {
  SoundType.Ambiente: _KC(
    color: Color(0xFF0891b2),
    lightBg: Color(0xFFecfbff),
    darkBg: Color(0xFF0a1f28),
  ),
  SoundType.Effekt: _KC(
    color: Color(0xFFc93a3a),
    lightBg: Color(0xFFfdf0f0),
    darkBg: Color(0xFF2a1212),
  ),
};

_KC _cfg(SoundType? t) => _kc[t] ?? _kc[SoundType.Ambiente]!;

String _fmtDuration(Duration? d) {
  if (d == null) return '—';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _KatFilter { all, ambiente, effekt, favorites }

// ── SoundLibraryScreen ────────────────────────────────────────────────────────

class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> {
  late SoundLibraryViewModel _vm;
  final _searchCtrl = TextEditingController();
  _KatFilter _katFilter = _KatFilter.all;
  String? _selectedSoundId;
  bool _tabSounds = true;

  // ── Preview player ──────────────────────────────────────────────────────────
  final _player = AudioPlayer();
  String? _playingId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _vm = SoundLibraryViewModel();
    _vm.addListener(_onVmChanged);
    _searchCtrl.addListener(_onSearch);
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _playingId = null; });
    });
    _vm.loadSounds();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _playSound(Sound s) async {
    setState(() => _selectedSoundId = s.id);
    if (_playingId == s.id) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } else {
      final file = File(s.filePath);
      if (!file.existsSync()) {
        if (mounted) SnackBarHelper.showError(context, 'Datei nicht gefunden');
        return;
      }
      _playingId = s.id;
      await _player.stop();
      await _player.play(DeviceFileSource(s.filePath));
    }
  }

  Future<void> _stopPreview() async {
    await _player.stop();
    setState(() { _isPlaying = false; _playingId = null; });
  }

  void _onVmChanged() {
    setState(() {
      final list = _filteredSounds();
      if (_selectedSoundId == null && list.isNotEmpty) {
        _selectedSoundId = list.first.id;
      } else if (_selectedSoundId != null &&
          !list.any((s) => s.id == _selectedSoundId)) {
        _selectedSoundId = list.isNotEmpty ? list.first.id : null;
      }
    });
  }

  void _onSearch() {
    _vm.setSoundSearchQuery(_searchCtrl.text);
  }

  List<Sound> _filteredSounds() {
    return _vm.sounds.where((s) {
      return switch (_katFilter) {
        _KatFilter.all       => true,
        _KatFilter.ambiente  => s.soundType == SoundType.Ambiente,
        _KatFilter.effekt    => s.soundType == SoundType.Effekt,
        _KatFilter.favorites => s.isFavorite,
      };
    }).toList();
  }

  Future<void> _openEditor([Sound? sound]) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: ChangeNotifierProvider(
            create: (_) => EditSoundViewModel(),
            child: EditSoundScreen(sound: sound),
          ),
        ),
      ),
    );
    await _vm.loadSounds();
  }

  Future<void> _toggleFavorite(Sound sound) async {
    try {
      await _vm.toggleSoundFavorite(sound.id);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }

  void _switchTab(bool toSounds) {
    setState(() {
      _tabSounds = toSounds;
      _searchCtrl.clear();
      _katFilter = _KatFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final filtered = _filteredSounds();
    final selected = filtered.cast<Sound?>().firstWhere(
      (s) => s!.id == _selectedSoundId,
      orElse: () => null,
    );

    return ChangeNotifierProvider<SoundLibraryViewModel>.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: _buildTopBar(context, C),
        body: Column(
          children: [
            _buildTabBar(C),
            Expanded(
              child: _tabSounds
                  ? _buildSoundsBody(context, C, filtered, selected)
                  : const SoundScenesTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ── TopBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTopBar(
      BuildContext context, AppColorsExtension C) {
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
                    if (Navigator.canPop(context)) ...[
                      _IconBtn(
                          C: C,
                          icon: AppIconName.back,
                          onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 18, color: C.border),
                      const SizedBox(width: 10),
                    ],
                    AppIcon(AppIconName.music, size: 16, color: C.accent),
                    const SizedBox(width: 8),
                    Text('Sound & Atmosphäre',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: C.text)),
                    const SizedBox(width: 8),
                    ListenableBuilder(
                      listenable: _vm,
                      builder: (_, __) => Text(
                        '${_vm.soundCount} Sounds · ${_vm.favoriteCount} Favoriten',
                        style:
                            TextStyle(fontSize: 11, color: C.textSoft),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      icon: AppIcon(AppIconName.plus,
                          size: 12, color: Colors.white),
                      label: Text(_tabSounds ? 'Sound' : 'Szene'),
                      style: FilledButton.styleFrom(
                        backgroundColor: C.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(AppColorsExtension C) {
    return Container(
      color: C.bgPanel,
      child: Column(
        children: [
          Row(
            children: [
              _Tab(
                label: 'Sounds',
                icon: AppIconName.music,
                active: _tabSounds,
                C: C,
                onTap: () => _switchTab(true),
              ),
              _Tab(
                label: 'Szenen',
                icon: AppIconName.scroll,
                active: !_tabSounds,
                C: C,
                onTap: () => _switchTab(false),
              ),
            ],
          ),
          Divider(height: 1, thickness: 1, color: C.border),
        ],
      ),
    );
  }

  // ── Sounds body ──────────────────────────────────────────────────────────────

  Widget _buildSoundsBody(
    BuildContext context,
    AppColorsExtension C,
    List<Sound> filtered,
    Sound? selected,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 340,
          child: _buildSoundsLeft(context, C, filtered, selected),
        ),
        VerticalDivider(width: 1, thickness: 1, color: C.border),
        Expanded(child: _buildSoundsRight(context, C, selected)),
      ],
    );
  }

  Widget _buildSoundsLeft(
    BuildContext context,
    AppColorsExtension C,
    List<Sound> filtered,
    Sound? selected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: C.bgPanel,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: _SearchField(
              ctrl: _searchCtrl,
              hint: 'Sounds suchen...',
              C: C,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _buildKatFilter(C, isDark),
          ),
          Divider(height: 1, thickness: 1, color: C.border),
          Expanded(
            child: _vm.isLoadingSounds
                ? Center(
                    child: CircularProgressIndicator(
                        color: C.accent, strokeWidth: 2))
                : filtered.isEmpty
                    ? _EmptyList(
                        icon: AppIconName.music,
                        label: 'Keine Sounds gefunden',
                        C: C)
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          final rowPlaying =
                              _playingId == s.id && _isPlaying;
                          return _SoundRow(
                            sound: s,
                            isSelected: s.id == _selectedSoundId,
                            isPlaying: rowPlaying,
                            C: C,
                            isDark: isDark,
                            onTap: () =>
                                setState(() => _selectedSoundId = s.id),
                            onPlay: () => _playSound(s),
                            onFavorite: () => _toggleFavorite(s),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKatFilter(AppColorsExtension C, bool isDark) {
    const chips = [
      (_KatFilter.all,       'Alle',      null),
      (_KatFilter.ambiente,  'Ambiente',  SoundType.Ambiente),
      (_KatFilter.effekt,    'Effekt',    SoundType.Effekt),
      (_KatFilter.favorites, 'Favoriten', null),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((t) {
          final active = _katFilter == t.$1;
          final cfg = t.$3 != null ? _kc[t.$3] : null;
          final activeColor = cfg?.color ?? C.accent;
          final activeBg = cfg != null
              ? cfg.bg(isDark)
              : (isDark
                  ? C.accent.withValues(alpha: 0.15)
                  : C.accentSoft);
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _katFilter = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? activeBg : Colors.transparent,
                  border: Border.all(
                      color: active ? activeColor : C.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? activeColor : C.textMid,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundsRight(
      BuildContext context, AppColorsExtension C, Sound? selected) {
    if (selected == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.music, size: 32, color: C.border),
            const SizedBox(height: 10),
            Text('Sound auswählen',
                style: TextStyle(fontSize: 14, color: C.textSoft)),
          ],
        ),
      );
    }
    return _SoundDetail(
      key: ValueKey(selected.id),
      sound: selected,
      player: _player,
      isPlaying: _playingId == selected.id && _isPlaying,
      C: C,
      onPlay: () => _playSound(selected),
      onStop: _stopPreview,
      onEdit: () => _openEditor(selected),
      onFavorite: () => _toggleFavorite(selected),
    );
  }
}

// ── _SoundRow ─────────────────────────────────────────────────────────────────

class _SoundRow extends StatefulWidget {
  const _SoundRow({
    required this.sound,
    required this.isSelected,
    required this.isPlaying,
    required this.C,
    required this.isDark,
    required this.onTap,
    required this.onPlay,
    required this.onFavorite,
  });

  final Sound sound;
  final bool isSelected;
  final bool isPlaying;
  final AppColorsExtension C;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;

  @override
  State<_SoundRow> createState() => _SoundRowState();
}

class _SoundRowState extends State<_SoundRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sound;
    final C = widget.C;
    final sel = widget.isSelected;
    final cfg = _cfg(s.soundType);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: sel
                ? C.bgActive
                : _hovered
                    ? C.bgHover
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                  color: sel ? cfg.color : Colors.transparent, width: 3),
              bottom: BorderSide(color: C.border, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(11, 9, 14, 9),
          child: Row(
            children: [
              // Play/pause circle
              GestureDetector(
                onTap: widget.onPlay,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cfg.color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon(
                      widget.isPlaying ? AppIconName.pause : AppIconName.play,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: C.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _KatBadge(
                            type: s.soundType,
                            isDark: widget.isDark),
                        const SizedBox(width: 6),
                        Text(
                          _fmtDuration(s.duration),
                          style: TextStyle(
                              fontSize: 10, color: C.textSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Favorite
              GestureDetector(
                onTap: widget.onFavorite,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Center(
                    child: AppIcon(
                      AppIconName.heart,
                      size: 13,
                      color: s.isFavorite ? C.red : C.textSoft,
                    ),
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

// ── _SoundDetail ──────────────────────────────────────────────────────────────

class _SoundDetail extends StatefulWidget {
  const _SoundDetail({
    super.key,
    required this.sound,
    required this.player,
    required this.isPlaying,
    required this.C,
    required this.onPlay,
    required this.onStop,
    required this.onEdit,
    required this.onFavorite,
  });

  final Sound sound;
  final AudioPlayer player;
  final bool isPlaying;
  final AppColorsExtension C;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final VoidCallback onEdit;
  final VoidCallback onFavorite;

  @override
  State<_SoundDetail> createState() => _SoundDetailState();
}

class _SoundDetailState extends State<_SoundDetail> {
  double _volume = 0.7;
  Duration _position = Duration.zero;
  Duration? _totalDuration;

  @override
  void initState() {
    super.initState();
    widget.player.setVolume(_volume);
    widget.player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    widget.player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
  }

  @override
  void didUpdateWidget(_SoundDetail old) {
    super.didUpdateWidget(old);
    // Reset position display when a different sound is selected but not playing
    if (old.sound.id != widget.sound.id && !widget.isPlaying) {
      setState(() { _position = Duration.zero; _totalDuration = null; });
    }
  }

  Future<void> _seek(double fraction, Duration? total) async {
    if (total == null) return;
    final target = Duration(milliseconds: (fraction * total.inMilliseconds).round());
    await widget.player.seek(target);
  }

  Future<void> _setVolume(double v) async {
    setState(() => _volume = v);
    await widget.player.setVolume(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sound;
    final C = widget.C;
    final cfg = _cfg(s.soundType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _totalDuration ?? s.duration;
    final fraction = (total != null && total.inMilliseconds > 0)
        ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cfg.bg(isDark),
              border: Border.all(color: cfg.color.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.15),
                    border: Border.all(
                        color: cfg.color.withValues(alpha: 0.3), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: AppIcon(AppIconName.music, size: 28,
                        color: cfg.color),
                  ),
                ),
                const SizedBox(height: 12),
                Text(s.name,
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: C.text),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                _KatBadge(type: s.soundType, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Progress bar ────────────────────────────────────────
          GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              // Width of the progress track = full widget width - 2*20 padding
              final trackWidth = box.size.width - 40;
              final f = (d.localPosition.dx / trackWidth).clamp(0.0, 1.0);
              _seek(f, total);
            },
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: C.border,
                    valueColor: AlwaysStoppedAnimation(cfg.color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtDuration(_position),
                        style: TextStyle(fontSize: 10, color: C.textSoft)),
                    Text(_fmtDuration(total),
                        style: TextStyle(fontSize: 10, color: C.textSoft)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Play controls ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CtrlBtn(
                icon: AppIconName.stop,
                color: C.textSoft,
                onTap: widget.onStop,
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: widget.onPlay,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cfg.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: cfg.color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: AppIcon(
                      widget.isPlaying ? AppIconName.pause : AppIconName.play,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _CtrlBtn(
                icon: AppIconName.refresh,
                color: C.textSoft,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Volume ─────────────────────────────────────────────
          Row(
            children: [
              AppIcon(
                _volume == 0
                    ? AppIconName.volumeOff
                    : AppIconName.volume,
                size: 13,
                color: C.textSoft,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12),
                    activeTrackColor: C.accent,
                    inactiveTrackColor: C.border,
                    thumbColor: C.accent,
                    overlayColor: C.accent.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: _setVolume,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(_volume * 100).round()}%',
                  style: TextStyle(fontSize: 10, color: C.textSoft)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Actions ────────────────────────────────────────────
          _SectionLabel('Aktionen', C),
          const SizedBox(height: 8),
          _ActionBtn(
            icon: AppIconName.heart,
            label: s.isFavorite
                ? 'Von Favoriten entfernen'
                : 'Als Favorit markieren',
            C: C,
            onTap: widget.onFavorite,
          ),
          const SizedBox(height: 6),
          _ActionBtn(
            icon: AppIconName.edit,
            label: 'Bearbeiten',
            C: C,
            onTap: widget.onEdit,
          ),
          if (s.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('Beschreibung', C),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.bgPanel,
                border: Border.all(color: C.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.description,
                  style: TextStyle(
                      fontSize: 12, color: C.textMid, height: 1.6)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _KatBadge extends StatelessWidget {
  const _KatBadge({required this.type, required this.isDark});

  final SoundType type;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.bg(isDark),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.name,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: cfg.color),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.C,
    required this.onTap,
  });

  final String label;
  final AppIconName icon;
  final bool active;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? C.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            AppIcon(icon, size: 14,
                color: active ? C.accent : C.textMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.w500 : FontWeight.w400,
                color: active ? C.accent : C.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.ctrl, required this.hint, required this.C});

  final TextEditingController ctrl;
  final String hint;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          AppIcon(AppIconName.search, size: 13, color: C.textSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: TextStyle(fontSize: 12, color: C.text),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (ctrl.text.isNotEmpty) ...[
            GestureDetector(
              onTap: ctrl.clear,
              child: AppIcon(AppIconName.close, size: 12,
                  color: C.textSoft),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList(
      {required this.icon, required this.label, required this.C});

  final AppIconName icon;
  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 28, color: C.border),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(fontSize: 13, color: C.textSoft)),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn(
      {required this.icon, required this.color, required this.onTap});

  final AppIconName icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Center(child: AppIcon(icon, size: 15, color: color)),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.C,
    required this.onTap,
  });

  final AppIconName icon;
  final String label;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? C.bgActive : C.bgHover,
            border: Border.all(color: C.border),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              AppIcon(widget.icon, size: 13, color: C.textSoft),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(fontSize: 12, color: C.textMid)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.C);

  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: C.textSoft,
          letterSpacing: 0.4),
    );
  }
}

// ── _IconBtn ──────────────────────────────────────────────────────────────────

class _IconBtn extends StatefulWidget {
  const _IconBtn(
      {required this.C, required this.icon, required this.onTap});

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
                color: _hovered ? widget.C.border : Colors.transparent),
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

