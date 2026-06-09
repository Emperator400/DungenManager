import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dungen_manager/models/app_user.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/viewmodels/campaign_viewmodel.dart';
import 'package:dungen_manager/services/campaign_sync_service.dart';
import 'package:dungen_manager/database/repositories/campaign_model_repository.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockCampaignRepo extends Mock implements CampaignModelRepository {}

class MockSyncService extends Mock implements CampaignSyncService {}

// ── Helfer ────────────────────────────────────────────────────────────────────

Campaign _c(String id, DateTime updatedAt, {String title = 'Kampagne'}) =>
    Campaign(
      id: id,
      title: '$title ($id)',
      description: '',
      createdAt: DateTime(2025),
      updatedAt: updatedAt,
    );

final _user = AppUser(uid: 'uid-test', displayName: null, email: null);

final _t0 = DateTime(2025, 1, 1);
final _t1 = DateTime(2025, 6, 1); // neuer als t0

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockCampaignRepo repo;
  late MockSyncService syncService;
  late CampaignViewModel vm;

  setUpAll(() {
    // Fallback-Werte für Typen, die mocktail in any() verwendet
    registerFallbackValue(
      _c('fallback', DateTime.now()),
    );
  });

  setUp(() {
    repo = MockCampaignRepo();
    syncService = MockSyncService();

    // Standard-Stubs die fast immer gebraucht werden
    when(() => repo.loadAllCampaignStats()).thenAnswer((_) async => {});
    when(() => syncService.uploadCampaign(any(), any()))
        .thenAnswer((_) async {});

    vm = CampaignViewModel(campaignRepo: repo);
  });

  // Hilfsmethode: Kampagnen in VM laden ohne echte DB
  Future<void> _loadCampaigns(List<Campaign> local) async {
    when(() => repo.findAll()).thenAnswer((_) async => local);
    await vm.loadCampaigns();
  }

  group('syncWithCloud – neue Cloud-Kampagne', () {
    test('wird lokal angelegt wenn ID noch nicht bekannt', () async {
      final cloudCampaign = _c('cloud-1', _t1);

      await _loadCampaigns([]);
      when(() => repo.findById('cloud-1')).thenAnswer((_) async => null);
      when(() => repo.create(any()))
          .thenAnswer((inv) async => inv.positionalArguments[0] as Campaign);

      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => [cloudCampaign]);

      final conflicts = await vm.syncWithCloud(_user, syncService);

      expect(conflicts, isEmpty);
      verify(() => repo.create(any())).called(1);
    });

    test('wird danach hochgeladen (orteData aktualisieren)', () async {
      final cloudCampaign = _c('cloud-1', _t1);

      await _loadCampaigns([]);
      when(() => repo.findById('cloud-1')).thenAnswer((_) async => null);
      when(() => repo.create(any()))
          .thenAnswer((inv) async => inv.positionalArguments[0] as Campaign);

      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => [cloudCampaign]);

      await vm.syncWithCloud(_user, syncService);

      // Die neu erstellte Kampagne soll direkt wieder hochgeladen werden
      // damit orteData in Firestore landet.
      verify(() => syncService.uploadCampaign(any(), _user.uid)).called(1);
    });
  });

  group('syncWithCloud – Konflikt (Cloud neuer)', () {
    test('gibt Konflikt zurück', () async {
      final local = _c('c1', _t0);
      final cloud = _c('c1', _t1);

      await _loadCampaigns([local]);
      when(() => repo.findById('c1')).thenAnswer((_) async => local);
      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => [cloud]);

      final conflicts = await vm.syncWithCloud(_user, syncService);

      expect(conflicts.length, 1);
      expect(conflicts.first.local.id, 'c1');
      expect(conflicts.first.cloud.id, 'c1');
    });

    test('Konflikt-Kampagne wird NICHT hochgeladen', () async {
      final local = _c('c1', _t0);
      final cloud = _c('c1', _t1);

      await _loadCampaigns([local]);
      when(() => repo.findById('c1')).thenAnswer((_) async => local);
      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => [cloud]);

      await vm.syncWithCloud(_user, syncService);

      // Kein Upload für die Konflikt-Kampagne
      verifyNever(() => syncService.uploadCampaign(
            any(that: predicate<Campaign>((c) => c.id == 'c1')),
            any(),
          ));
    });
  });

  group('syncWithCloud – kein Konflikt (lokal neuer oder gleich)', () {
    test('lokale Version wird hochgeladen wenn lokal neuer', () async {
      final local = _c('c1', _t1); // lokal neuer
      final cloud = _c('c1', _t0);

      await _loadCampaigns([local]);
      when(() => repo.findById('c1')).thenAnswer((_) async => local);
      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => [cloud]);

      final conflicts = await vm.syncWithCloud(_user, syncService);

      expect(conflicts, isEmpty);
      verify(() => syncService.uploadCampaign(
            any(that: predicate<Campaign>((c) => c.id == 'c1')),
            _user.uid,
          )).called(1);
    });

    test('rein lokale Kampagne (nicht in Cloud) wird hochgeladen', () async {
      final local = _c('local-only', _t0);

      await _loadCampaigns([local]);
      // Cloud kennt diese Kampagne nicht → downloadCampaigns gibt leere Liste
      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => []);

      await vm.syncWithCloud(_user, syncService);

      verify(() => syncService.uploadCampaign(
            any(that: predicate<Campaign>((c) => c.id == 'local-only')),
            _user.uid,
          )).called(1);
    });
  });

  group('syncWithCloud – gemischtes Szenario', () {
    test('Konflikt-Kampagne nicht hochgeladen, andere schon', () async {
      final localOld = _c('conflict-c', _t0); // Cloud neuer → Konflikt
      final localNew = _c('ok-c', _t1); // lokal neuer → Upload

      await _loadCampaigns([localOld, localNew]);

      final cloudConflict = _c('conflict-c', _t1);
      final cloudOlder = _c('ok-c', _t0);

      when(() => repo.findById('conflict-c'))
          .thenAnswer((_) async => localOld);
      when(() => repo.findById('ok-c')).thenAnswer((_) async => localNew);

      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => [cloudConflict, cloudOlder]);

      final conflicts = await vm.syncWithCloud(_user, syncService);

      expect(conflicts.length, 1);
      expect(conflicts.first.local.id, 'conflict-c');

      // ok-c wird hochgeladen
      verify(() => syncService.uploadCampaign(
            any(that: predicate<Campaign>((c) => c.id == 'ok-c')),
            _user.uid,
          )).called(1);

      // conflict-c wird NICHT hochgeladen
      verifyNever(() => syncService.uploadCampaign(
            any(that: predicate<Campaign>((c) => c.id == 'conflict-c')),
            any(),
          ));
    });
  });

  group('syncWithCloud – syncEnabled = false', () {
    test('Kampagne mit syncEnabled=false wird NICHT hochgeladen', () async {
      final local = Campaign(
        id: 'no-sync',
        title: 'Privat',
        description: '',
        createdAt: DateTime(2025),
        updatedAt: _t0,
        syncEnabled: false,
      );

      await _loadCampaigns([local]);
      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => []);

      await vm.syncWithCloud(_user, syncService);

      verifyNever(() => syncService.uploadCampaign(any(), any()));
    });

    test('Kampagne mit syncEnabled=true wird hochgeladen', () async {
      final local = Campaign(
        id: 'yes-sync',
        title: 'Normal',
        description: '',
        createdAt: DateTime(2025),
        updatedAt: _t0,
      );

      await _loadCampaigns([local]);
      when(() => syncService.downloadCampaigns(_user.uid))
          .thenAnswer((_) async => []);

      await vm.syncWithCloud(_user, syncService);

      verify(() => syncService.uploadCampaign(any(), _user.uid)).called(1);
    });
  });

  group('resolveConflicts', () {
    test('useCloud=true → lokale Version wird mit Cloud-Version ersetzt', () async {
      final local = _c('c1', _t0);
      final cloud = _c('c1', _t1, title: 'Cloud-Version');

      // VM mit einer lokalen Kampagne vorbereiten
      await _loadCampaigns([local]);
      when(() => repo.update(any()))
          .thenAnswer((inv) async => inv.positionalArguments[0] as Campaign);

      final conflicts = [SyncConflict(local: local, cloud: cloud)];
      await vm.resolveConflicts(conflicts, true, syncService, _user);

      verify(() => repo.update(
            any(that: predicate<Campaign>((c) => c.updatedAt == _t1)),
          )).called(1);
    });

    test('useCloud=false → lokale Version wird hochgeladen', () async {
      final local = _c('c1', _t0);
      final cloud = _c('c1', _t1);

      await _loadCampaigns([local]);

      final conflicts = [SyncConflict(local: local, cloud: cloud)];
      await vm.resolveConflicts(conflicts, false, syncService, _user);

      verify(() => syncService.uploadCampaign(
            any(that: predicate<Campaign>((c) => c.id == 'c1')),
            _user.uid,
          )).called(1);
    });
  });
}
