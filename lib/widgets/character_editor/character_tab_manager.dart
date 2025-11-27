import 'package:flutter/material.dart';
import '../character_editor/enhanced_character_editor_controller.dart';
import '../character_editor/character_editor_controller.dart';
import '../character_editor/basic_info_tab_builder.dart';
import '../character_editor/attributes_tab_widget.dart';
import '../character_editor/attacks_tab_widget.dart';
import '../character_editor/enhanced_inventory_tab_widget.dart';
import '../character_editor/character_inventory_handler.dart';
import '../../models/inventory_item.dart';

class CharacterTabManager {
  final EnhancedCharacterEditorController controller;
  final TickerProvider vsync;
  final VoidCallback onStateChanged;
  final GlobalKey<FormState> formKey;
  final CharacterInventoryHandler? inventoryHandler;

  CharacterTabManager({
    required this.controller,
    required this.vsync,
    required this.onStateChanged,
    required this.formKey,
    this.inventoryHandler,
  });

  TabController createTabController() {
    return TabController(length: _getTabCount(), vsync: vsync);
  }

  List<Tab> getTabs() {
    switch (controller.characterType) {
      case CharacterType.player:
        return const [
          Tab(text: 'Basis', icon: Icon(Icons.info)),
          Tab(text: 'Attribute', icon: Icon(Icons.fitness_center)),
          Tab(text: 'Inventar', icon: Icon(Icons.inventory)),
        ];
      case CharacterType.npc:
      case CharacterType.monster:
        return const [
          Tab(text: 'Basis', icon: Icon(Icons.info)),
          Tab(text: 'Attribute', icon: Icon(Icons.fitness_center)),
          Tab(text: 'Angriffe', icon: Icon(Icons.gavel)),
          Tab(text: 'Inventar', icon: Icon(Icons.inventory)),
        ];
    }
  }

  List<Widget> getTabViews() {
    final basicInfoBuilder = BasicInfoTabBuilder(
      controller: controller,
      formKey: formKey,
    );

    switch (controller.characterType) {
      case CharacterType.player:
        return [
          basicInfoBuilder.buildForPlayerCharacter(onStateChanged),
          _buildAttributesTab(showSkills: true),
          _buildInventoryTab(),
        ];
      case CharacterType.npc:
      case CharacterType.monster:
        return [
          basicInfoBuilder.buildForCreature(onStateChanged),
          _buildAttributesTab(showSkills: false),
          _buildAttacksTab(),
          _buildInventoryTab(),
        ];
    }
  }

  String getScreenTitle() {
    switch (controller.characterType) {
      case CharacterType.player:
        return controller.pcToEdit == null ? 'Neuen Helden erstellen' : 'Helden bearbeiten';
      case CharacterType.npc:
        return controller.creatureToEdit == null ? 'Neuen NSC erstellen' : 'NSC bearbeiten';
      case CharacterType.monster:
        return controller.creatureToEdit == null ? 'Neues Monster erstellen' : 'Monster bearbeiten';
    }
  }

  int _getTabCount() {
    switch (controller.characterType) {
      case CharacterType.player:
        return 3; // Basis, Attribute, Inventar
      case CharacterType.npc:
      case CharacterType.monster:
        return 4; // Basis, Attribute, Fähigkeiten, Inventar
    }
  }

  Widget _buildAttributesTab({required bool showSkills}) {
    return AttributesTabWidget(
      strController: controller.strController,
      dexController: controller.dexController,
      conController: controller.conController,
      intController: controller.intController,
      wisController: controller.wisController,
      chaController: controller.chaController,
      levelController: controller.levelController,
      proficientSkills: controller.proficientSkills,
      onSkillToggle: (skillName) {
        controller.toggleSkill(skillName);
        onStateChanged();
      },
      onRebuild: onStateChanged,
      showSkills: showSkills,
    );
  }

  Widget _buildAttacksTab() {
    return AttacksTabWidget(
      attacks: controller.attackList,
      onAttacksChanged: (attacks) {
        controller.updateAttacks(attacks);
        onStateChanged();
      },
      isEditable: true,
    );
  }

  Widget _buildInventoryTab() {
    return EnhancedInventoryTabWidget(
      characterType: controller.characterType,
      pcId: controller.pcToEdit?.id,
      creatureId: controller.creatureToEdit?.id,
      viewModel: controller.viewModel,
    );
  }

  Future<void> _handleAddItem() async {
    if (inventoryHandler != null) {
      await inventoryHandler!.addItemFromLibrary();
    }
  }

  Future<void> _handleLoadInventory() async {
    try {
      await controller.loadInventory();
      onStateChanged();
    } catch (e) {
      // Error handling wird vom aufrufenden Widget übernommen
    }
  }

  Future<void> _handleManageItem(DisplayInventoryItem displayItem) async {
    if (inventoryHandler != null) {
      await inventoryHandler!.showManageItemDialog(displayItem);
    }
  }

  Future<void> _handleUpdateQuantity(DisplayInventoryItem displayItem, int newQuantity) async {
    if (inventoryHandler != null) {
      await inventoryHandler!.updateItemQuantity(displayItem, newQuantity);
    }
  }

  Future<void> _handleRemoveItem(DisplayInventoryItem displayItem) async {
    if (inventoryHandler != null) {
      await inventoryHandler!.removeItem(displayItem);
    }
  }
}
