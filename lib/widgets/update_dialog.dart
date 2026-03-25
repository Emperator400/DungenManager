/// Update Dialog Widget
/// 
/// Zeigt einen Dialog an wenn ein Update verfügbar ist.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../viewmodels/update_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Zeigt den Update-Dialog an wenn ein Update verfügbar ist
Future<bool> showUpdateDialogIfNeeded(
  BuildContext context, {
  bool forceShow = false,
}) async {
  final viewModel = context.read<UpdateViewModel>();
  
  // Bei forceShow immer anzeigen, sonst nur wenn Update verfügbar und User noch nicht benachrichtigt
  if (!forceShow) {
    if (viewModel.userNotified) {
      return false;
    }
    
    if (!viewModel.hasUpdateAvailable || viewModel.availableUpdate == null) {
      return false;
    }
  } else {
    // Bei forceShow: Nur anzeigen wenn ein Update verfügbar ist
    if (viewModel.availableUpdate == null) {
      return false;
    }
  }

  viewModel.markUserNotified();
  
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpdateDialog(),
  ) ?? false;
}

/// Update Dialog
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateViewModel>(
      builder: (context, viewModel, child) {
        // Prüfe ob ein Update verfügbar ist (availableUpdate != null)
        if (viewModel.availableUpdate == null) {
          return AlertDialog(
            backgroundColor: DnDTheme.slateGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DnDTheme.ancientGold, width: 2),
            ),
            title: const Text(
              'Fehler',
              style: TextStyle(color: DnDTheme.errorRed),
            ),
            content: const Text(
              'Kein Update verfügbar oder Fehler beim Laden.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Schließen', style: TextStyle(color: Color.fromARGB(255, 145, 100, 48))),
              ),
            ],
          );
        }
        
        return AlertDialog(
          backgroundColor: DnDTheme.slateGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: DnDTheme.ancientGold, width: 2),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.system_update_alt,
                color: DnDTheme.ancientGold,
              ),
              SizedBox(width: 12),
              const Text(
                'Update verfügbar',
                style: TextStyle(color: DnDTheme.ancientGold),
              ),
            ],
          ),
          content: _buildContent(viewModel),
          actions: _buildActions(viewModel),
        );
      },
    );
  }

  Widget _buildContent(UpdateViewModel viewModel) {
    final update = viewModel.availableUpdate;
    
    if (update == null) {
      return const Text(
        'Kein Update verfügbar',
        style: TextStyle(color: Colors.white70),
      );
    }

    return SizedBox(
      width: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DnDTheme.dungeonBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Aktuell: ${viewModel.currentVersion.displayVersion}',
                  style: const TextStyle(color: DnDTheme.charcoalGrey),
                ),
                const Spacer(),
                Text(
                  'Neu: ${update.displayVersion}',
                  style: const TextStyle(
                    color: DnDTheme.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status-Anzeige
          if (viewModel.isDownloading || viewModel.isExtracting)
            _buildProgressIndicator(viewModel),

          // Fehlermeldung
          if (viewModel.hasError && viewModel.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: DnDTheme.errorRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: DnDTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),

          // Erfolgsanzeige
          if (viewModel.isReady)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DnDTheme.emeraldGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: DnDTheme.emeraldGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Update heruntergeladen und entpackt!',
                    style: TextStyle(color: DnDTheme.emeraldGreen),
                  ),
                ],
              ),
            ),

          // Release Notes - immer anzeigen
          if (!viewModel.isDownloading && !viewModel.isExtracting)
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  border: Border.all(color: DnDTheme.charcoalGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Release Header mit Version, Datum und Pre-Release Badge
                      Row(
                        children: [
                          Text(
                            update.displayVersion,
                            style: const TextStyle(
                              color: DnDTheme.ancientGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (update.isPrerelease)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: DnDTheme.arcaneBlue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: DnDTheme.arcaneBlue),
                              ),
                              child: const Text(
                                'Pre-Release',
                                style: TextStyle(
                                  color: DnDTheme.arcaneBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: DnDTheme.charcoalGrey),
                          const SizedBox(width: 6),
                          Text(
                            'Veröffentlicht: ${update.formattedDate}',
                            style: const TextStyle(
                              color: DnDTheme.charcoalGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: DnDTheme.charcoalGrey, height: 1),
                      const SizedBox(height: 12),
                      // Release Notes Inhalt
                      MarkdownBody(
                        data: update.releaseNotes.isNotEmpty 
                            ? update.releaseNotes 
                            : '*Keine Release-Notes verfügbar.*\n\nWeitere Informationen finden Sie auf der [GitHub Releases Seite](https://github.com/Emperator400/DungenManager/releases).',
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.white70, fontSize: 14),
                          h1: const TextStyle(color: DnDTheme.ancientGold, fontSize: 20),
                          h2: const TextStyle(color: DnDTheme.ancientGold, fontSize: 18),
                          h3: const TextStyle(color: DnDTheme.ancientGold, fontSize: 16),
                          listBullet: const TextStyle(color: Colors.white70),
                          code: const TextStyle(
                            color: DnDTheme.arcaneBlue,
                            backgroundColor: DnDTheme.dungeonBlack,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: DnDTheme.dungeonBlack,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquote: const TextStyle(
                            color: DnDTheme.charcoalGrey,
                            fontStyle: FontStyle.italic,
                          ),
                          strong: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          em: const TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        selectable: true,
                        onTapLink: (text, href, title) {
                          // Links im Browser öffnen
                          if (href != null) {
                            viewModel.openReleasesPage();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(UpdateViewModel viewModel) {
    String statusText;
    if (viewModel.isDownloading) {
      statusText = 'Wird heruntergeladen...';
    } else if (viewModel.isExtracting) {
      statusText = 'Wird entpackt...';
    } else {
      statusText = 'Bitte warten...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DnDTheme.arcaneBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(DnDTheme.arcaneBlue),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: const TextStyle(color: DnDTheme.arcaneBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: viewModel.progress,
              backgroundColor: DnDTheme.dungeonBlack,
              valueColor: const AlwaysStoppedAnimation(DnDTheme.arcaneBlue),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(UpdateViewModel viewModel) {
    final actions = <Widget>[];

    if (viewModel.isReady) {
      // Update ist bereit
      actions.addAll([
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Später',
            style: TextStyle(color: DnDTheme.charcoalGrey),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await viewModel.openExtractedFolder();
            if (context.mounted) {
              _showInstallInstructions(context);
            }
          },
          icon: const Icon(Icons.folder_open),
          label: const Text('Ordner öffnen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.emeraldGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ]);
    } else if (viewModel.isDownloading || viewModel.isExtracting) {
      // Download/Extraktion läuft
      actions.add(
        TextButton(
          onPressed: null,
          child: Text(
            'Bitte warten...',
            style: TextStyle(color: DnDTheme.charcoalGrey.withOpacity(0.5)),
          ),
        ),
      );
    } else if (viewModel.hasError) {
      // Fehler aufgetreten
      actions.addAll([
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Schließen',
            style: TextStyle(color: DnDTheme.charcoalGrey),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => viewModel.openReleasesPage(),
          icon: const Icon(Icons.open_in_browser),
          label: const Text('GitHub öffnen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.ancientGold,
            foregroundColor: DnDTheme.dungeonBlack,
          ),
        ),
      ]);
    } else {
      // Normale Auswahl
      actions.addAll([
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Später',
            style: TextStyle(color: DnDTheme.charcoalGrey),
          ),
        ),
        TextButton(
          onPressed: () => viewModel.openReleasesPage(),
          child: const Text(
            'GitHub',
            style: TextStyle(color: DnDTheme.arcaneBlue),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => viewModel.downloadUpdate(),
          icon: const Icon(Icons.download),
          label: const Text('Herunterladen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.ancientGold,
            foregroundColor: DnDTheme.dungeonBlack,
          ),
        ),
      ]);
    }

    return actions;
  }

  void _showInstallInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.slateGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: DnDTheme.ancientGold, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.info, color: DnDTheme.arcaneBlue),
            SizedBox(width: 12),
            Text(
              'Installation',
              style: TextStyle(color: DnDTheme.ancientGold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Das Update wurde heruntergeladen und entpackt.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'So installieren Sie das Update:',
              style: TextStyle(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Der Ordner mit dem Update wurde geöffnet\n'
              '2. Schließen Sie diese Anwendung\n'
              '3. Kopieren Sie den Inhalt des Ordners\n'
              '4. Ersetzen Sie die alten Dateien\n'
              '5. Starten Sie die Anwendung neu',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'Verstanden',
              style: TextStyle(color: DnDTheme.ancientGold),
            ),
          ),
        ],
      ),
    );
  }
}