import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/campaign.dart';
import 'auth_service.dart';

/// Synchronisiert Kampagnen mit Firestore.
/// Windows: Firestore REST API (kein nativer SDK — VS 2026 Inkompatibilität).
/// Android / iOS: natives cloud_firestore Plugin.
///
/// Firestore-Struktur: users/{uid}/campaigns/{campaignId}
/// Jedes Dokument enthält zwei Felder:
///   data      — JSON-kodierte Kampagne (String)
///   updatedAt — ISO-8601-Zeitstempel für Konflikterkennung
class CampaignSyncService {
  static const _projectId = 'dungoenmanager';
  static const _firestoreBase =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final AuthService _authService;

  CampaignSyncService(this._authService);

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> uploadCampaign(Campaign campaign, String uid) async {
    if (Platform.isWindows) {
      await _restUpload(campaign, uid);
    } else {
      await _nativeUpload(campaign, uid);
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

  Future<void> _restUpload(Campaign campaign, String uid) async {
    final url = Uri.parse('$_firestoreBase/users/$uid/campaigns/${campaign.id}');
    final body = jsonEncode({
      'fields': {
        'data': {'stringValue': campaign.toCloudJson()},
        'updatedAt': {'stringValue': campaign.updatedAt.toIso8601String()},
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
        final fields = doc['fields'] as Map<String, dynamic>;
        final dataJson = fields['data']['stringValue'] as String;
        campaigns.add(Campaign.fromCloudJson(dataJson));
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

  Future<void> _nativeUpload(Campaign campaign, String uid) async {
    await _collection(uid).doc(campaign.id).set({
      'data': campaign.toCloudJson(),
      'updatedAt': campaign.updatedAt.toIso8601String(),
    });
  }

  Future<List<Campaign>> _nativeDownload(String uid) async {
    final snapshot = await _collection(uid).get();
    final campaigns = <Campaign>[];
    for (final doc in snapshot.docs) {
      try {
        campaigns.add(Campaign.fromCloudJson(doc.data()['data'] as String));
      } catch (e) {
        debugPrint('[CampaignSyncService] Dokument konnte nicht geparst werden: $e');
      }
    }
    return campaigns;
  }

  Future<void> _nativeDelete(String campaignId, String uid) async {
    await _collection(uid).doc(campaignId).delete();
  }
}
