import '../database/repositories/campaign_repository.dart';
import '../database/core/database_connection.dart';
import '../services/campaign_service.dart';

/// Service Locator für Campaign Management
/// 
/// Zentralisiert den Zugriff auf alle Campaign-spezifischen Services
/// und ermöglicht Dependency Injection für Testing.
class CampaignServiceLocator {
  static CampaignService? _campaignService;
  static CampaignRepository? _campaignRepository;

  /// Holt den CampaignService
  static CampaignService get campaignService {
    _campaignService ??= CampaignService();
    return _campaignService!;
  }

  /// Holt den CampaignRepository
  static CampaignRepository get campaignRepository {
    _campaignRepository ??= CampaignRepository(DatabaseConnection.instance);
    return _campaignRepository!;
  }

  /// Setzt Mock Services für Testing
  static void setMocks({
    CampaignService? campaignService,
    CampaignRepository? campaignRepository,
  }) {
    _campaignService = campaignService;
    _campaignRepository = campaignRepository;
  }

  /// Resetet alle Services
  static void reset() {
    _campaignService = null;
    _campaignRepository = null;
  }
}
