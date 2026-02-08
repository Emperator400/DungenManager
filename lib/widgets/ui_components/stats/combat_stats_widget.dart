import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbares Widget für D&D 5e Kampfwerte
/// 
/// Beispiele:
/// ```dart
/// CombatStatsWidget(
///   maxHp: viewModel.maxHp,
///   currentHp: viewModel.currentHp,
///   armorClass: viewModel.armorClass,
///   challengeRating: viewModel.challengeRating,
///   speed: viewModel.speed,
///   onMaxHpChanged: (value) => viewModel.updateMaxHp(value),
///   onCurrentHpChanged: (value) => viewModel.updateCurrentHp(value),
///   onArmorClassChanged: (value) => viewModel.updateArmorClass(value),
///   onChallengeRatingChanged: (value) => viewModel.updateChallengeRating(value),
///   onSpeedChanged: (value) => viewModel.updateSpeed(value),
/// )
/// ```
class CombatStatsWidget extends StatelessWidget {
  final int? maxHp;
  final int? currentHp;
  final int? armorClass;
  final int? challengeRating;
  final String? speed;
  final Function(int)? onMaxHpChanged;
  final Function(int)? onCurrentHpChanged;
  final Function(int)? onArmorClassChanged;
  final Function(int)? onChallengeRatingChanged;
  final Function(String)? onSpeedChanged;
  final bool isEditable;

  const CombatStatsWidget({
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HP Row
        _buildStatRow(
          label: 'Lebenspunkte',
          icon: Icons.favorite,
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'Max. LP',
                value: maxHp,
                onChanged: onMaxHpChanged,
                isEditable: isEditable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumberField(
                label: 'Aktuelle LP',
                value: currentHp,
                onChanged: onCurrentHpChanged,
                isEditable: isEditable,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // RK
        _buildNumberField(
          label: 'Rüstungsklasse',
          icon: Icons.shield,
          value: armorClass,
          onChanged: onArmorClassChanged,
          isEditable: isEditable,
        ),
        const SizedBox(height: 12),
        
        // SG
        _buildNumberField(
          label: 'Herausforderungsgrad',
          icon: Icons.star,
          value: challengeRating,
          onChanged: onChallengeRatingChanged,
          isEditable: isEditable,
          allowZero: true,
        ),
        const SizedBox(height: 12),
        
        // Bewegungsrate
        _buildTextField(
          label: 'Bewegungsrate',
          icon: Icons.speed,
          value: speed ?? '30ft',
          onChanged: onSpeedChanged,
          isEditable: isEditable,
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required String label,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DnDTheme.ancientGold, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: children),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int? value,
    required Function(int)? onChanged,
    IconData? icon,
    bool isEditable = true,
    bool allowZero = false,
  }) {
    final controller = TextEditingController(text: value?.toString() ?? '');

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      enabled: isEditable,
      style: DnDTheme.bodyText1.copyWith(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: DnDTheme.ancientGold, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          borderSide: BorderSide(color: DnDTheme.ancientGold),
        ),
        filled: true,
        fillColor: isEditable ? DnDTheme.slateGrey : DnDTheme.stoneGrey,
        labelStyle: DnDTheme.bodyText2.copyWith(
          color: Colors.grey.shade400,
        ),
      ),
      onChanged: onChanged != null && isEditable
          ? (newValue) {
              final parsedValue = int.tryParse(newValue);
              if (parsedValue != null && (allowZero || parsedValue > 0)) {
                onChanged(parsedValue);
              }
            }
          : null,
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String)? onChanged,
    IconData? icon,
    bool isEditable = true,
  }) {
    final controller = TextEditingController(text: value);

    return TextField(
      controller: controller,
      enabled: isEditable,
      style: DnDTheme.bodyText1.copyWith(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: DnDTheme.ancientGold, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          borderSide: BorderSide(color: DnDTheme.ancientGold),
        ),
        filled: true,
        fillColor: isEditable ? DnDTheme.slateGrey : DnDTheme.stoneGrey,
        labelStyle: DnDTheme.bodyText2.copyWith(
          color: Colors.grey.shade400,
        ),
      ),
      onChanged: onChanged != null && isEditable
          ? (newValue) {
              onChanged(newValue);
            }
          : null,
    );
  }
}
