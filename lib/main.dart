// lib/main.dart
import 'package:flutter/material.dart';
// Keine Model- oder Hive-Imports mehr nötig!
import 'screens/campaign_list_screen.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() async {


   if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialisiere die FFI-Bibliotheken
    sqfliteFfiInit();
    // Sage sqflite, dass es die FFI-Implementierung verwenden soll
    databaseFactory = databaseFactoryFfi;
  }
  // Wichtig für sqflite, um sicherzustellen, dass alles bereit ist.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Alle Hive-Initialisierungen, Adapter und Boxen sind entfernt.
  
  runApp(const DmApp());
}

class DmApp extends StatelessWidget {
  const DmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM Helper',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepOrange,
        scaffoldBackgroundColor: const Color.fromARGB(255, 20, 30, 40),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 15, 25, 35),
        ),
        cardColor: const Color.fromARGB(255, 30, 40, 50),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
          ),
        ),
      ),
      home: const CampaignListScreen(), // SessionScreen wird unser neuer "Anker"
    );
  }
}