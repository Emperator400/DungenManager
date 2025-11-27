import 'package:flutter/material.dart';
import 'widgets/character_editor/inventory_demo_widget.dart';
import 'theme/dnd_theme.dart';

void main() {
  runApp(const InventoryDemoApp());
}

class InventoryDemoApp extends StatelessWidget {
  const InventoryDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventar Demo - D&D Theme',
      theme: DnDTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const InventoryDemoWidget(),
    );
  }
}
