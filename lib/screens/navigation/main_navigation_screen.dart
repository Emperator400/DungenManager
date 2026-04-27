import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/session_model_repository.dart';
import '../../models/campaign.dart';
import '../../models/player_character.dart';
import '../../models/session.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/session_list_for_campaign_viewmodel.dart';
import '../../widgets/campaign/campaign_edit_modal_widget.dart';
import '../../utils/color_utils.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import '../../widgets/ui_components/shared/app_logo.dart';

import '../characters/edit_pc_screen.dart';
import '../campaign/session_list_for_campaign_screen.dart';
import '../session/edit_session_screen.dart';

// Klassenfarben nach JSX-Vorlage
const Map<String, Color> _klasseColor = {
  'Barbar':      Color(0xFFC93A3A),
  'Barde':       Color(0xFF7C3AED),
  'Kleriker':    Color(0xFFD4890A),
  'Druide':      Color(0xFF1A7F4B),
  'Kämpfer':     Color(0xFF6B6B66),
  'Mönch':       Color(0xFF0891B2),
  'Paladin':     Color(0xFF2F6FEB),
  'Waldläufer':  Color(0xFF065F46),
  'Schurke':     Color(0xFF4A4A4A),
  'Zauberer':    Color(0xFFBE185D),
  'Hexenmeister':Color(0xFF4A235A),
  'Magier':      Color(0xFF1B4F72),
};

Color _colorForClass(String className, Color fallback) =>
    _klasseColor.entries
        .firstWhere(
          (e) => className.toLowerCase().contains(e.key.toLowerCase()),
          orElse: () => MapEntry('', fallback),
        )
        .value;

String _formatDate(DateTime? d) =>
    d == null ? '' : '${d.day}.${d.month}.${d.year}';

// ── SCREEN ────────────────────────────────────────────────────────────────────

class EnhancedMainNavigationScreen extends StatefulWidget {
  const EnhancedMainNavigationScreen({super.key, this.campaign});

  final Campaign? campaign;

  @override
  State<EnhancedMainNavigationScreen> createState() =>
      _EnhancedMainNavigationScreenState();
}

