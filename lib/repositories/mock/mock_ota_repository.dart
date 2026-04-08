import '../../models/ota_info.dart';
import '../ota_repository.dart';

/// Mock OTA Repository，提供模拟数据用于开发和测试
class MockOtaRepository implements OtaRepository {
  @override
  Future<OtaInfo?> checkUpgrade(String deviceId,
      {int? firmwareType}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // 模拟：dev_001 有可用升级，其他设备无升级
    if (deviceId == 'dev_001') {
      return const OtaInfo(
        version: '1.3.0',
        url: 'https://example.com/firmware/v1.3.0.bin',
        md5sum: 'abc123def456',
        fileSize: 2048000,
        firmwareType: 1,
        description: '修复蓝牙连接稳定性问题，优化语音识别速度',
      );
    }
    return null;
  }
}
