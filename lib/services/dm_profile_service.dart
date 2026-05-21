import 'package:flutter/foundation.dart';

import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/dm_profile_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../models/dm_profile.dart';
import 'image_storage_service.dart';

class DmProfileStats {
  final int campaignCount;
  final int sessionCount;
  final int characterCount;

  const DmProfileStats({
    required this.campaignCount,
    required this.sessionCount,
    required this.characterCount,
  });
}

class DmProfileService {
  final DmProfileModelRepository _profileRepo;
  final CampaignModelRepository _campaignRepo;
  final SessionModelRepository _sessionRepo;
  final PlayerCharacterModelRepository _characterRepo;

  DmProfileService({
    required DmProfileModelRepository profileRepo,
    required CampaignModelRepository campaignRepo,
    required SessionModelRepository sessionRepo,
    required PlayerCharacterModelRepository characterRepo,
  })  : _profileRepo = profileRepo,
        _campaignRepo = campaignRepo,
        _sessionRepo = sessionRepo,
        _characterRepo = characterRepo;

  Future<DmProfile> getProfile() => _profileRepo.getOrCreate();

  Future<DmProfile> updateProfile(DmProfile profile) =>
      _profileRepo.upsertProfile(profile.copyWith(updatedAt: DateTime.now()));

  Future<DmProfile> updateAvatar(DmProfile profile, String pickedPath) async {
    final securePath = await ImageStorageService.saveImageToSecureFolder(pickedPath);
    final updated = profile.copyWith(
      avatarPath: securePath,
      updatedAt: DateTime.now(),
    );
    return _profileRepo.upsertProfile(updated);
  }

  Future<DmProfile> clearAvatar(DmProfile profile) async {
    final updated = profile.copyWith(avatarPath: null, updatedAt: DateTime.now());
    return _profileRepo.upsertProfile(updated);
  }

  Future<DmProfileStats> loadStats() async {
    try {
      final campaigns = await _campaignRepo.findAll();
      final sessions = await _sessionRepo.findAll();
      final characters = await _characterRepo.findAll();
      return DmProfileStats(
        campaignCount: campaigns.length,
        sessionCount: sessions.length,
        characterCount: characters.length,
      );
    } catch (e) {
      debugPrint('DmProfileService.loadStats error: $e');
      return const DmProfileStats(campaignCount: 0, sessionCount: 0, characterCount: 0);
    }
  }
}
