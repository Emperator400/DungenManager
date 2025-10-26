import 'package:flutter/material.dart';
import '../../models/player_character.dart';
import 'character_list_helpers.dart';

/// Widget für die Anzeige des Helden-Avatars mit Bild-Fallback und Klassenfarben
class HeroAvatarWidget extends StatelessWidget {
  final PlayerCharacter character;
  final double size;
  final bool showLevelBadge;
  final bool showAlignment;

  const HeroAvatarWidget({
    super.key,
    required this.character,
    this.size = 60.0,
    this.showLevelBadge = true,
    this.showAlignment = false,
  });

  @override
  Widget build(BuildContext context) {
    final classColor = CharacterListHelpers.getClassColor(character.className);
    final levelBadgeColor = CharacterListHelpers.getLevelBadgeColor(character.level);
    final levelBadgeText = CharacterListHelpers.getLevelBadgeText(character.level);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Haupt-Avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  classColor.withOpacity(0.8),
                  classColor.withOpacity(0.6),
                ],
              ),
              border: Border.all(
                color: classColor.withOpacity(0.3),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: classColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.13),
              child: _buildAvatarContent(),
            ),
          ),

          // Level Badge
          if (showLevelBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  color: levelBadgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        levelBadgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Gesinnungs-Indikator
          if (showAlignment && character.alignment != null)
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: CharacterListHelpers.getAlignmentColor(character.alignment),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),

          // Favorit-Stern
          if (character.isFavorite)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.amber[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Wenn ein Bildpfad vorhanden ist, versuche es zu laden
    if (character.imagePath != null && character.imagePath!.isNotEmpty) {
      return Image.network(
        character.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar();
        },
      );
    }

    // Standard-Avatar mit Klassen-Icon
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    final classIcon = _getClassIcon(character.className);
    
    return Container(
      width: size,
      height: size,
      color: Colors.white.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            classIcon,
            color: Colors.white.withOpacity(0.9),
            size: size * 0.4,
          ),
          SizedBox(height: size * 0.05),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                _getClassShortName(character.className),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getClassIcon(String className) {
    switch (className.toLowerCase()) {
      case 'krieger':
      case 'barbar':
        return Icons.sports_martial_arts;
      case 'paladin':
        return Icons.shield;
      case 'kleriker':
      case 'druide':
      case 'mönch':
        return Icons.self_improvement;
      case 'magier':
      case 'hexenmeister':
      case 'bard':
        return Icons.auto_stories;
      case 'schurke':
      case 'schütze':
        return Icons.gps_fixed;
      case 'todesritter':
        return Icons.dangerous;
      default:
        return Icons.person;
    }
  }

  String _getClassShortName(String className) {
    switch (className.toLowerCase()) {
      case 'krieger':
        return 'KRI';
      case 'barbar':
        return 'BAR';
      case 'paladin':
        return 'PAL';
      case 'kleriker':
        return 'KLE';
      case 'magier':
        return 'MAG';
      case 'hexenmeister':
        return 'HEX';
      case 'schurke':
        return 'SCH';
      case 'schütze':
        return 'SCH';
      case 'druide':
        return 'DRU';
      case 'mönch':
        return 'MÖN';
      case 'bard':
        return 'BAR';
      case 'todesritter':
        return 'TOT';
      default:
        return className.length > 6 ? className.substring(0, 3).toUpperCase() : className.toUpperCase();
    }
  }
}
