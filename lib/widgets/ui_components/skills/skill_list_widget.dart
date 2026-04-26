import 'package:flutter/material.dart';

import '../../../game_data/dnd_models.dart';
import '../../../theme/app_theme.dart';

class SkillItemWidget extends StatelessWidget {
  const SkillItemWidget({
    required this.skill,
    required this.bonus,
    required this.isProficient,
    required this.onTap,
    super.key,
  });

  final DndSkill skill;
  final String bonus;
  final bool isProficient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isProficient ? C.greenSoft : C.bgPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isProficient ? C.green.withValues(alpha: 0.4) : C.border),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isProficient ? C.green : C.bgHover,
            shape: BoxShape.circle,
          ),
          child: isProficient
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Icon(Icons.check_box_outline_blank, color: C.textSoft, size: 18),
        ),
        title: Text(
          skill.name,
          style: TextStyle(
            color: C.text,
            fontWeight: isProficient ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: C.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: C.amber.withValues(alpha: 0.3)),
          ),
          child: Text(
            bonus,
            style: TextStyle(color: C.amber, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ── SKILL SECTION ─────────────────────────────────────────────────────────────

class SkillSectionWidget extends StatelessWidget {
  const SkillSectionWidget({
    required this.ability,
    required this.skills,
    required this.skillBonuses,
    required this.proficientSkills,
    required this.onSkillToggle,
    super.key,
  });

  final Ability ability;
  final List<DndSkill> skills;
  final Map<String, String> skillBonuses;
  final Set<String> proficientSkills;
  final void Function(String) onSkillToggle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 4),
          ...skills.map((skill) => SkillItemWidget(
                skill: skill,
                bonus: skillBonuses[skill.name] ?? '+0',
                isProficient: proficientSkills.contains(skill.name),
                onTap: () => onSkillToggle(skill.name),
              )),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildHeader(BuildContext context) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Icon(_abilityIcon(ability), color: C.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            _abilityName(ability),
            style: TextStyle(color: C.amber, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _abilityIcon(Ability a) {
    switch (a) {
      case Ability.strength:
        return Icons.fitness_center;
      case Ability.dexterity:
        return Icons.flash_on;
      case Ability.constitution:
        return Icons.favorite;
      case Ability.intelligence:
        return Icons.school;
      case Ability.wisdom:
        return Icons.psychology;
      case Ability.charisma:
        return Icons.people;
    }
  }

  String _abilityName(Ability a) {
    switch (a) {
      case Ability.strength:
        return 'Stärke';
      case Ability.dexterity:
        return 'Geschicklichkeit';
      case Ability.constitution:
        return 'Konstitution';
      case Ability.intelligence:
        return 'Intelligenz';
      case Ability.wisdom:
        return 'Weisheit';
      case Ability.charisma:
        return 'Charisma';
    }
  }
}

// ── SKILL SELECTION ───────────────────────────────────────────────────────────

class SkillSelectionWidget extends StatelessWidget {
  const SkillSelectionWidget({
    required this.skillsByAbility,
    required this.skillBonuses,
    required this.proficientSkills,
    required this.onSkillToggle,
    super.key,
    this.searchQuery = '',
  });

  final Map<Ability, List<DndSkill>> skillsByAbility;
  final Map<String, String> skillBonuses;
  final Set<String> proficientSkills;
  final void Function(String) onSkillToggle;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final filtered = skillsByAbility.entries
        .where((e) => searchQuery.isEmpty || e.value.any((s) => s.name.toLowerCase().contains(searchQuery)))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      child: Column(
        children: [
          if (searchQuery.isNotEmpty) ...[
            _buildSearchIndicator(searchQuery, filtered.length, C),
            const SizedBox(height: 12),
          ],
          ...filtered.map((e) => SkillSectionWidget(
                ability: e.key,
                skills: searchQuery.isEmpty
                    ? e.value
                    : e.value.where((s) => s.name.toLowerCase().contains(searchQuery)).toList(),
                skillBonuses: skillBonuses,
                proficientSkills: proficientSkills,
                onSkillToggle: onSkillToggle,
              )),
        ],
      ),
    );
  }

  Widget _buildSearchIndicator(String query, int count, AppColorsExtension C) => Row(
        children: [
          Icon(Icons.search, color: C.amber),
          const SizedBox(width: 8),
          Text(
            'Suchergebnisse für: "$query"',
            style: TextStyle(color: C.amber, fontStyle: FontStyle.italic),
          ),
          const Spacer(),
          Text('$count Sektionen', style: TextStyle(color: C.amber, fontSize: 12)),
        ],
      );
}

// ── SKILL SEARCH FIELD ────────────────────────────────────────────────────────

class SkillSearchField extends StatelessWidget {
  const SkillSearchField({required this.query, required this.onChanged, super.key});

  final String query;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Fertigkeiten durchsuchen...',
          hintStyle: TextStyle(color: C.textSoft, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: C.amber),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        style: TextStyle(color: C.text, fontSize: 13),
      ),
    );
  }
}

// ── SKILL SELECTION WITH SEARCH ───────────────────────────────────────────────

class SkillSelectionWithSearch extends StatelessWidget {
  const SkillSelectionWithSearch({
    required this.skillsByAbility,
    required this.skillBonuses,
    required this.proficientSkills,
    required this.onSkillToggle,
    required this.searchQuery,
    required this.onSearchChanged,
    super.key,
  });

  final Map<Ability, List<DndSkill>> skillsByAbility;
  final Map<String, String> skillBonuses;
  final Set<String> proficientSkills;
  final void Function(String) onSkillToggle;
  final String searchQuery;
  final void Function(String) onSearchChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SkillSearchField(query: searchQuery, onChanged: onSearchChanged),
          const SizedBox(height: 16),
          SkillSelectionWidget(
            skillsByAbility: skillsByAbility,
            skillBonuses: skillBonuses,
            proficientSkills: proficientSkills,
            onSkillToggle: onSkillToggle,
            searchQuery: searchQuery,
          ),
        ],
      );
}
