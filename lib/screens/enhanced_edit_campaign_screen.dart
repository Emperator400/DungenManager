import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../viewmodels/campaign_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Screen zur Bearbeitung von Campaigns mit CampaignViewModel
class EnhancedEditCampaignScreen extends StatefulWidget {
  final Campaign? campaign;

  const EnhancedEditCampaignScreen({
    Key? key,
    this.campaign,
  }) : super(key: key);

  @override
  State<EnhancedEditCampaignScreen> createState() => _EnhancedEditCampaignScreenState();
}

class _EnhancedEditCampaignScreenState extends State<EnhancedEditCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // temporäre Variablen für die Bearbeitung
  late CampaignStatus _status;
  late CampaignType _type;
  String? _dungeonMasterId;

  @override
  void initState() {
    super.initState();
    
    // Initialisiere temporäre Variablen mit den Werten der Kampagne oder Defaults
    _status = widget.campaign?.status ?? CampaignStatus.planning;
    _type = widget.campaign?.type ?? CampaignType.homebrew;
    _dungeonMasterId = widget.campaign?.dungeonMasterId;
    
    // Controller mit Kampagnendaten füllen
    if (widget.campaign != null) {
      _titleController.text = widget.campaign!.title;
      _descriptionController.text = widget.campaign!.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty && 
           _descriptionController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.campaign == null ? 'Neue Kampagne' : 'Kampagne bearbeiten',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
        ),
        actions: [
          Consumer<CampaignViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(
                  Icons.save, 
                  color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
                ),
                onPressed: _canSave && !viewModel.isLoading ? _saveCampaign : null,
                tooltip: 'Speichern',
              );
            },
          ),
        ],
      ),
      body: Consumer<CampaignViewModel>(
        builder: (context, viewModel, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fehlermeldung
                  if (viewModel.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.error!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: viewModel.clearError,
                            color: Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),

                  // Grundinformationen
                  _buildSectionCard(
                    title: 'Grundinformationen',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration('Titel', Icons.title),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Titel ist erforderlich';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration('Beschreibung', Icons.description),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Beschreibung ist erforderlich';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CampaignStatus>(
                          value: _status,
                          decoration: _buildInputDecoration('Status', Icons.flag),
                          items: CampaignStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                _getLocalizedStatus(status),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (CampaignStatus? value) {
                            if (value != null) {
                              setState(() {
                                _status = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CampaignType>(
                          value: _type,
                          decoration: _buildInputDecoration('Typ', Icons.category),
                          items: CampaignType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                _getLocalizedType(type),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (CampaignType? value) {
                            if (value != null) {
                              setState(() {
                                _type = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kampagnen-Informationen
                  _buildSectionCard(
                    title: 'Kampagnen-Informationen',
                    icon: Icons.campaign,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _dungeonMasterId ?? '',
                          decoration: _buildInputDecoration('Dungeon Master ID', Icons.person),
                          onChanged: (value) {
                            setState(() {
                              _dungeonMasterId = value.isEmpty ? null : value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.group, color: DnDTheme.mysticalPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Spieler: ${widget.campaign?.playerCount ?? 0}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if ((widget.campaign?.playerCount ?? 0) > 0)
                              TextButton.icon(
                                onPressed: () => _showPlayerDialog(),
                                icon: Icon(Icons.edit, size: 16),
                                label: Text('Spieler verwalten'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Aktionen
                  _buildActionButtons(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: DnDTheme.mysticalPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      prefixIcon: Icon(icon, color: DnDTheme.mysticalPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildActionButtons(CampaignViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text('Abbrechen'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _canSave && !viewModel.isLoading ? _saveCampaign : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.mysticalPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: viewModel.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Speichern',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        if (widget.campaign != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _duplicateCampaign,
              icon: Icon(Icons.copy, color: Colors.white),
              label: Text('Duplizieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  String _getLocalizedStatus(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.planning:
        return 'Planung';
      case CampaignStatus.active:
        return 'Aktiv';
      case CampaignStatus.paused:
        return 'Pausiert';
      case CampaignStatus.completed:
        return 'Abgeschlossen';
      case CampaignStatus.cancelled:
        return 'Abgebrochen';
    }
  }

  String _getLocalizedType(CampaignType type) {
    switch (type) {
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

  void _showPlayerDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Spieler verwalten'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              Text('Spieler-Management-Funktion wird in zukünftiger Version implementiert.'),
              const SizedBox(height: 20),
              Text(
                'Aktuelle Spieleranzahl: ${widget.campaign?.playerCount ?? 0}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<CampaignViewModel>();
    
    if (widget.campaign == null) {
      // Neue Kampagne erstellen
      await viewModel.createCampaign(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    } else {
      // Bestehende Kampagne aktualisieren
      final updatedCampaign = widget.campaign!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        type: _type,
        dungeonMasterId: _dungeonMasterId,
        updatedAt: DateTime.now(),
      );
      
      await viewModel.updateCampaign(updatedCampaign);
    }
    
    // Wenn erfolgreich, zurückspringen
    if (viewModel.error == null && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _duplicateCampaign() async {
    if (widget.campaign != null) {
      final viewModel = context.read<CampaignViewModel>();
      await viewModel.duplicateCampaign(widget.campaign!);
      
      if (viewModel.error == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kampagne dupliziert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
