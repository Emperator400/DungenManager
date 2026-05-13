import 'package:flutter/foundation.dart';

import '../models/player.dart';
import '../models/player_character.dart';
import '../services/player_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final PlayerService _service;

  PlayerViewModel({required PlayerService playerService}) : _service = playerService;

  List<Player> _players = [];
  List<PlayerWithCharacters> _playersWithCharacters = [];
  bool _isLoading = false;
  String? _error;

  List<Player> get players => _players;
  List<PlayerWithCharacters> get playersWithCharacters => _playersWithCharacters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadPlayers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.getAllPlayers();
    if (result.isSuccess) {
      _players = result.data ?? [];
    } else {
      _error = result.userMessage;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPlayersWithCharacters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.getPlayersWithCharacters();
    if (result.isSuccess) {
      _playersWithCharacters = result.data ?? [];
      _players = _playersWithCharacters.map((p) => p.player).toList();
    } else {
      _error = result.userMessage;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPlayer(Player player) async {
    final result = await _service.createPlayer(player);
    if (result.isSuccess) {
      await loadPlayers();
      return true;
    }
    _error = result.userMessage;
    notifyListeners();
    return false;
  }

  Future<bool> updatePlayer(Player player) async {
    final result = await _service.updatePlayer(player);
    if (result.isSuccess) {
      await loadPlayers();
      return true;
    }
    _error = result.userMessage;
    notifyListeners();
    return false;
  }

  Future<bool> deletePlayer(String playerId) async {
    final result = await _service.deletePlayer(playerId);
    if (result.isSuccess) {
      await loadPlayers();
      return true;
    }
    _error = result.userMessage;
    notifyListeners();
    return false;
  }

  Future<List<PlayerCharacter>> getCharactersForPlayer(String playerId) async {
    final result = await _service.getCharactersForPlayer(playerId);
    return result.data ?? [];
  }

  Future<bool> assignCharacterToPlayer(String characterId, String playerId) async {
    final result = await _service.assignCharacterToPlayer(characterId, playerId);
    if (!result.isSuccess) {
      _error = result.userMessage;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> unassignCharacterFromPlayer(String characterId) async {
    final result = await _service.unassignCharacterFromPlayer(characterId);
    if (!result.isSuccess) {
      _error = result.userMessage;
      notifyListeners();
      return false;
    }
    return true;
  }
}
