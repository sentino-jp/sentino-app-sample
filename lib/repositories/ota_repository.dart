import '../models/ota_info.dart';

/// OTA 固件升级数据访问抽象接口
abstract class OtaRepository {
  Future<OtaInfo?> checkUpgrade(String deviceId, {int? firmwareType});
}
