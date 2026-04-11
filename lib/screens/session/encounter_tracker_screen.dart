// lib/screens/session/encounter_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/encounter_participant.dart';
import '../../models/condition.dart';
import '../../models/player_character.dart';
import '../../models/creature.dart';
import '../../models/attack.dart';
import '../../viewmodels/encounter_tracker_viewmodel.dart';
import '../../theme/dnd_theme.dart';
import 'dart:math';

/// Encounter Tracker Screen
/// 
/// Haupt-Screen für das Abwickeln von Kämpfen mit:
/// - Initiative-Verwaltung
/// - HP-Tracking
/// - Conditions
/// - Runden-Counter
class EncounterTrackerScreen extends StatefulWidget {
  final String encounterId;
  final String encounterTitle;
  final Map<String, int>? initialInitiativeValues;

  const EncounterTrackerScreen({
    super.key,
    required this.encounterId,
    this.encounterTitle = 'Kampf',
    this.initialInitiativeValues,
  });

  @override
  State<EncounterTrackerScreen> createState() => _EncounterTrackerScreenState();
}

class _EncounterTrackerScreenState extends State<EncounterTrackerScreen> {
  late final EncounterTrackerViewModel _viewModel;
  // Lokale Initiative-Werte (werden nicht in DB gespeichert)
  final Map<String, int> _initiativeValues = {};
  final Map<String, TextEditingController> _initiativeControllers = {};

  @override
  void initState() {
    super.initState();
    _viewModel = EncounterTrackerViewModel();
    _viewModel.loadEncounter(widget.encounterId).then((_) {
      // Übernehme Initiative-Werte vom Setup-Screen, falls vorhanden
      _applyInitialInitiativeValues();
    });
  }

