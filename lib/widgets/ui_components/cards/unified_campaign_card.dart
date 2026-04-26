import 'package:flutter/material.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/campaign_viewmodel.dart';
import '../../../widgets/ui_components/shared/app_icon.dart';
import '../base/unified_card_base.dart';

class UnifiedCampaignCard extends UnifiedCardBase {
  const UnifiedCampaignCard({
    required this.campaign,
    required this.viewModel,
    super.key,
    this.onNavigate,
    super.onEdit,
    this.onDuplicate,
    super.onToggleFavorite,
    super.isSelected,
  });

  final Campaign campaign;
  final CampaignViewModel viewModel;
  final VoidCallback? onNavigate;
  final VoidCallback? onDuplicate;

  @override
  Widget buildCardContent(BuildContext context) =>
      _CampaignCardContent(card: this);
}

// ── CARD CONTENT (StatefulWidget für Hover) ───────────────────────────────────

class _CampaignCardContent extends StatefulWidget {
  const _CampaignCardContent({required this.card});

  final UnifiedCampaignCard card;

  @override
  State<_CampaignCardContent> createState() => _CampaignCardContentState();
}

class _CampaignCardContentState extends State<_CampaignCardContent> {
  bool _hovered = false;

  UnifiedCampaignCard get c => widget.card;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final stats = c.viewModel.getStatsForCampaign(c.campaign.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: c.onNavigate ?? c.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? C.bgHover : C.bgPanel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farbstreifen
              Container(height: 3, color: C.accent),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        _Avatar(
                          letter: c.campaign.title.isNotEmpty
                              ? c.campaign.title[0].toUpperCase()
                              : '?',
                          color: C.accent,
                          bg: C.accentSoft,
                        ),
                        const SizedBox(width: 10),
                        // Titel + Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.campaign.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: C.text,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _StatusBadge(
                                status: c.campaign.statusDescription,
                                C: C,
                              ),
                            ],
                          ),
                        ),
                        // Aktionen (bei Hover)
                        if (_hovered) ...[
                          _IconBtn(
                            C: C,
                            icon: AppIconName.edit,
                            onTap: c.onEdit,
                          ),
                          const SizedBox(width: 2),
                          _PopupBtn(card: c, C: C),
                        ],
                      ],
                    ),

                    // Beschreibung
                    if (c.campaign.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.campaign.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: C.textMid,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Meta-Zeile
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MetaChip(
                          icon: AppIconName.user,
                          value: '${stats['heroCount'] ?? 0}',
                          C: C,
                        ),
                        const SizedBox(width: 10),
                        _MetaChip(
                          icon: AppIconName.play,
                          value: '${stats['sessionCount'] ?? 0}',
                          C: C,
                        ),
                        const SizedBox(width: 10),
                        _MetaChip(
                          icon: AppIconName.scroll,
                          value: '${stats['questCount'] ?? 0}',
                          C: C,
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(c.campaign.createdAt),
                          style: TextStyle(fontSize: 10, color: C.textSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── POPUP MENU ────────────────────────────────────────────────────────────────

class _PopupBtn extends StatelessWidget {
  const _PopupBtn({required this.card, required this.C});

  final UnifiedCampaignCard card;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: '',
        color: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: C.border),
        ),
        offset: const Offset(0, 30),
        onSelected: (v) => _handle(context, v),
        itemBuilder: (_) => [
          _item('duplicate', AppIconName.copy, 'Duplizieren', C),
          _item('delete', AppIconName.trash, 'Löschen', C, color: C.red),
        ],
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.bgHover,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: AppIcon(AppIconName.dots, size: 12, color: C.textSoft),
          ),
        ),
      );

  PopupMenuItem<String> _item(
    String value,
    AppIconName icon,
    String label,
    AppColorsExtension C, {
    Color? color,
  }) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            AppIcon(icon, size: 13, color: color ?? C.textMid),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color ?? C.text),
            ),
          ],
        ),
      );

  void _handle(BuildContext context, String action) {
    switch (action) {
      case 'duplicate':
        card.onDuplicate?.call();
      case 'delete':
        _showDeleteDialog(context);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(title: card.campaign.title, C: C),
    );
    if ((confirmed ?? false) && context.mounted) {
      try {
        await card.viewModel.deleteCampaign(card.campaign);
      } catch (_) {}
    }
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.title, required this.C});

  final String title;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Dialog(
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
                'Kampagne löschen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: C.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Möchtest du "$title" wirklich löschen? '
                'Diese Aktion kann nicht rückgängig gemacht werden.',
                style: TextStyle(fontSize: 13, color: C.textMid),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: C.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(color: C.textMid, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: C.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text('Löschen', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── HILFSWIDGETS ──────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.letter,
    required this.color,
    required this.bg,
  });

  final String letter;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.C});

  final String status;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final fg = _fg();
    final bg = _bg();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  Color _fg() {
    final s = status.toLowerCase();
    if (s.contains('aktiv')) {
      return C.green;
    }
    if (s.contains('archiv')) {
      return C.textSoft;
    }
    return C.amber;
  }

  Color _bg() {
    final s = status.toLowerCase();
    if (s.contains('aktiv')) {
      return C.greenSoft;
    }
    if (s.contains('archiv')) {
      return C.bgHover;
    }
    return C.amberSoft;
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.value, required this.C});

  final AppIconName icon;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 11, color: C.textSoft),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(fontSize: 11, color: C.textSoft),
          ),
        ],
      );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.C, required this.icon, this.onTap});

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.bgActive,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: AppIcon(icon, size: 12, color: C.textSoft),
          ),
        ),
      );
}

String _formatDate(DateTime date) =>
    '${date.day}.${date.month}.${date.year}';
