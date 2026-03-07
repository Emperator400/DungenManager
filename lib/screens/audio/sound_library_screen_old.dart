// lib/screens/sound_library_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/sounds_tab.dart'; // Erstellen wir gleich
import '../../widgets/sound_scenes_tab.dart';

class SoundLibraryScreen extends StatelessWidget {
  const SoundLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Sound & Atmosphäre"),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.music_note), text: "Sounds"),
            Tab(icon: Icon(Icons.movie_filter), text: "Szenen"),
          ]),
        ),
        body: const TabBarView(
          children: [
            SoundsTab(),
            // Den Platzhalter durch unser neues Widget ersetzen
            SoundScenesTab(),
          ],
        ),
      ),
    );
  }
}
