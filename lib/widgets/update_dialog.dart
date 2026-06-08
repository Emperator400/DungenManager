import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../viewmodels/update_viewmodel.dart';

Future<bool> showUpdateDialogIfNeeded(
  BuildContext context, {
  bool forceShow = false,
}) async {
  final viewModel = context.read<UpdateViewModel>();

  if (!forceShow) {
    if (viewModel.userNotified) {
      return false;
    }
    if (!viewModel.hasUpdateAvailable || viewModel.availableUpdate == null) {
      return false;
    }
  } else {
    if (viewModel.availableUpdate == null) {
      return false;
    }
  }

  viewModel.markUserNotified();

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpdateDialog(),
      ) ??
      false;
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Consumer<UpdateViewModel>(
      builder: (context, vm, _) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: C.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(C, vm),
                const SizedBox(height: 16),
                if (vm.availableUpdate == null)
                  _buildNoUpdateBody(C)
                else ...[
                  _buildVersionRow(C, vm),
                  const SizedBox(height: 12),
                  if (vm.isDownloading || vm.isExtracting || vm.isBackingUp || vm.isReady)
                    _buildProgress(C, vm)
                  else ...[
                    if (vm.hasError && vm.errorMessage != null) _buildError(C, vm),
                    _buildReleaseNotes(C, vm),
                  ],
                ],
                const SizedBox(height: 20),
                _buildActions(C, vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension C, UpdateViewModel vm) => Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: C.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.system_update_alt_outlined, size: 16, color: C.accent),
        ),
        const SizedBox(width: 10),
        Text(
          vm.availableUpdate != null ? 'Update verfügbar' : 'Fehler',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Icon(Icons.close, size: 18, color: C.textSoft),
        ),
      ],
    );

  Widget _buildNoUpdateBody(AppColorsExtension C) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Kein Update verfügbar oder Fehler beim Laden.',
          style: TextStyle(color: C.textMid),
        ),
      );

  Widget _buildVersionRow(AppColorsExtension C, UpdateViewModel vm) {
    final update = vm.availableUpdate!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Text(
            'Aktuell: ${vm.currentVersion.displayVersion}',
            style: TextStyle(fontSize: 12, color: C.textSoft),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward, size: 14, color: C.textSoft),
          const SizedBox(width: 8),
          Text(
            update.displayVersion,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.green),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(AppColorsExtension C, UpdateViewModel vm) {
    final label = vm.isBackingUp
        ? 'Daten werden gesichert...'
        : vm.isDownloading
            ? 'Wird heruntergeladen...'
            : vm.isExtracting
                ? 'Wird entpackt...'
                : 'Wird installiert...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: C.accent),
              ),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 12, color: C.accent)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (vm.isDownloading && !vm.isTotalSizeKnown) ? null : vm.progress,
              backgroundColor: C.border,
              valueColor: AlwaysStoppedAnimation(C.accent),
              minHeight: 4,
            ),
          ),
          if (vm.isDownloading) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${vm.downloadedMb} / ${vm.totalMb}',
                style: TextStyle(fontSize: 11, color: C.textSoft),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(AppColorsExtension C, UpdateViewModel vm) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.red.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: C.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vm.errorMessage!,
                style: TextStyle(fontSize: 12, color: C.red),
              ),
            ),
          ],
        ),
      );

  Widget _buildReleaseNotes(AppColorsExtension C, UpdateViewModel vm) {
    final update = vm.availableUpdate!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: Container(
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    update.displayVersion,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                  ),
                  if (update.isPrerelease) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: C.accentSoft,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: C.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Pre-Release',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: C.accent),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: C.textSoft),
                  const SizedBox(width: 4),
                  Text(
                    'Veröffentlicht: ${update.formattedDate}',
                    style: TextStyle(fontSize: 11, color: C.textSoft),
                  ),
                ],
              ),
              Divider(height: 20, color: C.border),
              MarkdownBody(
                data: update.releaseNotes.isNotEmpty
                    ? update.releaseNotes
                    : '*Keine Release-Notes verfügbar.*',
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: C.textMid, fontSize: 13),
                  h1: TextStyle(color: C.text, fontSize: 18, fontWeight: FontWeight.w600),
                  h2: TextStyle(color: C.text, fontSize: 16, fontWeight: FontWeight.w600),
                  h3: TextStyle(color: C.text, fontSize: 14, fontWeight: FontWeight.w600),
                  listBullet: TextStyle(color: C.textMid),
                  code: TextStyle(color: C.accent, backgroundColor: C.bgActive, fontFamily: 'monospace'),
                  codeblockDecoration: BoxDecoration(
                    color: C.bgActive,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  strong: TextStyle(color: C.text, fontWeight: FontWeight.bold),
                  em: TextStyle(color: C.textMid, fontStyle: FontStyle.italic),
                ),
                selectable: true,
                onTapLink: (_, href, __) {
                  if (href != null) vm.openReleasesPage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(AppColorsExtension C, UpdateViewModel vm) {
    // Laufend: nur Abbrechen anbieten (außer Backup + Extraktion — zu kurz)
    if (vm.isBackingUp || vm.isExtracting) {
      return _btn(C, 'Bitte warten...', C.textSoft, null, filled: false);
    }

    if (vm.isDownloading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _btn(C, 'Abbrechen', C.textSoft, vm.cancelDownload, filled: false),
        ],
      );
    }

    // isReady → passiert nur noch kurz bevor installAndRestart die App beendet
    if (vm.isReady) {
      return _btn(C, 'Installiere...', C.textSoft, null, filled: false);
    }

    if (vm.hasError) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _btn(C, 'Schließen', C.textSoft, () => Navigator.of(context).pop(false), filled: false),
          const SizedBox(width: 8),
          _btn(C, 'Erneut versuchen', Colors.white, vm.retryAndInstall,
              icon: Icons.refresh, bgColor: C.amber),
          const SizedBox(width: 8),
          _btn(C, 'GitHub öffnen', Colors.white, () => vm.openReleasesPage(),
              icon: Icons.open_in_browser, bgColor: C.accent),
        ],
      );
    }

    if (vm.availableUpdate == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: _btn(C, 'Schließen', C.textSoft, () => Navigator.of(context).pop(false), filled: false),
      );
    }

    // Hauptfall: Update verfügbar → ein einziger Button
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _btn(C, 'Später', C.textSoft, () => Navigator.of(context).pop(false), filled: false),
        const SizedBox(width: 8),
        _btn(
          C,
          'Jetzt aktualisieren',
          Colors.white,
          () => vm.downloadAndInstall(),
          icon: Icons.system_update_alt_outlined,
          bgColor: C.accent,
        ),
      ],
    );
  }

  Widget _btn(
    AppColorsExtension C,
    String label,
    Color textColor,
    VoidCallback? onTap, {
    bool filled = true,
    Color? bgColor,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? (bgColor ?? C.accent) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: filled ? null : Border.all(color: C.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: textColor), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 13, color: textColor)),
          ],
        ),
      ),
    );
  }

}
