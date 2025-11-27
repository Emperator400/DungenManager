import '../database/database_helper.dart';
import '../services/campaign_service.dart';

/// Service Locator für Campaign Management
/// 
/// Zentralisiert den Zugriff auf alle Campaign-spezifischen Services
/// und ermöglicht Dependency Injection für Testing.
class CampaignServiceLocator {
  static CampaignService? _campaignService;
  static DatabaseHelper? _databaseHelper;

  /// Holt den CampaignService
  static CampaignService get campaignService {
    _campaignService ??= CampaignService();
    return _campaignService!;
  }

  /// Holt den DatabaseHelper
  static DatabaseHelper get databaseHelper {
    _databaseHelper ??= DatabaseHelper.instance;
    return _databaseHelper!;
  }

  /// Setzt Mock Services für Testing
  static void setMocks({
    CampaignService? campaignService,
    DatabaseHelper? databaseHelper,
  }) {
    _campaignService = campaignService;
    _databaseHelper = databaseHelper;
  }

  /// Resetet alle Services
  static void reset() {
    _campaignService = null;
    _databaseHelper = null;
  }
}
