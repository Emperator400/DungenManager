import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/dnd_theme.dart';
import '../../../utils/color_utils.dart';
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
    this.onUseCopy,
    this.onExport,
    super.onToggleFavorite,
    super.isSelected,
  });

  final Campaign campaign;
  final CampaignViewModel viewModel;
  final VoidCallback? onNavigate;
  final VoidCallback? onDuplicate;
  final VoidCallback? onUseCopy;
  final VoidCallback? onExport;

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
  bool _popupOpen = false;

  UnifiedCampaignCard get c => widget.card;

  void _onPopupOpenState({required bool isOpen}) {
    if (mounted) {
      setState(() => _popupOpen = isOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final stats = c.viewModel.getStatsForCampaign(c.campaign.id);
    final cardColor = ColorUtils.fromHex(c.campaign.accentColor) ?? C.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: c.onNavigate ?? c.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? C.bgHover : C.bgPanel,
          child: Row(
            children: [
              // Farbstreifen
              Container(width: 3, height: 52, color: cardColor),
              const SizedBox(width: 10),
              // Avatar
              _Avatar(
                letter: c.campaign.title.isNotEmpty ? c.campaign.title[0].toUpperCase() : '?',
                color: cardColor,
                bg: cardColor.withValues(alpha: 0.15),
                coverImagePath: c.campaign.coverImagePath,
              ),
              const SizedBox(width: 10),
              // Titel + Meta
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zeile 1: Titel + Badges
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.campaign.title,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: c.campaign.statusDescription, C: C),
                          if (c.campaign.isTemplate) ...[const SizedBox(width: 4), _TemplateBadge(C: C)],
                          if (c.campaign.templateId != null) ...[const SizedBox(width: 4), _CopyBadge(C: C)],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Zeile 2: Meta
                      Row(
                        children: [
                          _MetaChip(icon: AppIconName.user,   value: '${stats['heroCount'] ?? 0}',    C: C),
                          const SizedBox(width: 8),
                          _MetaChip(icon: AppIconName.play,   value: '${stats['sessionCount'] ?? 0}', C: C),
                          const SizedBox(width: 8),
                          _MetaChip(icon: AppIconName.scroll, value: '${stats['questCount'] ?? 0}',   C: C),
                          const Spacer(),
                          _CloudStatusIcon(
                            isSynced: c.viewModel.isSynced(c.campaign.id),
                            isPending: c.viewModel.isPendingSync(c.campaign.id),
                            isDownloaded: c.viewModel.isDownloadedFromCloud(c.campaign.id),
                            isSyncDisabled: !c.campaign.syncEnabled,
                            C: C,
                          ),
                          Text(_formatDate(c.campaign.createdAt), style: TextStyle(fontSize: 10, color: C.textSoft)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Aktionen (bei Hover)
              if (_hovered || _popupOpen) ...[
                _IconBtn(C: C, icon: AppIconName.edit, onTap: c.onEdit),
                const SizedBox(width: 2),
                _PopupBtn(card: c, C: C, onOpenStateChanged: _onPopupOpenState),
                const SizedBox(width: 6),
              ] else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── POPUP MENU ────────────────────────────────────────────────────────────────

class _PopupBtn extends StatelessWidget {
  const _PopupBtn({
    required this.card,
    required this.C,
    this.onOpenStateChanged,
  });

  final UnifiedCampaignCard card;
  final AppColorsExtension C;
  final void Function({required bool isOpen})? onOpenStateChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: '',
        color: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: C.border),
        ),
        offset: const Offset(0, 30),
        onOpened: () => onOpenStateChanged?.call(isOpen: true),
        onSelected: (v) {
          onOpenStateChanged?.call(isOpen: false);
          _handle(context, v);
        },
        onCanceled: () => onOpenStateChanged?.call(isOpen: false),
        itemBuilder: (_) => [
          if (card.onUseCopy != null)
            _item('use_copy', AppIconName.copy, 'Als Kopie verwenden', C)
          else
            _item('duplicate', AppIconName.copy, 'Duplizieren', C),
          if (card.onExport != null)
            _item('export', AppIconName.upload, 'Exportieren', C),
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
      case 'use_copy':
        card.onUseCopy?.call();
      case 'export':
        card.onExport?.call();
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
    this.coverImagePath,
  });

  final String letter;
  final Color color;
  final Color bg;
  final String? coverImagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = coverImagePath != null && File(coverImagePath!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: hasImage
          ? SizedBox(
              width: 28,
              height: 28,
              child: Image.file(File(coverImagePath!), fit: BoxFit.cover),
            )
          : Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: color.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
    );
  }
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

class _CloudStatusIcon extends StatelessWidget {
  const _CloudStatusIcon({
    required this.isSynced,
    required this.isPending,
    required this.isDownloaded,
    required this.isSyncDisabled,
    required this.C,
  });

  final bool isSynced;
  final bool isPending;
  final bool isDownloaded;
  final bool isSyncDisabled;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    if (isSyncDisabled) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Tooltip(
          message: 'Sync deaktiviert',
          child: Icon(Icons.cloud_off_outlined, size: 12, color: C.textSoft.withValues(alpha: 0.4)),
        ),
      );
    }
    if (isPending) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: C.textSoft),
        ),
      );
    }
    if (isDownloaded) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Tooltip(
          message: 'Aus Cloud synchronisiert',
          child: Icon(Icons.cloud_download_outlined, size: 12, color: DnDTheme.infoBlue),
        ),
      );
    }
    if (isSynced) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Tooltip(
          message: 'Synchronisiert',
          child: Icon(Icons.cloud_done_outlined, size: 12, color: C.textSoft),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── TEMPLATE / COPY BADGES ────────────────────────────────────────────────────

class _TemplateBadge extends StatelessWidget {
  const _TemplateBadge({required this.C});
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: C.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: C.accent.withValues(alpha: 0.25)),
        ),
        child: Text(
          'Vorlage',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: C.accent,
          ),
        ),
      );
}

class _CopyBadge extends StatelessWidget {
  const _CopyBadge({required this.C});
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: C.textSoft.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: C.border),
        ),
        child: Text(
          'Kopie',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: C.textMid,
          ),
        ),
      );
}

