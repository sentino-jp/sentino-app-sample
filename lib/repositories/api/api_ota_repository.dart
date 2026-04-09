import '../../models/ota_info.dart';
import '../../utils/api_client.dart';
import '../ota_repository.dart';

/// Real API OTA Repository
class ApiOtaRepository implements OtaRepository {
  final ApiClient _api;

  ApiOtaRepository({required ApiClient api}) : _api = api;

  @override
  Future<OtaInfo?> checkUpgrade(String deviceId, {int? firmwareType}) async {
    final type = firmwareType ?? 1;
    try {
      final resp = await _api.post(
        'business-app/v1/ota/checkUpgrade/$deviceId/$type',
        fromData: (d) {
          if (d == null) return null;
          return OtaInfo.fromJson(Map<String, dynamic>.from(d));
        },
      );
      final data = resp.data;
      return data is OtaInfo ? data : null;
    } catch (_) {
      return null;
    }
  }
}
