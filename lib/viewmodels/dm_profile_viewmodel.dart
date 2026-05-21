import 'package:flutter/foundation.dart';

import '../models/dm_profile.dart';
import '../services/dm_profile_service.dart';

class DmProfileViewModel extends ChangeNotifier {
  final DmProfileService _service;

  DmProfile? _profile;
  DmProfileStats? _stats;
  bool _isLoading = false;
  String? _error;

  DmProfileViewModel({required DmProfileService service}) : _service = service;

  DmProfile? get profile => _profile;
  DmProfileStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _service.getProfile();
      _stats = await _service.loadStats();
    } catch (e) {
      _error = e.toString();
      debugPrint('DmProfileViewModel.loadProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String dmName,
    String? bio,
    String? favoriteSystem,
  }) async {
    if (_profile == null) return false;
    try {
      _profile = await _service.updateProfile(
        _profile!.copyWith(
          dmName: dmName,
          bio: (bio == null || bio.trim().isEmpty) ? null : bio.trim(),
          favoriteSystem: (favoriteSystem == null || favoriteSystem.trim().isEmpty) ? null : favoriteSystem.trim(),
        ),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvatar(String pickedPath) async {
    if (_profile == null) return false;
    try {
      _profile = await _service.updateAvatar(_profile!, pickedPath);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearAvatar() async {
    if (_profile == null) return false;
    try {
      _profile = await _service.clearAvatar(_profile!);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
