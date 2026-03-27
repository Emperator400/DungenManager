import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/campaign_viewmodel.dart';
import '../../viewmodels/update_viewmodel.dart';
import '../../widgets/campaign/campaign_selection_layout_widget.dart';

/// Campaign Selection Screen - Startseite der Anwendung
/// 
/// Zeigt alle verfügbaren Kampagnen mit Filter- und Suchfunktionen.
/// Ermöglicht die Auswahl einer Kampagne für den Zugriff auf
/// kampagnenspezifische Inhalte und Funktionen.
class CampaignSelectionScreen extends StatefulWidget {
  const CampaignSelectionScreen({super.key});

  @override
  State<CampaignSelectionScreen> createState() => _CampaignSelectionScreenState();
}

class _CampaignSelectionScreenState extends State<CampaignSelectionScreen> {
  bool _updateChecked = false;
  UpdateViewModel? _updateViewModel;

  @override
  void initState() {
    super.initState();
    // Lade Kampagnen beim Start des Screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignViewModel>().loadCampaigns();
      _checkForUpdates();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sichere Referenz auf UpdateViewModel speichern (wie von Flutter empfohlen)
    _updateViewModel ??= context.read<UpdateViewModel>();
  }

  /// Prüft automatisch auf Updates beim Start
  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;
    _updateChecked = true;

    // Kurze Verzögerung damit die UI geladen ist
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted || _updateViewModel == null) return;

    final hasUpdate = await _updateViewModel!.checkForUpdate();

    if (hasUpdate && mounted) {
      // Zeige Update-Dialog wenn Update verfügbar
      // Importiere die Funktion aus dem update_dialog.dart
      // await showUpdateDialogIfNeeded(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CampaignSelectionLayout();
  }
}