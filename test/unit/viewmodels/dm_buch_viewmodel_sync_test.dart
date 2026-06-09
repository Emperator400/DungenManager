import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dungen_manager/models/app_user.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/services/campaign_sync_service.dart';
import 'package:dungen_manager/services/cloud_resource_service.dart';
import 'package:dungen_manager/viewmodels/dm_buch_viewmodel.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockCampaignSyncService extends Mock implements CampaignSyncService {}

class MockCloudResourceService extends Mock implements CloudResourceService {}

// ── Helfer ────────────────────────────────────────────────────────────────────

final _user = AppUser(uid: 'uid-test', displayName: null, email: null);

Campaign _campaign({String id = 'c1'}) => Campaign(
      id: id,
      title: 'Test-Kampagne',
      description: '',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

DmBuchViewModel _vm({
  CampaignSyncService? syncService,
  CloudResourceService? resourceService,
  AppUser? user,
}) =>
    DmBuchViewModel(
      campaign: _campaign(),
      campaignSyncService: syncService,
      cloudResourceService: resourceService,
      syncUser: user,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockCampaignSyncService syncService;
  late MockCloudResourceService resourceService;

  setUpAll(() {
    registerFallbackValue(_campaign());
  });

  setUp(() {
    syncService = MockCampaignSyncService();
    resourceService = MockCloudResourceService();

    when(() => syncService.uploadCampaign(any(), any()))
        .thenAnswer((_) async {});
    when(() => resourceService.syncResources(any()))
        .thenAnswer((_) async {});
  });

  // ── canSyncToCloud ────────────────────────────────────────────────────────

  group('canSyncToCloud', () {
    test('false wenn kein User', () {
      final vm = _vm(syncService: syncService, resourceService: resourceService);
      expect(vm.canSyncToCloud, isFalse);
    });

    test('false wenn kein syncService', () {
      final vm = _vm(resourceService: resourceService, user: _user);
      expect(vm.canSyncToCloud, isFalse);
    });

    test('false wenn kein resourceService', () {
      final vm = _vm(syncService: syncService, user: _user);
      expect(vm.canSyncToCloud, isFalse);
    });

    test('true wenn alle drei vorhanden', () {
      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      expect(vm.canSyncToCloud, isTrue);
    });
  });

  // ── syncToCloud ───────────────────────────────────────────────────────────

  group('syncToCloud', () {
    test('gibt false zurück wenn nicht angemeldet', () async {
      final vm = _vm(syncService: syncService, resourceService: resourceService);
      expect(await vm.syncToCloud(), isFalse);
    });

    test('gibt false zurück wenn Services fehlen', () async {
      final vm = _vm(user: _user);
      expect(await vm.syncToCloud(), isFalse);
    });

    test('gibt true zurück bei Erfolg', () async {
      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      expect(await vm.syncToCloud(), isTrue);
    });

    test('syncResources wird vor uploadCampaign aufgerufen', () async {
      final calls = <String>[];
      when(() => resourceService.syncResources(any())).thenAnswer((_) async {
        calls.add('resources');
      });
      when(() => syncService.uploadCampaign(any(), any())).thenAnswer((_) async {
        calls.add('campaign');
      });

      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      await vm.syncToCloud();

      expect(calls, ['resources', 'campaign']);
    });

    test('uploadCampaign wird mit korrekter uid aufgerufen', () async {
      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      await vm.syncToCloud();

      verify(() => syncService.uploadCampaign(any(), 'uid-test')).called(1);
    });

    test('syncResources wird mit korrekter uid aufgerufen', () async {
      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      await vm.syncToCloud();

      verify(() => resourceService.syncResources('uid-test')).called(1);
    });

    test('gibt false zurück wenn uploadCampaign wirft', () async {
      when(() => syncService.uploadCampaign(any(), any()))
          .thenThrow(Exception('Netzwerkfehler'));

      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      expect(await vm.syncToCloud(), isFalse);
    });

    test('isSyncing ist während Sync true, danach false', () async {
      var syncingDuring = false;
      when(() => syncService.uploadCampaign(any(), any())).thenAnswer((_) async {
        syncingDuring = true;
      });

      final vm =
          _vm(syncService: syncService, resourceService: resourceService, user: _user);
      expect(vm.isSyncing, isFalse);

      final future = vm.syncToCloud();
      // isSyncing ist true während der Future läuft
      await future;

      expect(syncingDuring, isTrue);
      expect(vm.isSyncing, isFalse);
    });
  });
}
