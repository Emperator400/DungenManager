import 'package:flutter/material.dart';
import '../../../game_data/dnd_models.dart';
import '../../../theme/dnd_theme.dart';

/// Widget für einzelne Fertigkeit
class SkillItemWidget extends StatelessWidget {
  final DndSkill skill;
  final String bonus;
  final bool isProficient;
  final VoidCallback onTap;

  const SkillItemWidget({
    super.key,
    required this.skill,
    required this.bonus,
    required this.isProficient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isProficient 
            ? DnDTheme.successGreen.withValues(alpha: 0.2)
            : DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isProficient ? DnDTheme.successGreen : DnDTheme.slateGrey,
            shape: BoxShape.circle,
          ),
          child: isProficient
              ? Icon(Icons.check, color: Colors.white, size: 20)
              : Icon(Icons.check_box_outline_blank, color: Colors.white.withValues(alpha: 0.6), size: 20),
        ),
        title: Text(
          skill.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isProficient ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: DnDTheme.ancientGold,
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          ),
          child: Text(
            bonus,
            style: const TextStyle(
              color: DnDTheme.dungeonBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Widget für eine Sektion von Fertigkeiten (nach Attribut gruppiert)
class SkillSectionWidget extends StatelessWidget {
  final Ability ability;
  final List<DndSkill> skills;
  final Map<String, String> skillBonuses;
  final Set<String> proficientSkills;
  final Function(String) onSkillToggle;

  const SkillSectionWidget({
    super.key,
    required this.ability,
    required this.skills,
    required this.skillBonuses,
    required this.proficientSkills,
    required this.onSkillToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 4),
        ...skills.map((skill) {
          final bonus = skillBonuses[skill.name] ?? '+0';
          final isProficient = proficientSkills.contains(skill.name);

          return SkillItemWidget(
            skill: skill,
            bonus: bonus,
            isProficient: isProficient,
            onTap: () => onSkillToggle(skill.name),
          );
        }).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DnDTheme.md,
        vertical: DnDTheme.sm,
      ),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            _getAbilityIcon(ability),
            color: DnDTheme.ancientGold,
            size: 20,
          ),
          const SizedBox(width: DnDTheme.sm),
          Text(
            _getAbilityName(ability),
            style: const TextStyle(
              color: DnDTheme.ancientGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAbilityIcon(Ability ability) {
    switch (ability) {
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

  String _getAbilityName(Ability ability) {
    switch (ability) {
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

/// Vollständiges Widget für die Fertigkeitsauswahl
class SkillSelectionWidget extends StatelessWidget {
  final Map<Ability, List<DndSkill>> skillsByAbility;
  final Map<String, String> skillBonuses;
  final Set<String> proficientSkills;
  final Function(String) onSkillToggle;
  final String searchQuery;

  const SkillSelectionWidget({
    super.key,
    required this.skillsByAbility,
    required this.skillBonuses,
    required this.proficientSkills,
    required this.onSkillToggle,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final filteredSections = skillsByAbility.entries
        .where((entry) {
          if (searchQuery.isEmpty) return true;
          return entry.value.any((skill) =>
              skill.name.toLowerCase().contains(searchQuery));
        })
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DnDTheme.dungeonBlack,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        children: [
          if (searchQuery.isNotEmpty) ...[
            _buildSearchIndicator(searchQuery),
            const SizedBox(height: 12),
          ],
          ...filteredSections.map((entry) {
            return SkillSectionWidget(
              ability: entry.key,
              skills: entry.value
                  .where((skill) => searchQuery.isEmpty ||
                      skill.name.toLowerCase().contains(searchQuery))
                  .toList(),
              skillBonuses: skillBonuses,
              proficientSkills: proficientSkills,
              onSkillToggle: onSkillToggle,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchIndicator(String query) {
    final count = filteredSectionsCount;
    return Row(
      children: [
        Icon(Icons.search, color: DnDTheme.ancientGold),
        const SizedBox(width: DnDTheme.sm),
        Text(
          'Suchergebnisse für: "$query"',
          style: TextStyle(
            color: DnDTheme.ancientGold,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Text(
          '$count Sektionen',
          style: TextStyle(
            color: DnDTheme.ancientGold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int get filteredSectionsCount {
    return skillsByAbility.entries
        .where((entry) {
          if (searchQuery.isEmpty) return true;
          return entry.value.any((skill) =>
              skill.name.toLowerCase().contains(searchQuery));
        })
        .length;
  }
}

/// Suchfeld für Fertigkeiten
class SkillSearchField extends StatelessWidget {
  final String query;
  final Function(String) onChanged;

  const SkillSearchField({
    super.key,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Fertigkeiten durchsuchen...',
          hintStyle: DnDTheme.bodyText2.copyWith(
            color: Colors.white60,
          ),
          prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(DnDTheme.sm),
        ),
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Komplettes Widget für die Fertigkeitsauswahl mit Suche
class SkillSelectionWithSearch extends StatelessWidget {
  final Map<Ability, List<DndSkill>> skillsByAbility;
  final Map<String, String> skillBonuses;
  final Set<String> proficientSkills;
  final Function(String) onSkillToggle;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const SkillSelectionWithSearch({
    super.key,
    required this.skillsByAbility,
    required this.skillBonuses,
    required this.proficientSkills,
    required this.onSkillToggle,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkillSearchField(
          query: searchQuery,
          onChanged: onSearchChanged,
        ),
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
}
