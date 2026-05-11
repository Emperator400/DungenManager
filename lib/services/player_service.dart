import '../models/player.dart';
import '../models/player_character.dart';
import '../database/repositories/player_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import 'exceptions/service_exceptions.dart';

class PlayerWithCharacters {
  final Player player;
  final List<PlayerCharacter> characters;

  const PlayerWithCharacters({required this.player, required this.characters});
}

class PlayerService {
  final PlayerModelRepository _playerRepository;
  final PlayerCharacterModelRepository _characterRepository;

  PlayerService({
    required PlayerModelRepository playerRepository,
    required PlayerCharacterModelRepository characterRepository,
  })  : _playerRepository = playerRepository,
        _characterRepository = characterRepository;

  Future<ServiceResult<List<Player>>> getAllPlayers() =>
      performServiceOperation('getAllPlayers', () => _playerRepository.findAllSorted());

  Future<ServiceResult<Player?>> getPlayerById(String id) =>
      performServiceOperation('getPlayerById', () => _playerRepository.findById(id));

  Future<ServiceResult<Player>> createPlayer(Player player) =>
      performServiceOperation('createPlayer', () => _playerRepository.create(player));

  Future<ServiceResult<Player>> updatePlayer(Player player) =>
      performServiceOperation('updatePlayer', () => _playerRepository.update(player));

  Future<ServiceResult<void>> deletePlayer(String playerId) =>
      performServiceOperation('deletePlayer', () async {
        final chars = await _characterRepository.findWhere(
          where: 'player_id = ?',
          whereArgs: [playerId],
        );
        for (final c in chars) {
          await _characterRepository.update(c.copyWith(playerId: ''));
        }
        await _playerRepository.delete(playerId);
      });

  Future<ServiceResult<List<PlayerCharacter>>> getCharactersForPlayer(String playerId) =>
      performServiceOperation(
        'getCharactersForPlayer',
        () => _characterRepository.findWhere(
          where: 'player_id = ?',
          whereArgs: [playerId],
        ),
      );

  Future<ServiceResult<void>> assignCharacterToPlayer(
    String characterId,
    String playerId,
  ) =>
      performServiceOperation('assignCharacterToPlayer', () async {
        final char = await _characterRepository.findById(characterId);
        if (char == null) return;
        final player = await _playerRepository.findById(playerId);
        await _characterRepository.update(
          char.copyWith(
            playerId: playerId,
            playerName: player?.name ?? char.playerName,
          ),
        );
      });

  Future<ServiceResult<void>> unassignCharacterFromPlayer(String characterId) =>
      performServiceOperation('unassignCharacterFromPlayer', () async {
        final char = await _characterRepository.findById(characterId);
        if (char == null) return;
        await _characterRepository.update(char.copyWith(playerId: ''));
      });

  Future<ServiceResult<List<PlayerWithCharacters>>> getPlayersWithCharacters() =>
      performServiceOperation('getPlayersWithCharacters', () async {
        final players = await _playerRepository.findAllSorted();
        final result = <PlayerWithCharacters>[];
        for (final p in players) {
          final chars = await _characterRepository.findWhere(
            where: 'player_id = ?',
            whereArgs: [p.id],
          );
          result.add(PlayerWithCharacters(player: p, characters: chars));
        }
        return result;
      });
}
