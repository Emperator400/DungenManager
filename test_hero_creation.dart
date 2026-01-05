import 'package:flutter/material.dart';
import 'lib/screens/enhanced_unified_character_editor_screen.dart';
import 'lib/widgets/character_editor/character_editor_controller.dart';
import 'lib/theme/dnd_theme.dart';
import 'lib/viewmodels/character_editor_viewmodel.dart';

void main() {
  runApp(const HeroCreationTestApp());
}

class HeroCreationTestApp extends StatelessWidget {
  const HeroCreationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hero Creation Test',
      theme: DnDTheme.darkTheme,
      home: const HeroCreationTestScreen(),
    );
  }
}

class HeroCreationTestScreen extends StatelessWidget {
  const HeroCreationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: const Text(
          'Hero Creation Test',
          style: TextStyle(color: DnDTheme.ancientGold),
        ),
        backgroundColor: DnDTheme.stoneGrey,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DnDTheme.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Teste Heldenerstellung',
                style: TextStyle(
                  color: DnDTheme.ancientGold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DnDTheme.lg),
              
              // Player Character Creation
              Container(
                width: double.infinity,
                height: 80,
                decoration: DnDTheme.getFantasyCardDecoration(
                  borderColor: DnDTheme.emeraldGreen,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EnhancedUnifiedCharacterEditorScreen(
                          characterType: CharacterType.player,
                          campaignId: 'test-campaign-123',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 32),
                  label: const Text(
                    'Player Character erstellen',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: DnDTheme.emeraldGreen,
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: DnDTheme.md),
              
              // NPC Creation
              Container(
                width: double.infinity,
                height: 80,
                decoration: DnDTheme.getFantasyCardDecoration(
                  borderColor: DnDTheme.arcaneBlue,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EnhancedUnifiedCharacterEditorScreen(
                          characterType: CharacterType.npc,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_alt, size: 32),
                  label: const Text(
                    'NPC erstellen',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: DnDTheme.arcaneBlue,
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: DnDTheme.md),
              
              // Monster Creation
              Container(
                width: double.infinity,
                height: 80,
                decoration: DnDTheme.getFantasyCardDecoration(
                  borderColor: DnDTheme.errorRed,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EnhancedUnifiedCharacterEditorScreen(
                          characterType: CharacterType.monster,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.pets, size: 32),
                  label: const Text(
                    'Monster erstellen',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: DnDTheme.errorRed,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
