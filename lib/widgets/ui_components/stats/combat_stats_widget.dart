import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class CombatStatsWidget extends StatelessWidget {
  const CombatStatsWidget({
    super.key,
    this.maxHp,
    this.currentHp,
    this.armorClass,
    this.challengeRating,
    this.speed,
    this.onMaxHpChanged,
    this.onCurrentHpChanged,
    this.onArmorClassChanged,
    this.onChallengeRatingChanged,
    this.onSpeedChanged,
    this.isEditable = true,
  });

  final int? maxHp;
  final int? currentHp;
  final int? armorClass;
  final int? challengeRating;
  final String? speed;
  final void Function(int)? onMaxHpChanged;
  final void Function(int)? onCurrentHpChanged;
  final void Function(int)? onArmorClassChanged;
  final void Function(int)? onChallengeRatingChanged;
  final void Function(String)? onSpeedChanged;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Column(
      children: [
        _buildStatRow(
          label: 'Lebenspunkte',
          icon: Icons.favorite,
          C: C,
          children: [
            Expanded(child: _buildNumberField(label: 'Max. LP', value: maxHp, onChanged: onMaxHpChanged, C: C)),
            const SizedBox(width: 12),
            Expanded(child: _buildNumberField(label: 'Aktuelle LP', value: currentHp, onChanged: onCurrentHpChanged, C: C)),
          ],
        ),
        const SizedBox(height: 12),
        _buildNumberField(label: 'Rüstungsklasse', icon: Icons.shield, value: armorClass, onChanged: onArmorClassChanged, C: C),
        const SizedBox(height: 12),
        _buildNumberField(label: 'Herausforderungsgrad', icon: Icons.star, value: challengeRating, onChanged: onChallengeRatingChanged, C: C, allowZero: true),
        const SizedBox(height: 12),
        _buildTextField(label: 'Bewegungsrate', icon: Icons.speed, value: speed ?? '30ft', onChanged: onSpeedChanged, C: C),
      ],
    );
  }

  Widget _buildStatRow({
    required String label,
    required IconData icon,
    required List<Widget> children,
    required AppColorsExtension C,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: C.amber, size: 16),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.textSoft)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: children),
          ],
        ),
      );

  Widget _buildNumberField({
    required String label,
    required int? value,
    required void Function(int)? onChanged,
    required AppColorsExtension C,
    IconData? icon,
    bool allowZero = false,
  }) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      enabled: isEditable,
      style: TextStyle(fontSize: 16, color: C.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: C.amber, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: C.accent),
        ),
        filled: true,
        fillColor: C.bgPanel,
        labelStyle: TextStyle(color: C.textSoft, fontSize: 13),
      ),
      onChanged: onChanged != null && isEditable
          ? (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && (allowZero || parsed > 0)) {
                onChanged(parsed);
              }
            }
          : null,
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required void Function(String)? onChanged,
    required AppColorsExtension C,
    IconData? icon,
  }) {
    final controller = TextEditingController(text: value);
    return TextField(
      controller: controller,
      enabled: isEditable,
      style: TextStyle(fontSize: 16, color: C.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: C.amber, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: C.accent),
        ),
        filled: true,
        fillColor: C.bgPanel,
        labelStyle: TextStyle(color: C.textSoft, fontSize: 13),
      ),
      onChanged: onChanged != null && isEditable ? onChanged : null,
    );
  }
}

// ── COMBAT STAT CHIP ──────────────────────────────────────────────────────────

class CombatStatChip extends StatelessWidget {
  const CombatStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

// ── COMBAT STATS ROW ─────────────────────────────────────────────────────────

class CombatStatsRow extends StatelessWidget {
  const CombatStatsRow({
    required this.maxHp,
    required this.armorClass,
    required this.initiativeBonus,
    required this.speed,
    super.key,
  });

  final int maxHp;
  final int armorClass;
  final int initiativeBonus;
  final int speed;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: CombatStatChip(icon: Icons.favorite, label: 'HP', value: '$maxHp', color: Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: CombatStatChip(icon: Icons.shield, label: 'AC', value: '$armorClass', color: Colors.blue)),
          const SizedBox(width: 8),
          Expanded(
            child: CombatStatChip(
              icon: Icons.flash_on,
              label: 'Init',
              value: initiativeBonus >= 0 ? '+$initiativeBonus' : '$initiativeBonus',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: CombatStatChip(icon: Icons.speed, label: 'Bew.', value: '$speed ft', color: Colors.green)),
        ],
      );
}

// ── CURRENCY WIDGET ───────────────────────────────────────────────────────────

class CurrencyWidget extends StatelessWidget {
  const CurrencyWidget({
    required this.gold,
    required this.silver,
    required this.copper,
    super.key,
  });

  final double gold;
  final double silver;
  final double copper;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber[50]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200]!.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            if (gold > 0) ...[
              Icon(Icons.monetization_on, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text('${gold.toStringAsFixed(0)} Gold',
                  style: TextStyle(fontSize: 11, color: Colors.amber[800], fontWeight: FontWeight.w600)),
              if (silver > 0 || copper > 0) const SizedBox(width: 12),
            ],
            if (silver > 0) ...[
              Icon(Icons.circle, size: 8, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('${silver.toStringAsFixed(0)} Silber',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              if (copper > 0) const SizedBox(width: 12),
            ],
            if (copper > 0) ...[
              Icon(Icons.circle, size: 8, color: Colors.brown[400]),
              const SizedBox(width: 4),
              Text('${copper.toStringAsFixed(0)} Kupfer',
                  style: TextStyle(fontSize: 11, color: Colors.brown[700], fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
}
