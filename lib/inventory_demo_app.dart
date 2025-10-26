import 'package:flutter/material.dart';
import 'widgets/character_editor/inventory_demo_widget.dart';

void main() {
  runApp(const InventoryDemoApp());
}

class InventoryDemoApp extends StatelessWidget {
  const InventoryDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventar Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade900,
        cardColor: Colors.grey.shade800,
        primaryColor: Colors.blue.shade700,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const InventoryDemoWidget(),
    );
  }
}
