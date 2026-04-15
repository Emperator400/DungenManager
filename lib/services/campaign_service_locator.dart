import '../services/campaign_service.dart';

/// Service Locator für Campaign Management
///
/// Zentralisiert den Zugriff auf alle Campaign-spezifischen Services
/// und ermöglicht Dependency Injection für Testing.
class CampaignServiceLocator {
  static CampaignService? _campaignService;

  /// Holt den CampaignService
  static CampaignService get campaignService {
    _campaignService ??= CampaignService();
    return _campaignService!;
  }

  /// Setzt Mock Services für Testing
  static void setMocks({
    CampaignService? campaignService,
  }) {
    _campaignService = campaignService;
  }

  /// Resetet alle Services
  static void reset() {
    _campaignService = null;
  }
}
