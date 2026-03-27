import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/item.dart';
import '../../../services/inventory_service.dart';
import '../../../theme/dnd_theme.dart';
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
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand hinzufügen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: DnDTheme.arcaneBlue),
              title: Text(
                'Manuell eingeben',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              subtitle: Text(
                'Gegenstand mit allen Details manuell erstellen',
                style: DnDTheme.bodyText2.copyWith(color: Colors.white60),
              ),
              onTap: () => Navigator.of(dialogContext).pop('manual'),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: Icon(Icons.inventory_2, color: DnDTheme.ancientGold),
              title: Text(
                'Aus Waffenkammer wählen',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              subtitle: Text(
                'Gegenstand aus der Item-Bibliothek auswählen',
                style: DnDTheme.bodyText2.copyWith(color: Colors.white60),
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
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
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
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final typeController = TextEditingController(text: 'item');
    final quantityController = TextEditingController(text: '1');
    final valueController = TextEditingController(text: '0.0');

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand hinzufügen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
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
                  const SizedBox(width: DnDTheme.md),
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
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
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
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
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
    final quantityController = TextEditingController(text: '1');
    final inventoryService = InventoryService();

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          String searchQuery = '';

          return AlertDialog(
            backgroundColor: DnDTheme.stoneGrey,
            title: Text(
              'Gegenstand aus Waffenkammer',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
              ),
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
                      hintStyle: DnDTheme.bodyText2.copyWith(
                        color: Colors.white60,
                      ),
                      prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
                      filled: true,
                      fillColor: DnDTheme.slateGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(DnDTheme.md),
                    ),
                    style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: DnDTheme.md),
                  
                  // Item-Liste
                  Expanded(
                    child: FutureBuilder<List<Item>>(
                      future: inventoryService.getAllItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: DnDTheme.ancientGold,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Fehler beim Laden: ${snapshot.error}',
                              style: DnDTheme.bodyText1.copyWith(
                                color: DnDTheme.errorRed,
                              ),
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
                              style: DnDTheme.bodyText1.copyWith(
                                color: Colors.white60,
                              ),
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
                  style: DnDTheme.bodyText1.copyWith(
                    color: DnDTheme.mysticalPurple,
                  ),
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
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand bearbeiten',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
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
                  const SizedBox(width: DnDTheme.md),
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
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
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
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}