class _EnhancedMainNavigationScreenState
    extends State<EnhancedMainNavigationScreen> {
  late final PlayerCharacterModelRepository _heroRepo;
  late final SessionModelRepository _sessionRepo;

  List<PlayerCharacter> _heroes = [];
  List<Session> _sessions = [];
  bool _loadingHeroes = true;
  bool _loadingSessions = true;

  @override
  void initState() {
    super.initState();
    _heroRepo = PlayerCharacterModelRepository(DatabaseConnection.instance);
    _sessionRepo = SessionModelRepository(DatabaseConnection.instance);
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.campaign == null) return;
    await Future.wait([_loadHeroes(), _loadSessions()]);
  }

  Future<void> _loadHeroes() async {
    setState(() => _loadingHeroes = true);
    try {
      final heroes = await _heroRepo.findByCampaign(widget.campaign!.id);
      if (mounted) setState(() { _heroes = heroes; _loadingHeroes = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHeroes = false);
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final sessions = await _sessionRepo.findByCampaign(widget.campaign!.id);
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() { _sessions = sessions; _loadingSessions = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  void _goToHero(PlayerCharacter? hero) {
    final campaign = widget.campaign;
    if (campaign == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => EditPCScreen(
            campaignId: campaign.id,
            pcToEdit: hero,
          ),
        ))
        .then((_) => _loadHeroes());
  }

  void _goToSession(Session? session) {
    final campaign = widget.campaign;
    if (campaign == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => EditSessionScreen(
            session: session,
            isNewSession: session == null,
          ),
        ))
        .then((_) => _loadSessions());
  }

  void _goToSessionList() {
    final campaign = widget.campaign;
    if (campaign == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<SessionListForCampaignViewModel>(
            create: (_) => SessionListForCampaignViewModel(),
            child: SessionListForCampaignScreen(campaign: campaign),
          ),
        ))
        .then((_) => _loadSessions());
  }

  void _goToEditCampaign() {
    final campaign = widget.campaign;
    if (campaign == null) return;
    CampaignEditModal.show(context, campaign: campaign);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          _TopBar(campaign: widget.campaign, C: C, onEdit: _goToEditCampaign),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session starten
                  if (widget.campaign != null) ...[
                    _SessionStartBanner(C: C, onTap: _goToSessionList),
                    const SizedBox(height: 28),
                  ],

                  // Helden
                  if (widget.campaign != null) ...[
                    _SectionHeader(
                      title: 'Helden',
                      subtitle: '${_heroes.length} Charakter${_heroes.length != 1 ? "e" : ""} in dieser Kampagne',
                      actionLabel: 'Held hinzufügen',
                      onAction: () => _goToHero(null),
                      C: C,
                    ),
                    const SizedBox(height: 12),
                    _HeroGrid(
                      heroes: _heroes,
                      loading: _loadingHeroes,
                      C: C,
                      onTap: _goToHero,
                      onAdd: () => _goToHero(null),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Sessions
                  if (widget.campaign != null) ...[
                    _SectionHeader(
                      title: 'Sessions',
                      subtitle: '${_sessions.length} Session${_sessions.length != 1 ? "s" : ""}',
                      actionLabel: 'Session hinzufügen',
                      onAction: () => _goToSession(null),
                      C: C,
                    ),
                    const SizedBox(height: 12),
                    _SessionList(
                      sessions: _sessions,
                      loading: _loadingSessions,
                      C: C,
                      onTap: _goToSession,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.campaign, required this.C, required this.onEdit});

  final Campaign? campaign;
  final AppColorsExtension C;
  final VoidCallback onEdit;

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
                  _IconBtn(
                    C: C,
                    icon: AppIconName.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 18, color: C.border),
                  const SizedBox(width: 10),

                  if (campaign != null) ...[
                    _CampaignAvatar(campaign: campaign!, size: 22, C: C),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            campaign!.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (campaign!.system.isNotEmpty)
                            Text(
                              campaign!.system,
                              style: TextStyle(fontSize: 11, color: C.textSoft),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const AppLogo(size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dungeon Manager',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                      ),
                    ),
                  ],

                  if (campaign != null) ...[
                    _StatusBadge(campaign: campaign!, C: C),
                    const SizedBox(width: 4),
                    _IconBtn(C: C, icon: AppIconName.edit, onTap: onEdit),
                    const SizedBox(width: 4),
                  ],

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

// ── SESSION START BANNER ──────────────────────────────────────────────────────

class _SessionStartBanner extends StatelessWidget {
  const _SessionStartBanner({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const AppIcon(AppIconName.play, size: 15, color: Colors.white),
        label: const Text('Session starten'),
        style: FilledButton.styleFrom(
          backgroundColor: C.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── SECTION HEADER ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.C,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: C.textSoft)),
            ],
          ),
        ),
        _OutlineBtn(label: actionLabel, C: C, onTap: onAction),
      ],
    );
  }
}

// ── HERO GRID ─────────────────────────────────────────────────────────────────

class _HeroGrid extends StatelessWidget {
  const _HeroGrid({
    required this.heroes,
    required this.loading,
    required this.C,
    required this.onTap,
    required this.onAdd,
  });

