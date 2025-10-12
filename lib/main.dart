// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/campaign_list_screen.dart';

// NEU: Import für das Audio-Player-Paket
import 'package:audioplayers/audioplayers.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await AudioPlayer.global.setAudioContext( AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: true,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
  ));
  
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