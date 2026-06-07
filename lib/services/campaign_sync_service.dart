import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../models/campaign.dart';
import '../models/ort.dart';
import '../models/quest.dart';
import '../models/scene.dart';
import 'auth_service.dart';

/// Synchronisiert Kampagnen mit Firestore.
/// Windows: Firestore REST API (kein nativer SDK — VS 2026 Inkompatibilität).
/// Android / iOS: natives cloud_firestore Plugin.
///
/// Firestore-Struktur: users/{uid}/campaigns/{campaignId}
/// Jedes Dokument enthält:
///   data       — JSON-kodierte Kampagne (String)
///   updatedAt  — ISO-8601-Zeitstempel für Konflikterkennung
///   orteData   — JSON-Array aller Orte der Kampagne
///   scenesData — JSON-Array aller Szenen der Kampagne
///   questsData — JSON-Array aller Quests der Kampagne
class CampaignSyncService {
  static const _projectId = 'dungoenmanager';
  static const _firestoreBase =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final AuthService _authService;
  final OrtModelRepository _ortRepo;
  final SceneModelRepository _sceneRepo;
  final QuestModelRepository _questRepo;

  CampaignSyncService(
    this._authService,
    this._ortRepo,
    this._sceneRepo,
    this._questRepo,
  );

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> uploadCampaign(Campaign campaign, String uid) async {
    final orte   = await _ortRepo.findByCampaign(campaign.id);
    final scenes = await _sceneRepo.findByCampaign(campaign.id);
    final quests = await _questRepo.findByCampaign(campaign.id);

    if (Platform.isWindows) {
      await _restUpload(campaign, uid, orte, scenes, quests);
    } else {
      await _nativeUpload(campaign, uid, orte, scenes, quests);
    }
  }

  Future<List<Campaign>> downloadCampaigns(String uid) async {
    if (Platform.isWindows) {
      return _restDownload(uid);
    } else {
      return _nativeDownload(uid);
    }
  }

  Future<void> deleteCampaign(String campaignId, String uid) async {
    if (Platform.isWindows) {
      await _restDelete(campaignId, uid);
    } else {
      await _nativeDelete(campaignId, uid);
    }
  }

  // ── Windows REST API ──────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getIdToken();
    if (token == null) throw Exception('Nicht angemeldet – bitte zuerst einloggen.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _restUpload(
    Campaign campaign,
    String uid,
    List<Ort> orte,
    List<Scene> scenes,
    List<Quest> quests,
  ) async {
    final url = Uri.parse('$_firestoreBase/users/$uid/campaigns/${campaign.id}');
    final body = jsonEncode({
      'fields': {
        'data':       {'stringValue': campaign.toCloudJson()},
        'updatedAt':  {'stringValue': campaign.updatedAt.toIso8601String()},
        'orteData':   {'stringValue': _encodeList(orte.map((o) => o.toDatabaseMap()).toList())},
        'scenesData': {'stringValue': _encodeList(scenes.map((s) => s.toDatabaseMap()).toList())},
        'questsData': {'stringValue': _encodeList(quests.map((q) => q.toDatabaseMap()).toList())},
      },
    });
    final response = await http.patch(url, headers: await _authHeaders(), body: body);
    if (response.statusCode != 200) {
      throw Exception('Upload fehlgeschlagen (${response.statusCode})');
    }
  }

