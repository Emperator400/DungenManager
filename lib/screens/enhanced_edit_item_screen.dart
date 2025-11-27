import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/edit_item_viewmodel.dart';
import '../models/item.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Item Edit Screen mit Provider-Pattern und modernem D&D Design
class EnhancedEditItemScreen extends StatefulWidget {
  final Item? item;

  const EnhancedEditItemScreen({
    super.key,
    this.item,
  });

  @override
  State<EnhancedEditItemScreen> createState() => _EnhancedEditItemScreenState();
}

class _EnhancedEditItemScreenState extends State<EnhancedEditItemScreen> {
  late EditItemViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _propertiesController = TextEditingController();
  final _costController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = EditItemViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize(widget.item);
      _populateFields();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _propertiesController.dispose();
    _costController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final item = _viewModel.item;
    
    if (item != null) {
      _nameController.text = item!.name;
      _descriptionController.text = item!.description;
      _propertiesController.text = item!.properties ?? '';
      _costController.text = item!.cost.toString();
      _weightController.text = item!.weight.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditItemViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(),
          ),
          child: SafeArea(
            child: Consumer<EditItemViewModel>(
              builder: (context, viewModel, child) {
                return Column(
                  children: [
                    _buildHeader(context, viewModel),
                    Expanded(
                      child: _buildForm(context, viewModel),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.mysticalPurple.withValues(alpha: 0.9),
          endColor: DnDTheme.arcaneBlue.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleBackNavigation(viewModel),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              viewModel.item != null ? 'Item bearbeiten' : 'Neues Item',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (viewModel.hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DnDTheme.errorRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Nicht gespeichert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, EditItemViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(context, viewModel),
            const SizedBox(height: 24),
            _buildDetailsSection(context, viewModel),
            const SizedBox(height: 24),
            _buildPropertiesSection(context, viewModel),
            const SizedBox(height: 32),
            _buildActionButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DnDTheme.ancientGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grundlegende Informationen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Item Name *',
              hintText: 'z.B. Langschwert +1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name ist erforderlich';
              }
              if (value.trim().length < 2) {
                return 'Name muss mindestens 2 Zeichen lang sein';
              }
              return null;
            },
            onChanged: (value) => viewModel.updateName(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Beschreibung',
              hintText: 'Beschreibe das Item...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
            ),
            onChanged: (value) => viewModel.updateDescription(value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ItemType>(
            value: viewModel.item?.itemType,
            decoration: InputDecoration(
              labelText: 'Item Typ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withValues(alpha: 0.5)),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
            ),
            items: ItemType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getItemTypeDisplayName(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                viewModel.updateType(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DnDTheme.ancientGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Wert (Gold)',
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  onChanged: (value) {
                    final cost = double.tryParse(value) ?? 0.0;
                    viewModel.updateValue(cost);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Gewicht (lbs)',
                    hintText: '0.0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DnDTheme.ancientGold),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value) ?? 0.0;
                    viewModel.updateWeight(weight);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesSection(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DnDTheme.ancientGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eigenschaften',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _propertiesController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Spezielle Eigenschaften',
              hintText: 'z.B. Magische Boni, Spezialfähigkeiten...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DnDTheme.ancientGold),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
            onChanged: (value) => viewModel.updateProperties(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EditItemViewModel viewModel) {
    return Column(
      children: [
        if (viewModel.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: DnDTheme.errorRed.withOpacity(0.1),
              border: Border.all(color: DnDTheme.errorRed),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(
                color: DnDTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: viewModel.isLoading ? null : () => _handleSave(viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SPEICHERN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.isLoading ? null : () => _handleCancel(viewModel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ABBRECHEN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (viewModel.item != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: viewModel.isLoading ? null : () => _handleDelete(viewModel),
              style: OutlinedButton.styleFrom(
                foregroundColor: DnDTheme.errorRed,
                side: BorderSide(color: DnDTheme.errorRed),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'LÖSCHEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getItemTypeDisplayName(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return 'Waffe';
      case ItemType.Armor:
        return 'Rüstung';
      case ItemType.Shield:
        return 'Schild';
      case ItemType.Consumable:
        return 'Verbrauchsgut';
      case ItemType.Tool:
        return 'Werkzeug';
      case ItemType.Material:
        return 'Material';
      case ItemType.Component:
        return 'Komponente';
      case ItemType.MagicItem:
        return 'Magisches Item';
      case ItemType.Scroll:
        return 'Schriftrolle';
      case ItemType.Potion:
        return 'Trank';
      case ItemType.Treasure:
        return 'Schatz';
      case ItemType.Currency:
        return 'Währung';
      case ItemType.AdventuringGear:
        return 'Ausrüstung';
      case ItemType.SPELL_WEAPON:
        return 'Spruch als Waffe';
    }
  }

  void _handleSave(EditItemViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await viewModel.saveItem();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _handleCancel(EditItemViewModel viewModel) {
    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(viewModel);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleDelete(EditItemViewModel viewModel) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true) {
      final success = await viewModel.deleteItem();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _handleBackNavigation(EditItemViewModel viewModel) {
    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(viewModel);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog(EditItemViewModel viewModel) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich gehen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('VERLASSEN'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: const Text(
          'Möchten Sie dieses Item wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: DnDTheme.errorRed),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }
}
