import 'package:flutter/material.dart';
import '../character_editor/character_editor_controller.dart';
import 'enhanced_inventory_tab_widget.dart';

class InventoryDemoWidget extends StatefulWidget {
  const InventoryDemoWidget({super.key});

  @override
  State<InventoryDemoWidget> createState() => _InventoryDemoWidgetState();
}

class _InventoryDemoWidgetState extends State<InventoryDemoWidget> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Inventar Demo'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        actions: const [],
      ),
      body: EnhancedInventoryTabWidget(
        characterType: CharacterType.npc, // NPCs können bearbeitet werden
        pcId: null,
        creatureId: 'demo_character',
        viewModel: null, // Demo-Modus ohne ViewModel
      ),
    );
  }

}
