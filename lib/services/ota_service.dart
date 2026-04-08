import '../models/ota_info.dart';
import '../repositories/ota_repository.dart';

/// OTA 固件升级业务逻辑层
class OtaService {
  final OtaRepository _repository;

  OtaService({required OtaRepository repository}) : _repository = repository;

  Future<OtaInfo?> checkUpgrade(String deviceId, {int? firmwareType}) =>
      _repository.checkUpgrade(deviceId, firmwareType: firmwareType);
}
