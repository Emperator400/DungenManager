import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../theme/app_theme.dart';

/// Wiederverwendbarer Dialog zum Erstellen neuer Kampagnen
///
/// Kann in verschiedenen Screens (Selection, Dashboard) verwendet werden
class CampaignCreateDialogWidget extends StatefulWidget {
  final CampaignViewModel viewModel;
  final VoidCallback? onSuccess;

  const CampaignCreateDialogWidget({
    super.key,
    required this.viewModel,
    this.onSuccess,
  });

  /// Zeigt den Dialog als Modal
  static Future<void> show(
    BuildContext context, {
    required CampaignViewModel viewModel,
    VoidCallback? onSuccess,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CampaignCreateDialogWidget(
        viewModel: viewModel,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<CampaignCreateDialogWidget> createState() => _CampaignCreateDialogWidgetState();
}

class _CampaignCreateDialogWidgetState extends State<CampaignCreateDialogWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  CampaignType _selectedType = CampaignType.homebrew;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return AlertDialog(
      title: Text(
        'Neue Kampagne erstellen',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text).copyWith(
          color: C.amber,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Titel *',
                hintText: 'Name der Kampagne',
                labelStyle: TextStyle(
                  color: C.amber.withValues(alpha: 0.8),
                ),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Beschreibung *',
                hintText: 'Kurze Beschreibung der Kampagne',
                labelStyle: TextStyle(
                  color: C.amber.withValues(alpha: 0.8),
                ),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CampaignType>(
              value: _selectedType,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Kampagnen-Typ',
                labelStyle: TextStyle(
                  color: C.amber.withValues(alpha: 0.8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: C.amber,
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: C.bg,
              items: CampaignType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (type) => setState(() => _selectedType = type!),
            ),
          ],
        ),
      ),
      backgroundColor: C.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: C.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _createCampaign,
          style: ElevatedButton.styleFrom(
            backgroundColor: C.amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  void _createCampaign() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    Navigator.of(context).pop();

    try {
      await widget.viewModel.createCampaign(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kampagne erstellt'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // onSuccess Callback ausführen
      widget.onSuccess?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen: $e'),
            backgroundColor: context.appColors.red,
          ),
        );
      }
    }
  }
}

/// Extension für CampaignType Display Names
extension CampaignTypeExtension on CampaignType {
  String get displayName {
    switch (this) {
      case CampaignType.homebrew:
        return 'Homebrew';
      case CampaignType.module:
        return 'Module';
      case CampaignType.adventurePath:
        return 'Adventure Path';
      case CampaignType.oneShot:
        return 'One-Shot';
    }
  }
}