  final List<PlayerCharacter> heroes;
  final bool loading;
  final AppColorsExtension C;
  final void Function(PlayerCharacter) onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator(color: C.accent, strokeWidth: 2)),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...heroes.map((h) => SizedBox(
          width: _cardWidth(context),
          child: _HeroCard(hero: h, C: C, onTap: () => onTap(h)),
        )),
        SizedBox(
          width: _cardWidth(context),
          child: _AddHeroCard(C: C, onTap: onAdd),
        ),
      ],
    );
  }

  double _cardWidth(BuildContext context) {
    final available = MediaQuery.of(context).size.width - 40;
    if (available >= 600) return (available - 30) / 4;
    if (available >= 400) return (available - 20) / 3;
    return (available - 10) / 2;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hero, required this.C, required this.onTap});

  final PlayerCharacter hero;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForClass(hero.className, C.accent);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farbstreifen
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.13),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            hero.name.isNotEmpty ? hero.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AppIcon(AppIconName.chevronRight, size: 12, color: C.textSoft),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hero.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lvl ${hero.level} · ${hero.className}',
                    style: TextStyle(fontSize: 11, color: C.textMid),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: C.bgHover,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(AppIconName.user, size: 10, color: C.textSoft),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hero.playerName,
                            style: TextStyle(fontSize: 11, color: C.textSoft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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

class _AddHeroCard extends StatelessWidget {
  const _AddHeroCard({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          border: Border.all(color: C.border, width: 1.5, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            AppIcon(AppIconName.plus, size: 18, color: C.textSoft),
            const SizedBox(height: 6),
            Text('Neuer Held', style: TextStyle(fontSize: 11, color: C.textSoft)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── SESSION LIST ──────────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.sessions,
    required this.loading,
    required this.C,
    required this.onTap,
  });

  final List<Session> sessions;
  final bool loading;
  final AppColorsExtension C;
  final void Function(Session) onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: C.accent, strokeWidth: 2)),
      );
    }

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('Noch keine Sessions', style: TextStyle(fontSize: 13, color: C.textSoft)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sessions.length; i++)
            _SessionRow(
              session: sessions[i],
              C: C,
              isLast: i == sessions.length - 1,
              onTap: () => onTap(sessions[i]),
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.C,
    required this.isLast,
    required this.onTap,
  });

  final Session session;
  final AppColorsExtension C;
  final bool isLast;
  final VoidCallback onTap;

  bool get _isActive => session.startedAt != null && session.completedAt == null;
  bool get _isDone => session.completedAt != null;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : Radius.zero,
        bottom: isLast ? const Radius.circular(10) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: C.border)),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isActive ? C.green : (_isDone ? C.textSoft : C.amber),
                boxShadow: _isActive
                    ? [BoxShadow(color: C.green.withValues(alpha: 0.5), blurRadius: 5)]
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  fontSize: 13,
                  color: C.text,
                  fontWeight: _isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Datum
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIconName.calendar, size: 11, color: C.textSoft),
                const SizedBox(width: 4),
                Text(
                  _formatDate(session.startedAt ?? session.createdAt),
                  style: TextStyle(fontSize: 11, color: C.textSoft),
                ),
              ],
            ),

            // Aktiv-Badge
            if (_isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: C.greenSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Aktiv', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: C.green)),
              ),
            ],

            const SizedBox(width: 8),
            AppIcon(AppIconName.chevronRight, size: 12, color: C.textSoft),
          ],
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.C, required this.onTap});

  final String label;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.plus, size: 13, color: C.textMid),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.textMid)),
          ],
        ),
      ),
    );
  }
}

class _CampaignAvatar extends StatelessWidget {
  const _CampaignAvatar({required this.campaign, required this.size, required this.C});

  final Campaign campaign;
  final double size;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(campaign.accentColor) ?? C.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          campaign.title.isNotEmpty ? campaign.title[0].toUpperCase() : '?',
          style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.campaign, required this.C});

  final Campaign campaign;
  final AppColorsExtension C;

  static const _labels = <CampaignStatus, String>{
    CampaignStatus.planning:   'Planung',
    CampaignStatus.active:     'Aktiv',
    CampaignStatus.paused:     'Pausiert',
    CampaignStatus.completed:  'Abgeschlossen',
    CampaignStatus.cancelled:  'Abgebrochen',
  };

  static const _colors = <CampaignStatus, Color>{
    CampaignStatus.planning:   Color(0xFF7C3AED),
    CampaignStatus.active:     Color(0xFF1A7F4B),
    CampaignStatus.paused:     Color(0xFFB45309),
    CampaignStatus.completed:  Color(0xFF6B6B66),
    CampaignStatus.cancelled:  Color(0xFFC93A3A),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[campaign.status] ?? C.textSoft;
    final label = _labels[campaign.status] ?? campaign.status.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
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
            width: 30,
            height: 30,
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
