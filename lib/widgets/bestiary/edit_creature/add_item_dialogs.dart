import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/item.dart';
import '../../../services/inventory_service.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/edit_creature_viewmodel.dart';
import '../../../widgets/ui_components/forms/form_field_widget.dart';
import 'library_item_card.dart';

/// Klasse für alle Item-bezogenen Dialoge in der Kreatur-Bearbeitung
class CreatureItemDialogs {
  /// Zeigt den Dialog zum Hinzufügen eines Items (Auswahl: Manuell oder Bibliothek)
  static Future<void> showAddItemDialog(
    BuildContext context,
    EditCreatureViewModel viewModel,
  ) async {
    final C = context.appColors;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Gegenstand hinzufügen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.amber),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: C.accent),
              title: Text(
                'Manuell eingeben',
                style: TextStyle(fontSize: 14, color: C.text),
              ),
              subtitle: Text(
                'Gegenstand mit allen Details manuell erstellen',
                style: TextStyle(fontSize: 12, color: C.textMid),
              ),
              onTap: () => Navigator.of(dialogContext).pop('manual'),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: Icon(Icons.inventory_2, color: C.amber),
              title: Text(
                'Aus Waffenkammer wählen',
                style: TextStyle(fontSize: 14, color: C.text),
              ),
              subtitle: Text(
                'Gegenstand aus der Item-Bibliothek auswählen',
                style: TextStyle(fontSize: 12, color: C.textMid),
              ),
              onTap: () => Navigator.of(dialogContext).pop('library'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
        ],
      ),
    );

    if (choice == 'manual') {
      await showManualAddDialog(context, viewModel);
    } else if (choice == 'library') {
      await showLibraryDialog(context, viewModel);
    }
  }

  /// Zeigt den Dialog zum manuellen Hinzufügen eines Items
  static Future<void> showManualAddDialog(
    BuildContext context,
    EditCreatureViewModel viewModel,
  ) {
    final C = context.appColors;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final typeController = TextEditingController(text: 'item');
    final quantityController = TextEditingController(text: '1');
    final valueController = TextEditingController(text: '0.0');

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Gegenstand hinzufügen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.amber),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormFieldWidget(
                label: 'Name',
                value: '',
                onChanged: (value) => nameController.text = value,
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Beschreibung',
                value: '',
                onChanged: (value) => descriptionController.text = value,
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Typ',
                value: 'item',
                onChanged: (value) => typeController.text = value,
                icon: Icons.category,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Menge',
                      value: '1',
                      onChanged: (value) => quantityController.text = value,
                      icon: Icons.add_box,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Wert (Gold)',
                      value: '0.0',
                      onChanged: (value) => valueController.text = value,
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final newItem = {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'type': typeController.text.trim(),
                  'quantity': int.tryParse(quantityController.text) ?? 1,
                  'value': double.tryParse(valueController.text) ?? 0.0,
                };
                viewModel.addInventoryItem(newItem);
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.amber,
              foregroundColor: C.bg,
            ),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  /// Zeigt den Dialog zur Auswahl aus der Item-Bibliothek
  static Future<void> showLibraryDialog(
    BuildContext context,
    EditCreatureViewModel viewModel,
  ) async {
    final C = context.appColors;
    final quantityController = TextEditingController(text: '1');
    final inventoryService = InventoryService();

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          String searchQuery = '';

          return AlertDialog(
            backgroundColor: C.bg,
            title: Text(
              'Gegenstand aus Waffenkammer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.amber),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  // Suchfeld
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Gegenstände durchsuchen...',
                      hintStyle: TextStyle(fontSize: 12, color: C.textMid),
                      prefixIcon: Icon(Icons.search, color: C.amber),
                      filled: true,
                      fillColor: C.bgPanel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(fontSize: 14, color: C.text),
                  ),
                  const SizedBox(height: 16),

                  // Item-Liste
                  Expanded(
                    child: FutureBuilder<List<Item>>(
                      future: inventoryService.getAllItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: C.amber,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Fehler beim Laden: ${snapshot.error}',
                              style: TextStyle(fontSize: 14, color: C.red),
                            ),
                          );
                        }

                        final items = snapshot.data ?? [];
                        final filteredItems = searchQuery.isEmpty
                            ? items
                            : items.where((item) =>
                                item.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

                        if (filteredItems.isEmpty) {
                          return Center(
                            child: Text(
                              'Keine Gegenstände gefunden',
                              style: TextStyle(fontSize: 14, color: C.textMid),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return LibraryItemCard(
                              item: item,
                              viewModel: viewModel,
                              quantityController: quantityController,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Abbrechen',
                  style: TextStyle(fontSize: 14, color: C.accent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Zeigt den Dialog zum Bearbeiten eines existierenden Items
  static Future<void> showEditItemDialog(
    BuildContext context,
    EditCreatureViewModel viewModel,
    int index,
  ) {
    final C = context.appColors;
    final inventory = viewModel.inventory;
    if (index < 0 || index >= inventory.length) return Future.value();

    final item = inventory[index];
    final nameController = TextEditingController(text: item['name'] as String? ?? '');
    final descriptionController = TextEditingController(text: item['description'] as String? ?? '');
    final typeController = TextEditingController(text: item['type'] as String? ?? 'item');
    final quantityController = TextEditingController(text: (item['quantity'] as int? ?? 1).toString());
    final valueController = TextEditingController(text: (item['value'] as double? ?? 0.0).toString());

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Gegenstand bearbeiten',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.amber),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormFieldWidget(
                label: 'Name',
                value: item['name'] as String? ?? '',
                onChanged: (value) => nameController.text = value,
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Beschreibung',
                value: item['description'] as String? ?? '',
                onChanged: (value) => descriptionController.text = value,
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Typ',
                value: item['type'] as String? ?? 'item',
                onChanged: (value) => typeController.text = value,
                icon: Icons.category,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Menge',
                      value: (item['quantity'] as int? ?? 1).toString(),
                      onChanged: (value) => quantityController.text = value,
                      icon: Icons.add_box,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Wert (Gold)',
                      value: (item['value'] as double? ?? 0.0).toString(),
                      onChanged: (value) => valueController.text = value,
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedItem = {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'type': typeController.text.trim(),
                  'quantity': int.tryParse(quantityController.text) ?? 1,
                  'value': double.tryParse(valueController.text) ?? 0.0,
                };
                viewModel.updateInventoryItem(index, updatedItem);
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.amber,
              foregroundColor: C.bg,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