  /// Wendet die übergebenen Initiative-Werte auf die Teilnehmer an
  void _applyInitialInitiativeValues() {
    if (widget.initialInitiativeValues == null || 
        widget.initialInitiativeValues!.isEmpty) {
      return;
    }
    
    // Mapping von Character/Monster-IDs zu Participant-IDs
    for (final participant in _viewModel.participants) {
      // Prüfe ob es ein Character ist
      if (participant.characterId != null) {
        final charKey = 'char_${participant.characterId}';
        if (widget.initialInitiativeValues!.containsKey(charKey)) {
          _initiativeValues[participant.id] = widget.initialInitiativeValues![charKey]!;
        }
      }
      // Prüfe ob es ein Monster/Creature ist
      if (participant.creatureId != null) {
        final monsterKey = 'monster_${participant.creatureId}';
        if (widget.initialInitiativeValues!.containsKey(monsterKey)) {
          _initiativeValues[participant.id] = widget.initialInitiativeValues![monsterKey]!;
        }
      }
    }
    
    // Nach dem Laden der initialen Werte direkt sortieren
    if (_initiativeValues.isNotEmpty) {
      _sortParticipantsByInitiative();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    // Controller aufräumen
    for (final controller in _initiativeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _rollInitiativeForAll() {
    final random = Random();
    setState(() {
      for (final participant in _viewModel.participants) {
        int modifier = 0;
        
        // Versuche, den DEX-Modifikator zu ermitteln
        final character = _viewModel.getCharacterForParticipant(participant);
        final creature = _viewModel.getCreatureForParticipant(participant);
        
        if (character != null) {
          modifier = (character.dexterity - 10) ~/ 2;
        } else if (creature != null) {
          modifier = (creature.dexterity - 10) ~/ 2;
        }

        final roll = random.nextInt(20) + 1 + modifier;
        _initiativeValues[participant.id] = roll;
        if (_initiativeControllers.containsKey(participant.id)) {
          _initiativeControllers[participant.id]!.text = roll.toString();
        }
      }
    });
    _sortParticipantsByInitiative();
  }

  void _sortParticipantsByInitiative() {
    try {
      // Sortiere direkt im ViewModel, damit viewModel.nextTurn() die Reihenfolge beachtet
      _viewModel.participants.sort((a, b) {
        // 1. Tote ans Ende
        if (a.isDead && b.isAlive) return 1;
        if (a.isAlive && b.isDead) return -1;
        
        // 2. Nach Initiative sortieren (absteigend)
        final initA = _initiativeValues[a.id] ?? 0;
        final initB = _initiativeValues[b.id] ?? 0;
        return initB.compareTo(initA);
      });
    } catch (e) {
      debugPrint('Hinweis: Teilnehmer konnten nicht im ViewModel sortiert werden: $e');
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EncounterTrackerViewModel>.value(
      value: _viewModel,
      child: Consumer<EncounterTrackerViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: DnDTheme.dungeonBlack,
            appBar: _buildAppBar(viewModel),
            body: _buildBody(viewModel),
            floatingActionButton: _buildFAB(viewModel),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(EncounterTrackerViewModel viewModel) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.gavel, color: DnDTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.encounterTitle,
                  style: DnDTheme.headline3.copyWith(color: Colors.white),
                ),
                Text(
                  'Runde ${viewModel.roundCounter}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: DnDTheme.stoneGrey,
      foregroundColor: Colors.white,
      elevation: 4,
      actions: [
        // Initiative würfeln Button
        IconButton(
          icon: Icon(Icons.casino, color: DnDTheme.ancientGold),
          onPressed: _rollInitiativeForAll,
          tooltip: 'Alle Initiative würfeln',
        ),
        // Kampf beenden Button
        IconButton(
          icon: Icon(Icons.stop_circle, color: DnDTheme.errorRed),
          onPressed: () => _showEndEncounterDialog(viewModel),
          tooltip: 'Kampf beenden',
        ),
      ],
    );
  }

  Widget _buildBody(EncounterTrackerViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DnDTheme.ancientGold),
      );
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorWidget(viewModel.errorMessage!);
    }

    if (viewModel.participants.isEmpty) {
      return _buildEmptyWidget();
    }

    // Initialisiere Initiative-Controller falls nötig
    for (final participant in viewModel.participants) {
      if (!_initiativeControllers.containsKey(participant.id)) {
        _initiativeControllers[participant.id] = TextEditingController(
          text: _initiativeValues[participant.id]?.toString() ?? '',
        );
      }
    }

    return Column(
      children: [
        // Status Bar
        _buildStatusBar(viewModel),
        // Teilnehmer Liste
        Expanded(
          child: _buildParticipantsList(viewModel),
        ),
      ],
    );
  }

  Widget _buildStatusBar(EncounterTrackerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        border: Border(
          bottom: BorderSide(
            color: DnDTheme.ancientGold.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Spieler Status
          _buildStatusChip(
            icon: Icons.person,
            label: 'Helden: ${viewModel.alivePlayersCount}',
            color: DnDTheme.arcaneBlue,
          ),
          const SizedBox(width: 12),
          // Gegner Status
          _buildStatusChip(
            icon: Icons.shield,
            label: 'Gegner: ${viewModel.aliveEnemiesCount}',
            color: DnDTheme.errorRed,
          ),
          const Spacer(),
          // Aktueller Zug
          if (viewModel.currentParticipant != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DnDTheme.ancientGold),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: DnDTheme.ancientGold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Am Zug: ${viewModel.currentParticipant!.name}',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(EncounterTrackerViewModel viewModel) {
    final sortedParticipants = List<EncounterParticipant>.from(viewModel.participants);
    
    // Zur Sicherheit visuell sortieren, falls das in-place Sortieren im ViewModel fehlschlug
    sortedParticipants.sort((a, b) {
      if (a.isDead && b.isAlive) return 1;
      if (a.isAlive && b.isDead) return -1;
      
      final initA = _initiativeValues[a.id] ?? 0;
      final initB = _initiativeValues[b.id] ?? 0;
      return initB.compareTo(initA);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
      itemCount: sortedParticipants.length,
      itemBuilder: (context, index) {
        final participant = sortedParticipants[index];
        final isActive = viewModel.currentParticipant?.id == participant.id;
        final initiative = _initiativeValues[participant.id];
        
        return _buildParticipantCard(
          viewModel: viewModel,
          participant: participant,
          isActive: isActive,
          initiative: initiative,
        );
      },
    );
  }

  Widget _buildParticipantCard({
    required EncounterTrackerViewModel viewModel,
    required EncounterParticipant participant,
    required bool isActive,
    int? initiative,
  }) {
    final isPlayer = participant.type == ParticipantType.player;
    final cardColor = isPlayer ? DnDTheme.arcaneBlue : DnDTheme.errorRed;

    return GestureDetector(
      onLongPress: () => _showParticipantContextMenu(participant, viewModel),
      onSecondaryTapDown: (details) => _showParticipantContextMenuAt(
        participant, 
        viewModel, 
        details.globalPosition,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: isActive ? 4 : 8,
          vertical: isActive ? 6 : 4,
        ),
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: cardColor.withValues(alpha: isActive ? 0.9 : 0.7),
            endColor: cardColor.withValues(alpha: isActive ? 0.7 : 0.5),
          ),
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          border: Border.all(
            color: isActive 
                ? DnDTheme.ancientGold 
                : cardColor.withValues(alpha: 0.5),
            width: isActive ? 3 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: DnDTheme.ancientGold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header mit Initiative und Name
            _buildCardHeader(participant, initiative, isPlayer, cardColor),
            
            // HP Bar und Schnellaktionen
            _buildHpSection(participant, viewModel, cardColor),
            
            // Conditions
            _buildConditionsSection(participant, viewModel, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    EncounterParticipant participant,
    int? initiative,
    bool isPlayer,
    Color cardColor,
  ) {
    // Lade Character- oder Creature-Daten für Stats
    final character = _viewModel.getCharacterForParticipant(participant);
    final creature = _viewModel.getCreatureForParticipant(participant);
    
    // AC ermitteln
    int? armorClass;
    if (character != null) {
      armorClass = character.armorClass;
    } else if (creature != null) {
      armorClass = creature.armorClass;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              // Initiative Badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DnDTheme.ancientGold.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: initiative != null
                      ? Text(
                          initiative.toString(),
                          style: const TextStyle(
                            color: DnDTheme.ancientGold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.casino,
                            color: DnDTheme.ancientGold,
                            size: 20,
                          ),
                          onPressed: () => _showInitiativeDialog(participant),
                          tooltip: 'Initiative setzen',
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Name und Typ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isPlayer ? Icons.person : Icons.shield,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPlayer ? 'Held' : 'Gegner',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (participant.isDead) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DnDTheme.errorRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // HP und AC Anzeige
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HP
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'HP: ${participant.currentHp}/${participant.maxHp}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // AC (falls verfügbar)
                      if (armorClass != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'AC: $armorClass',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Attribute und Angriffe (falls verfügbar)
          if (character != null || creature != null) ...[
            const SizedBox(height: 8),
            _buildStatsAndAttacks(character, creature),
          ],
        ],
      ),
    );
  }

  /// D&D 5e Fertigkeiten und ihre zugehörigen Attribute
  static const Map<String, String> _skillAbilities = {
    // Deutsche Namen
    'Akrobatik': 'DEX',
    'Athletik': 'STR',
    'Auftreten': 'CHA',
    'Einschüchtern': 'CHA',
    'Fingerfertigkeit': 'DEX',
    'Geschichte': 'INT',
    'Heilkunde': 'WIS',
    'Heimlichkeit': 'DEX',
    'Motiv erkennen': 'WIS',
    'Nachforschung': 'INT',
    'Naturkunde': 'INT',
    'Täuschen': 'CHA',
    'Überleben': 'WIS',
    'Überzeugen': 'CHA',
    'Wahrnehmung': 'WIS',
    'Tierkunde': 'WIS',
    'Arkane Kunde': 'INT',
    // Englische Namen
    'Acrobatics': 'DEX',
    'Athletics': 'STR',
    'Performance': 'CHA',
    'Intimidation': 'CHA',
    'Sleight of Hand': 'DEX',
    'History': 'INT',
    'Medicine': 'WIS',
    'Stealth': 'DEX',
    'Insight': 'WIS',
    'Investigation': 'INT',
    'Nature': 'INT',
    'Religion': 'INT', // Religion ist auf Deutsch und Englisch gleich
    'Deception': 'CHA',
    'Survival': 'WIS',
    'Persuasion': 'CHA',
    'Perception': 'WIS',
    'Animal Handling': 'WIS',
    'Arcana': 'INT',
  };

  /// Berechnet den Rettungswurf-Bonus
  int _getSavingThrowBonus(String saveName, PlayerCharacter character) {
    // Attribut ermitteln basierend auf dem Namen
    String ability = 'CON'; // Standard
    String normalizedName = saveName.toLowerCase();
    
    if (normalizedName.contains('str') || normalizedName.contains('stärke')) {
      ability = 'STR';
    } else if (normalizedName.contains('dex') || normalizedName.contains('geschick')) {
      ability = 'DEX';
    } else if (normalizedName.contains('con') || normalizedName.contains('konstitution')) {
      ability = 'CON';
    } else if (normalizedName.contains('int') || normalizedName.contains('intelligenz')) {
      ability = 'INT';
    } else if (normalizedName.contains('wis') || normalizedName.contains('weisheit')) {
      ability = 'WIS';
    } else if (normalizedName.contains('cha') || normalizedName.contains('charisma')) {
      ability = 'CHA';
    }
    
    int abilityScore;
    switch (ability) {
      case 'STR':
        abilityScore = character.strength;
        break;
      case 'DEX':
        abilityScore = character.dexterity;
        break;
      case 'CON':
        abilityScore = character.constitution;
        break;
      case 'INT':
        abilityScore = character.intelligence;
        break;
      case 'WIS':
        abilityScore = character.wisdom;
        break;
      case 'CHA':
        abilityScore = character.charisma;
        break;
      default:
        abilityScore = 10;
    }
    
    // Modifikator berechnen
    int modifier = ((abilityScore - 10) ~/ 2);
    
    // Kompetenzbonus addieren (ist ja geübt)
    modifier += character.proficiencyBonus;
    
    return modifier;
  }

  /// Helper für Saving Throw-Chips
  Widget _buildSavingThrowChip(String saveName, int bonus) {
    final modText = bonus >= 0 ? '+$bonus' : '$bonus';
    
    // Gold/Amber für Rettungswürfe
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber[900]?.withValues(alpha: 0.3) ?? const Color(0x4DFF6F00),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.amber[600] ?? const Color(0xFFFFB300),
          width: 1,
        ),
      ),
      child: Text(
        '$saveName $modText',
        style: TextStyle(
          color: Colors.amber[200] ?? const Color(0xFFFFE082),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Berechnet den Fertigkeitsbonus
  int _getSkillBonus(String skillName, PlayerCharacter character) {
    // Attribut ermitteln
    final ability = _skillAbilities[skillName] ?? 'DEX';
    int abilityScore;
    
    switch (ability) {
      case 'STR':
        abilityScore = character.strength;
        break;
      case 'DEX':
        abilityScore = character.dexterity;
        break;
      case 'CON':
        abilityScore = character.constitution;
        break;
      case 'INT':
        abilityScore = character.intelligence;
        break;
      case 'WIS':
        abilityScore = character.wisdom;
        break;
      case 'CHA':
        abilityScore = character.charisma;
        break;
      default:
        abilityScore = 10;
    }
    
    // Modifikator berechnen
    int modifier = ((abilityScore - 10) ~/ 2);
    
    // Kompetenzbonus addieren wenn geübt
    if (character.proficientSkills.contains(skillName)) {
      modifier += character.proficiencyBonus;
    }
    
    return modifier;
  }

  /// Baut die Stats- und Angriffs-Anzeige für einen Teilnehmer
  Widget _buildStatsAndAttacks(PlayerCharacter? character, Creature? creature) {
    final List<Widget> statChips = [];
    
    if (character != null) {
      // Attributs-Boni (kompakt in einer Zeile)
      statChips.addAll([
        _buildAbilityChip('STR', character.strength),
        _buildAbilityChip('DEX', character.dexterity),
        _buildAbilityChip('CON', character.constitution),
        _buildAbilityChip('INT', character.intelligence),
        _buildAbilityChip('WIS', character.wisdom),
        _buildAbilityChip('CHA', character.charisma),
      ]);
      
      // Rettungswürfe (Saving Throws) - nur die geübten
      if (character.savingThrowProficiencies.isNotEmpty) {
        for (final save in character.savingThrowProficiencies.take(3)) {
          final bonus = _getSavingThrowBonus(save, character);
          statChips.add(_buildSavingThrowChip(save, bonus));
        }
      }
      
      // Fertigkeiten mit Boni (nur die geübten)
      if (character.proficientSkills.isNotEmpty) {
        for (final skill in character.proficientSkills.take(4)) {
          final bonus = _getSkillBonus(skill, character);
          statChips.add(_buildSkillChip(skill, bonus));
        }
      }
      
      // Angriffe für Helden
      if (character.attackList.isNotEmpty) {
        for (final attack in character.attackList.take(3)) {
          statChips.add(_buildAttackChip(attack.name, attack.totalDamage));
        }
      }
    } else if (creature != null) {
      // Attribute für Monster
      statChips.addAll([
        _buildAbilityChip('STR', creature.strength),
        _buildAbilityChip('DEX', creature.dexterity),
        _buildAbilityChip('CON', creature.constitution),
        _buildAbilityChip('INT', creature.intelligence),
        _buildAbilityChip('WIS', creature.wisdom),
        _buildAbilityChip('CHA', creature.charisma),
      ]);
      // Angriffe für Monster
      if (creature.attackList.isNotEmpty) {
        for (final attack in creature.attackList.take(3)) {
          statChips.add(_buildAttackChip(attack.name, attack.totalDamage));
        }
      }
    }
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: statChips,
    );
  }

  /// Helper für Ability-Score-Chips - zeigt nur den Bonus
  Widget _buildAbilityChip(String label, int score) {
    final modifier = ((score - 10) ~/ 2);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    // Farbe basierend auf Bonus-Stärke
    Color textColor;
    if (modifier >= 3) {
      textColor = Colors.green; // Sehr gut
    } else if (modifier >= 1) {
      textColor = Colors.lightGreen; // Gut
    } else if (modifier == 0) {
      textColor = Colors.white70; // Neutral
    } else if (modifier >= -2) {
      textColor = Colors.orange; // Leicht negativ
    } else {
      textColor = Colors.red; // Stark negativ
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: textColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        '$label $modText',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Helper für Skill-Chips
  Widget _buildSkillChip(String skillName, int bonus) {
    final modText = bonus >= 0 ? '+$bonus' : '$bonus';
    
    // Cyan/Türkis für Fertigkeiten
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.cyan[900]?.withValues(alpha: 0.3) ?? const Color(0x4D004D40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.cyan[600] ?? const Color(0xFF00ACC1),
          width: 1,
        ),
      ),
      child: Text(
        '$skillName $modText',
        style: TextStyle(
          color: Colors.cyan[200] ?? const Color(0xFF80DEEA),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Helper für Attack-Chips
  Widget _buildAttackChip(String name, String damage) {
    final bgColor = Colors.purple[900]?.withValues(alpha: 0.3) ?? const Color(0x4D4A148C);
    final borderColor = Colors.purple[700] ?? const Color(0xFF7B1FA2);
    final textColor = Colors.purple[200] ?? const Color(0xFFCE93D8);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        damage.isNotEmpty ? '$name ($damage)' : name,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildHpSection(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
    Color cardColor,
  ) {
    final hpPercent = participant.hpPercent;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // HP Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: hpPercent,
                  backgroundColor: Colors.black38,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hpPercent > 0.5
                        ? DnDTheme.successGreen
                        : (hpPercent > 0.2 ? Colors.amber : DnDTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Schnellaktionen
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Schaden Button
              _buildQuickButton(
                icon: Icons.remove,
                color: DnDTheme.errorRed,
                onPressed: () => _showDamageDialog(participant, viewModel),
                tooltip: 'Schaden',
              ),
              const SizedBox(width: 4),
              // Heilung Button
              _buildQuickButton(
                icon: Icons.add,
                color: DnDTheme.successGreen,
                onPressed: () => _showHealDialog(participant, viewModel),
                tooltip: 'Heilung',
              ),
              const SizedBox(width: 4),
              // Conditions Button
              _buildQuickButton(
                icon: Icons.shield,
                color: DnDTheme.arcaneBlue,
                onPressed: () => _showConditionsDialog(participant, viewModel),
                tooltip: 'Zustände',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildConditionsSection(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
    Color cardColor,
  ) {
    if (participant.conditions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text(
              'Keine Zustände',
              style: TextStyle(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: participant.conditions.map((condition) {
          return _buildConditionChip(condition, participant, viewModel);
        }).toList(),
      ),
    );
  }

  Widget _buildConditionChip(
    String condition,
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
  ) {
    return GestureDetector(
      onTap: () => viewModel.removeCondition(participant.id, condition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getConditionIcon(condition),
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              condition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              color: Colors.white70,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'blinded':
        return Icons.visibility_off;
      case 'charmed':
        return Icons.favorite;
      case 'deafened':
        return Icons.volume_off;
      case 'exhaustion':
        return Icons.battery_alert;
      case 'frightened':
        return Icons.warning;
      case 'grappled':
        return Icons.pan_tool;
      case 'incapacitated':
        return Icons.block;
      case 'invisible':
        return Icons.visibility;
      case 'paralyzed':
        return Icons.accessibility_new;
      case 'petrified':
        return Icons.texture;
      case 'poisoned':
        return Icons.sick;
      case 'prone':
        return Icons.airline_seat_flat;
      case 'restrained':
        return Icons.link;
      case 'stunned':
        return Icons.flash_on;
      case 'unconscious':
        return Icons.bedtime;
      default:
        return Icons.error_outline;
    }
  }

  Widget _buildFAB(EncounterTrackerViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.ancientGold,
          endColor: Colors.amber.shade700,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.ancientGold.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'encounter_next_turn',
        onPressed: viewModel.nextTurn,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.arrow_forward, color: DnDTheme.dungeonBlack),
        label: Text(
          'Zug beenden',
          style: TextStyle(
            color: DnDTheme.dungeonBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===== DIALOGS =====

  void _showInitiativeDialog(EncounterParticipant participant) {
    final controller = TextEditingController(
      text: _initiativeValues[participant.id]?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Initiative für ${participant.name}',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
        ),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Initiative',
                  labelStyle: TextStyle(color: DnDTheme.ancientGold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.ancientGold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.casino, color: DnDTheme.ancientGold),
              onPressed: () {
                int modifier = 0;
                
                final character = _viewModel.getCharacterForParticipant(participant);
                final creature = _viewModel.getCreatureForParticipant(participant);
                
                if (character != null) {
                  modifier = (character.dexterity - 10) ~/ 2;
                } else if (creature != null) {
                  modifier = (creature.dexterity - 10) ~/ 2;
                }
                
                final roll = Random().nextInt(20) + 1 + modifier;
                controller.text = roll.toString();
              },
              tooltip: 'Würfeln (W20 + DEX)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                setState(() {
                  _initiativeValues[participant.id] = value;
                });
                _sortParticipantsByInitiative();
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDamageDialog(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
  ) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.flash_on, color: DnDTheme.errorRed),
            const SizedBox(width: 8),
            Text(
              'Schaden für ${participant.name}',
              style: DnDTheme.headline3.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Schaden',
            labelStyle: TextStyle(color: DnDTheme.errorRed),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: DnDTheme.errorRed),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: DnDTheme.errorRed, width: 2),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              await viewModel.applyDamage(participant.id, amount);
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Schaden anwenden'),
          ),
        ],
      ),
    );
  }

  void _showHealDialog(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
  ) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.healing, color: DnDTheme.successGreen),
            const SizedBox(width: 8),
            Text(
              'Heilung für ${participant.name}',
              style: DnDTheme.headline3.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Heilung',
            labelStyle: TextStyle(color: DnDTheme.successGreen),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: DnDTheme.successGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: DnDTheme.successGreen, width: 2),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              await viewModel.applyHeal(participant.id, amount);
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Heilen'),
          ),
        ],
      ),
    );
  }

  void _showConditionsDialog(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.shield, color: DnDTheme.arcaneBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zustände für ${participant.name}',
                style: DnDTheme.headline3.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: Condition.values.length,
            itemBuilder: (context, index) {
              final condition = Condition.values[index];
              final conditionName = condition.toString().split('.').last;
              final hasCondition = participant.conditions.contains(conditionName);
              
              return CheckboxListTile(
                title: Text(
                  conditionName,
                  style: TextStyle(
                    color: hasCondition ? DnDTheme.ancientGold : Colors.white,
                    fontWeight: hasCondition ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _getConditionDescription(conditionName),
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                secondary: Icon(
                  _getConditionIcon(conditionName),
                  color: hasCondition ? DnDTheme.ancientGold : Colors.white54,
                ),
                value: hasCondition,
                activeColor: DnDTheme.ancientGold,
                checkColor: DnDTheme.dungeonBlack,
                onChanged: (bool? value) async {
                  if (value == true) {
                    await viewModel.addCondition(participant.id, conditionName);
                  } else {
                    await viewModel.removeCondition(participant.id, conditionName);
                  }
                  // Dialog neu bauen
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showConditionsDialog(participant, viewModel);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  String _getConditionDescription(String condition) {
    switch (condition.toLowerCase()) {
      case 'blinded':
        return 'Kann nicht sehen, -2 auf AC';
      case 'charmed':
        return 'Kann den Verzauberer nicht angreifen';
      case 'deafened':
        return 'Kann nicht hören';
      case 'exhaustion':
        return 'Abgeschwächt durch Erschöpfung';
      case 'frightened':
        return 'Hat Nachteil bei Angriffen';
      case 'grappled':
        return 'Bewegungsrate 0';
      case 'incapacitated':
        return 'Kann keine Aktionen ausführen';
      case 'invisible':
        return 'Unsichtbar für andere';
      case 'paralyzed':
        return 'Gelähmt, automatisch getroffen';
      case 'petrified':
        return 'Versteinert';
      case 'poisoned':
        return 'Nachteil bei Angriffen';
      case 'prone':
        return 'Liegend, -2 auf Nahkampf-AC';
      case 'restrained':
        return 'Bewegung eingeschränkt';
      case 'stunned':
        return 'Betäubt, keine Aktionen';
      case 'unconscious':
        return 'Bewusstlos, liegt am Boden';
      default:
        return '';
    }
  }

  void _showParticipantContextMenu(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: DnDTheme.slateGrey,
            endColor: DnDTheme.stoneGrey,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(DnDTheme.radiusLarge),
            topRight: Radius.circular(DnDTheme.radiusLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.flash_on, color: DnDTheme.errorRed),
                title: Text('Schaden', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDamageDialog(participant, viewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.healing, color: DnDTheme.successGreen),
                title: Text('Heilung', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showHealDialog(participant, viewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.shield, color: DnDTheme.arcaneBlue),
                title: Text('Zustände', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showConditionsDialog(participant, viewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.casino, color: DnDTheme.ancientGold),
                title: Text('Initiative setzen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showInitiativeDialog(participant);
                },
              ),
              if (participant.isAlive)
                ListTile(
                  leading: Icon(Icons.dangerous, color: DnDTheme.errorRed),
                  title: Text('Töten (HP auf 0)', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await viewModel.setHp(participant.id, 0);
                  },
                ),
              if (participant.isDead)
                ListTile(
                  leading: Icon(Icons.refresh, color: DnDTheme.successGreen),
                  title: Text('Wiederbeleben', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await viewModel.setHp(participant.id, participant.maxHp);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParticipantContextMenuAt(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
    Offset position,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'damage',
          child: Row(
            children: [
              Icon(Icons.flash_on, color: DnDTheme.errorRed),
              const SizedBox(width: 8),
              Text('Schaden'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'heal',
          child: Row(
            children: [
              Icon(Icons.healing, color: DnDTheme.successGreen),
              const SizedBox(width: 8),
              Text('Heilung'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'condition',
          child: Row(
            children: [
              Icon(Icons.shield, color: DnDTheme.arcaneBlue),
              const SizedBox(width: 8),
              Text('Zustände'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'initiative',
          child: Row(
            children: [
              Icon(Icons.casino, color: DnDTheme.ancientGold),
              const SizedBox(width: 8),
              Text('Initiative'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'damage') _showDamageDialog(participant, viewModel);
      if (value == 'heal') _showHealDialog(participant, viewModel);
      if (value == 'condition') _showConditionsDialog(participant, viewModel);
      if (value == 'initiative') _showInitiativeDialog(participant);
    });
  }

  void _showEndEncounterDialog(EncounterTrackerViewModel viewModel) {
    final winner = viewModel.getWinner();
    String resultText = 'Möchtest du den Kampf beenden?';
    
    if (winner == ParticipantType.player) {
      resultText = 'Die Helden haben gewonnen! Kampf beenden?';
    } else if (winner == ParticipantType.enemy) {
      resultText = 'Die Gegner haben gewonnen! Kampf beenden?';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.stop_circle, color: DnDTheme.errorRed),
            const SizedBox(width: 8),
            Text(
              'Kampf beenden',
              style: DnDTheme.headline3.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultText,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Zusammenfassung
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Helden',
                        viewModel.alivePlayersCount,
                        DnDTheme.arcaneBlue,
                      ),
                      _buildSummaryItem(
                        'Gegner',
                        viewModel.aliveEnemiesCount,
                        DnDTheme.errorRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Runden: ${viewModel.roundCounter}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await viewModel.completeEncounter();
              if (mounted) {
                Navigator.of(context).pop(); // Dialog
                Navigator.of(context).pop(); // Screen
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kampf beenden'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: DnDTheme.errorRed, size: 64),
            const SizedBox(height: 16),
            Text(
              'Fehler',
              style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _viewModel.loadEncounter(widget.encounterId),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          Text(
            'Keine Teilnehmer',
            style: DnDTheme.headline3.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Dieser Encounter hat keine Teilnehmer.',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}