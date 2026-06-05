import '../models/store_settings.dart';
import 'api_service.dart';

class StoreSettingsService {
  final ApiService _api = ApiService();

  Future<StoreSettings> getStoreSettings() async {
    final data = await _api.get('/store-settings');
    final m = (data is Map && data['settings'] is Map)
        ? Map<String, dynamic>.from(data['settings'] as Map)
        : Map<String, dynamic>.from(data as Map);
    return StoreSettings.fromJson(m);
  }
}
