import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/encounter_participant.dart';
import '../../models/condition.dart';
import '../../models/player_character.dart';
import '../../models/creature.dart';
import '../../models/attack.dart';
import '../../viewmodels/encounter_tracker_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

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
  final Map<String, int> _initiativeValues = {};
  final Map<String, TextEditingController> _initiativeControllers = {};

  @override
  void initState() {
    super.initState();
    _viewModel = EncounterTrackerViewModel();
    _viewModel.loadEncounter(widget.encounterId).then((_) {
      _applyInitialInitiativeValues();
    });
  }

  void _applyInitialInitiativeValues() {
    if (widget.initialInitiativeValues == null ||
        widget.initialInitiativeValues!.isEmpty) {
      return;
    }
    for (final participant in _viewModel.participants) {
      if (participant.characterId != null) {
        final charKey = 'char_${participant.characterId}';
        if (widget.initialInitiativeValues!.containsKey(charKey)) {
          _initiativeValues[participant.id] = widget.initialInitiativeValues![charKey]!;
        }
      }
      if (participant.creatureId != null) {
        final monsterKey = 'monster_${participant.creatureId}';
        if (widget.initialInitiativeValues!.containsKey(monsterKey)) {
          _initiativeValues[participant.id] = widget.initialInitiativeValues![monsterKey]!;
        }
      }
    }
    if (_initiativeValues.isNotEmpty) {
      _sortParticipantsByInitiative();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
      _viewModel.participants.sort((a, b) {
        if (a.isDead && b.isAlive) return 1;
        if (a.isAlive && b.isDead) return -1;
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
    final C = context.appColors;
    return ChangeNotifierProvider<EncounterTrackerViewModel>.value(
      value: _viewModel,
      child: Consumer<EncounterTrackerViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: C.bg,
            appBar: _buildAppBar(viewModel),
            body: _buildBody(viewModel),
            floatingActionButton: _buildFAB(viewModel),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(EncounterTrackerViewModel viewModel) {
    final C = context.appColors;
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.gavel, color: C.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.encounterTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Runde ${viewModel.roundCounter}',
                  style: TextStyle(fontSize: 12, color: C.amber),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: C.bgPanel,
      foregroundColor: Colors.white,
      elevation: 4,
      actions: [
        IconButton(
          icon: Icon(Icons.casino, color: C.amber),
          onPressed: _rollInitiativeForAll,
          tooltip: 'Alle Initiative würfeln',
        ),
        IconButton(
          icon: Icon(Icons.stop_circle, color: C.red),
          onPressed: () => _showEndEncounterDialog(viewModel),
          tooltip: 'Kampf beenden',
        ),
      ],
    );
  }

  Widget _buildBody(EncounterTrackerViewModel viewModel) {
    final C = context.appColors;
    if (viewModel.isLoading) {
      return Center(child: CircularProgressIndicator(color: C.amber));
    }
    if (viewModel.errorMessage != null) {
      return _buildErrorWidget(viewModel.errorMessage!);
    }
    if (viewModel.participants.isEmpty) {
      return _buildEmptyWidget();
    }
    for (final participant in viewModel.participants) {
      if (!_initiativeControllers.containsKey(participant.id)) {
        _initiativeControllers[participant.id] = TextEditingController(
          text: _initiativeValues[participant.id]?.toString() ?? '',
        );
      }
    }
    return Column(
      children: [
        _buildStatusBar(viewModel),
        Expanded(child: _buildParticipantsList(viewModel)),
      ],
    );
  }

  Widget _buildStatusBar(EncounterTrackerViewModel viewModel) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border(
          bottom: BorderSide(color: C.amber.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _buildStatusChip(
            icon: Icons.person,
            label: 'Helden: ${viewModel.alivePlayersCount}',
            color: C.accent,
          ),
          const SizedBox(width: 12),
          _buildStatusChip(
            icon: Icons.shield,
            label: 'Gegner: ${viewModel.aliveEnemiesCount}',
            color: C.red,
          ),
          const Spacer(),
          if (viewModel.currentParticipant != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: C.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.amber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: C.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Am Zug: ${viewModel.currentParticipant!.name}',
                    style: TextStyle(
                      fontSize: 13,
                      color: C.amber,
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
            style: const TextStyle(
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
    final C = context.appColors;
    final isPlayer = participant.type == ParticipantType.player;
    final cardColor = isPlayer ? C.accent : C.red;

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
          color: cardColor.withValues(alpha: isActive ? 0.8 : 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? C.amber : cardColor.withValues(alpha: 0.5),
            width: isActive ? 3 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: C.amber.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            _buildCardHeader(participant, initiative, isPlayer, cardColor),
            _buildHpSection(participant, viewModel, cardColor),
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
    final C = context.appColors;
    final character = _viewModel.getCharacterForParticipant(participant);
    final creature = _viewModel.getCreatureForParticipant(participant);
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: C.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: initiative != null
                      ? Text(
                          initiative.toString(),
                          style: TextStyle(
                            color: C.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.casino, color: C.amber, size: 20),
                          onPressed: () => _showInitiativeDialog(participant),
                          tooltip: 'Initiative setzen',
                        ),
                ),
              ),
              const SizedBox(width: 12),
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
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        if (participant.isDead) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: C.red,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: C.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: C.green.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'HP: ${participant.currentHp}/${participant.maxHp}',
                          style: TextStyle(
                            color: C.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (armorClass != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: C.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: C.amber.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'AC: $armorClass',
                            style: TextStyle(
                              color: C.amber,
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
          if (character != null || creature != null) ...[
            const SizedBox(height: 8),
            _buildStatsAndAttacks(character, creature),
          ],
        ],
      ),
    );
  }

  static const Map<String, String> _skillAbilities = {
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
    'Religion': 'INT',
    'Deception': 'CHA',
    'Survival': 'WIS',
    'Persuasion': 'CHA',
    'Perception': 'WIS',
    'Animal Handling': 'WIS',
    'Arcana': 'INT',
  };

  int _getSavingThrowBonus(String saveName, PlayerCharacter character) {
    String ability = 'CON';
    final normalizedName = saveName.toLowerCase();
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
    final abilityScore = switch (ability) {
      'STR' => character.strength,
      'DEX' => character.dexterity,
      'CON' => character.constitution,
      'INT' => character.intelligence,
      'WIS' => character.wisdom,
      'CHA' => character.charisma,
      _ => 10,
    };
    return ((abilityScore - 10) ~/ 2) + character.proficiencyBonus;
  }

  Widget _buildSavingThrowChip(String saveName, int bonus) {
    final C = context.appColors;
    final modText = bonus >= 0 ? '+$bonus' : '$bonus';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: C.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: C.amber.withValues(alpha: 0.6)),
      ),
      child: Text(
        '$saveName $modText',
        style: TextStyle(
          color: C.amber,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  int _getSkillBonus(String skillName, PlayerCharacter character) {
    final ability = _skillAbilities[skillName] ?? 'DEX';
    final abilityScore = switch (ability) {
      'STR' => character.strength,
      'DEX' => character.dexterity,
      'CON' => character.constitution,
      'INT' => character.intelligence,
      'WIS' => character.wisdom,
      'CHA' => character.charisma,
      _ => 10,
    };
    int modifier = (abilityScore - 10) ~/ 2;
    if (character.proficientSkills.contains(skillName)) {
      modifier += character.proficiencyBonus;
    }
    return modifier;
  }

  Widget _buildStatsAndAttacks(PlayerCharacter? character, Creature? creature) {
    final List<Widget> statChips = [];
    if (character != null) {
      statChips.addAll([
        _buildAbilityChip('STR', character.strength),
        _buildAbilityChip('DEX', character.dexterity),
        _buildAbilityChip('CON', character.constitution),
        _buildAbilityChip('INT', character.intelligence),
        _buildAbilityChip('WIS', character.wisdom),
        _buildAbilityChip('CHA', character.charisma),
      ]);
      for (final save in character.savingThrowProficiencies.take(3)) {
        statChips.add(_buildSavingThrowChip(save, _getSavingThrowBonus(save, character)));
      }
      for (final skill in character.proficientSkills.take(4)) {
        statChips.add(_buildSkillChip(skill, _getSkillBonus(skill, character)));
      }
      for (final attack in character.attackList.take(3)) {
        statChips.add(_buildAttackChip(attack.name, attack.totalDamage));
      }
    } else if (creature != null) {
      statChips.addAll([
        _buildAbilityChip('STR', creature.strength),
        _buildAbilityChip('DEX', creature.dexterity),
        _buildAbilityChip('CON', creature.constitution),
        _buildAbilityChip('INT', creature.intelligence),
        _buildAbilityChip('WIS', creature.wisdom),
        _buildAbilityChip('CHA', creature.charisma),
      ]);
      for (final attack in creature.attackList.take(3)) {
        statChips.add(_buildAttackChip(attack.name, attack.totalDamage));
      }
    }
    return Wrap(spacing: 6, runSpacing: 4, children: statChips);
  }

  Widget _buildAbilityChip(String label, int score) {
    final C = context.appColors;
    final modifier = (score - 10) ~/ 2;
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    final textColor = modifier >= 3
        ? C.green
        : modifier >= 1
            ? C.green
            : modifier == 0
                ? C.textMid
                : modifier >= -2
                    ? C.amber
                    : C.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label $modText',
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSkillChip(String skillName, int bonus) {
    final C = context.appColors;
    final modText = bonus >= 0 ? '+$bonus' : '$bonus';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: C.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: C.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$skillName $modText',
        style: TextStyle(
          color: C.accent,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttackChip(String name, String damage) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: C.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: C.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        damage.isNotEmpty ? '$name ($damage)' : name,
        style: TextStyle(
          color: C.accent,
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
    final C = context.appColors;
    final hpPercent = participant.hpPercent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: hpPercent,
              backgroundColor: Colors.black38,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              valueColor: AlwaysStoppedAnimation<Color>(
                hpPercent > 0.5
                    ? C.green
                    : (hpPercent > 0.2 ? C.amber : C.red),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuickButton(
                icon: Icons.remove,
                color: C.red,
                onPressed: () => _showDamageDialog(participant, viewModel),
                tooltip: 'Schaden',
              ),
              const SizedBox(width: 4),
              _buildQuickButton(
                icon: Icons.add,
                color: C.green,
                onPressed: () => _showHealDialog(participant, viewModel),
                tooltip: 'Heilung',
              ),
              const SizedBox(width: 4),
              _buildQuickButton(
                icon: Icons.shield,
                color: C.accent,
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
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white38, size: 14),
            SizedBox(width: 6),
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
        children: participant.conditions
            .map((condition) => _buildConditionChip(condition, participant, viewModel))
            .toList(),
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
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getConditionIcon(condition), color: Colors.white, size: 14),
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
            const Icon(Icons.close, color: Colors.white70, size: 12),
          ],
        ),
      ),
    );
  }

  IconData _getConditionIcon(String condition) {
    return switch (condition.toLowerCase()) {
      'blinded' => Icons.visibility_off,
      'charmed' => Icons.favorite,
      'deafened' => Icons.volume_off,
      'exhaustion' => Icons.battery_alert,
      'frightened' => Icons.warning,
      'grappled' => Icons.pan_tool,
      'incapacitated' => Icons.block,
      'invisible' => Icons.visibility,
      'paralyzed' => Icons.accessibility_new,
      'petrified' => Icons.texture,
      'poisoned' => Icons.sick,
      'prone' => Icons.airline_seat_flat,
      'restrained' => Icons.link,
      'stunned' => Icons.flash_on,
      'unconscious' => Icons.bedtime,
      _ => Icons.error_outline,
    };
  }

  Widget _buildFAB(EncounterTrackerViewModel viewModel) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.amber,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: C.amber.withValues(alpha: 0.4),
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
        icon: Icon(Icons.arrow_forward, color: C.bg),
        label: Text(
          'Zug beenden',
          style: TextStyle(color: C.bg, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showInitiativeDialog(EncounterParticipant participant) {
    final C = context.appColors;
    final controller = TextEditingController(
      text: _initiativeValues[participant.id]?.toString() ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text(
          'Initiative für ${participant.name}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: C.amber,
          ),
        ),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Initiative',
                  labelStyle: TextStyle(color: C.amber),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: C.amber),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: C.amber, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.casino, color: C.amber),
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
              backgroundColor: C.amber,
              foregroundColor: C.bg,
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
    final C = context.appColors;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            Icon(Icons.flash_on, color: C.red),
            const SizedBox(width: 8),
            Text(
              'Schaden für ${participant.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Schaden',
            labelStyle: TextStyle(color: C.red),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: C.red)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: C.red, width: 2)),
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
              backgroundColor: C.red,
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
    final C = context.appColors;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            Icon(Icons.healing, color: C.green),
            const SizedBox(width: 8),
            Text(
              'Heilung für ${participant.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Heilung',
            labelStyle: TextStyle(color: C.green),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: C.green)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: C.green, width: 2)),
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
              backgroundColor: C.green,
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
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            Icon(Icons.shield, color: C.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zustände für ${participant.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                    color: hasCondition ? C.amber : Colors.white,
                    fontWeight: hasCondition ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _getConditionDescription(conditionName),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                secondary: Icon(
                  _getConditionIcon(conditionName),
                  color: hasCondition ? C.amber : Colors.white54,
                ),
                value: hasCondition,
                activeColor: C.amber,
                checkColor: C.bg,
                onChanged: (bool? value) async {
                  if (value == true) {
                    await viewModel.addCondition(participant.id, conditionName);
                  } else {
                    await viewModel.removeCondition(participant.id, conditionName);
                  }
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
    return switch (condition.toLowerCase()) {
      'blinded' => 'Kann nicht sehen, -2 auf AC',
      'charmed' => 'Kann den Verzauberer nicht angreifen',
      'deafened' => 'Kann nicht hören',
      'exhaustion' => 'Abgeschwächt durch Erschöpfung',
      'frightened' => 'Hat Nachteil bei Angriffen',
      'grappled' => 'Bewegungsrate 0',
      'incapacitated' => 'Kann keine Aktionen ausführen',
      'invisible' => 'Unsichtbar für andere',
      'paralyzed' => 'Gelähmt, automatisch getroffen',
      'petrified' => 'Versteinert',
      'poisoned' => 'Nachteil bei Angriffen',
      'prone' => 'Liegend, -2 auf Nahkampf-AC',
      'restrained' => 'Bewegung eingeschränkt',
      'stunned' => 'Betäubt, keine Aktionen',
      'unconscious' => 'Bewusstlos, liegt am Boden',
      _ => '',
    };
  }

  void _showParticipantContextMenu(
    EncounterParticipant participant,
    EncounterTrackerViewModel viewModel,
  ) {
    final C = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.flash_on, color: C.red),
                title: const Text('Schaden', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDamageDialog(participant, viewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.healing, color: C.green),
                title: const Text('Heilung', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showHealDialog(participant, viewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.shield, color: C.accent),
                title: const Text('Zustände', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showConditionsDialog(participant, viewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.casino, color: C.amber),
                title: const Text('Initiative setzen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showInitiativeDialog(participant);
                },
              ),
              if (participant.isAlive)
                ListTile(
                  leading: Icon(Icons.dangerous, color: C.red),
                  title: const Text('Töten (HP auf 0)', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await viewModel.setHp(participant.id, 0);
                  },
                ),
              if (participant.isDead)
                ListTile(
                  leading: Icon(Icons.refresh, color: C.green),
                  title: const Text('Wiederbeleben', style: TextStyle(color: Colors.white)),
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
    final C = context.appColors;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'damage',
          child: Row(
            children: [Icon(Icons.flash_on, color: C.red), const SizedBox(width: 8), const Text('Schaden')],
          ),
        ),
        PopupMenuItem(
          value: 'heal',
          child: Row(
            children: [Icon(Icons.healing, color: C.green), const SizedBox(width: 8), const Text('Heilung')],
          ),
        ),
        PopupMenuItem(
          value: 'condition',
          child: Row(
            children: [Icon(Icons.shield, color: C.accent), const SizedBox(width: 8), const Text('Zustände')],
          ),
        ),
        PopupMenuItem(
          value: 'initiative',
          child: Row(
            children: [Icon(Icons.casino, color: C.amber), const SizedBox(width: 8), const Text('Initiative')],
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
    final C = context.appColors;
    final winner = viewModel.getWinner();
    String resultText = 'Möchtest du den Kampf beenden?';
    if (winner == ParticipantType.player) {
      resultText = 'Die Helden haben gewonnen! Kampf beenden?';
    } else if (winner == ParticipantType.enemy) {
      resultText = 'Die Gegner haben gewonnen! Kampf beenden?';
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            Icon(Icons.stop_circle, color: C.red),
            const SizedBox(width: 8),
            const Text(
              'Kampf beenden',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(resultText, style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 16),
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
                      _buildSummaryItem('Helden', viewModel.alivePlayersCount, C.accent),
                      _buildSummaryItem('Gegner', viewModel.aliveEnemiesCount, C.red),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Runden: ${viewModel.roundCounter}',
                    style: const TextStyle(color: Colors.white70),
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.green,
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
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    final C = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: C.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Fehler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: C.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _viewModel.loadEncounter(widget.encounterId),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, color: Colors.white38, size: 64),
          SizedBox(height: 16),
          Text(
            'Keine Teilnehmer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            'Dieser Encounter hat keine Teilnehmer.',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