  Future<List<Campaign>> _restDownload(String uid) async {
    final url = Uri.parse('$_firestoreBase/users/$uid/campaigns');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 404) return [];
    if (response.statusCode == 403) {
      throw Exception(
        'Zugriff verweigert (403). Bitte Firestore-Sicherheitsregeln prüfen: '
        'Firebase Console → Firestore → Regeln → allow read, write: if request.auth != null',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('Download fehlgeschlagen (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = body['documents'] as List<dynamic>? ?? [];
    final campaigns = <Campaign>[];
    for (final doc in docs) {
      try {
        final fields  = doc['fields'] as Map<String, dynamic>;
        final dataJson = fields['data']['stringValue'] as String;
        final campaign = Campaign.fromCloudJson(dataJson);
        campaigns.add(campaign);

        await _upsertRelated(
          campaignId: campaign.id,
          orteJson:   fields['orteData']?['stringValue'] as String?,
          scenesJson: fields['scenesData']?['stringValue'] as String?,
          questsJson: fields['questsData']?['stringValue'] as String?,
        );
      } catch (e) {
        debugPrint('[CampaignSyncService] Dokument konnte nicht geparst werden: $e');
      }
    }
    return campaigns;
  }

  Future<void> _restDelete(String campaignId, String uid) async {
    final url = Uri.parse('$_firestoreBase/users/$uid/campaigns/$campaignId');
    final response = await http.delete(url, headers: await _authHeaders());
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception('Löschen fehlgeschlagen (${response.statusCode})');
    }
  }

  // ── Native Firestore (Android / iOS) ─────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('campaigns');

  Future<void> _nativeUpload(
    Campaign campaign,
    String uid,
    List<Ort> orte,
    List<Scene> scenes,
    List<Quest> quests,
  ) async {
    await _collection(uid).doc(campaign.id).set({
      'data':       campaign.toCloudJson(),
      'updatedAt':  campaign.updatedAt.toIso8601String(),
      'orteData':   _encodeList(orte.map((o) => o.toDatabaseMap()).toList()),
      'scenesData': _encodeList(scenes.map((s) => s.toDatabaseMap()).toList()),
      'questsData': _encodeList(quests.map((q) => q.toDatabaseMap()).toList()),
    });
  }

  Future<List<Campaign>> _nativeDownload(String uid) async {
    final snapshot = await _collection(uid).get();
    final campaigns = <Campaign>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final campaign = Campaign.fromCloudJson(data['data'] as String);
        campaigns.add(campaign);

        await _upsertRelated(
          campaignId: campaign.id,
          orteJson:   data['orteData'] as String?,
          scenesJson: data['scenesData'] as String?,
          questsJson: data['questsData'] as String?,
        );
      } catch (e) {
        debugPrint('[CampaignSyncService] Dokument konnte nicht geparst werden: $e');
      }
    }
    return campaigns;
  }

  Future<void> _nativeDelete(String campaignId, String uid) async {
    await _collection(uid).doc(campaignId).delete();
  }

  // ── Related-Entity Upsert ─────────────────────────────────────────────────

  Future<void> _upsertRelated({
    required String campaignId,
    String? orteJson,
    String? scenesJson,
    String? questsJson,
  }) async {
    await Future.wait([
      if (orteJson != null && orteJson.isNotEmpty)
        _upsertOrte(campaignId, orteJson),
      if (scenesJson != null && scenesJson.isNotEmpty)
        _upsertScenes(scenesJson),
      if (questsJson != null && questsJson.isNotEmpty)
        _upsertQuests(questsJson),
    ]);
  }

  Future<void> _upsertOrte(String campaignId, String json) async {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final ort = Ort.fromDatabaseMap(map);
        final existing = await _ortRepo.findById(ort.id);
        if (existing == null) {
          await _ortRepo.create(ort);
        } else {
          await _ortRepo.update(ort);
        }
      }
    } catch (e) {
      debugPrint('[CampaignSyncService] Orte-Upsert fehlgeschlagen: $e');
    }
  }

  Future<void> _upsertScenes(String json) async {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final scene = Scene.fromDatabaseMap(map);
        final existing = await _sceneRepo.findById(scene.id);
        if (existing == null) {
          await _sceneRepo.create(scene);
        } else {
          await _sceneRepo.update(scene);
        }
      }
    } catch (e) {
      debugPrint('[CampaignSyncService] Szenen-Upsert fehlgeschlagen: $e');
    }
  }

  Future<void> _upsertQuests(String json) async {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final quest = Quest.fromDatabaseMap(map);
        final existing = await _questRepo.findById(quest.id);
        if (existing == null) {
          await _questRepo.create(quest);
        } else {
          await _questRepo.update(quest);
        }
      }
    } catch (e) {
      debugPrint('[CampaignSyncService] Quests-Upsert fehlgeschlagen: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _encodeList(List<Map<String, dynamic>> list) => jsonEncode(list);
}
