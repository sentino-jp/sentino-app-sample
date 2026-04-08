import '../../models/asset.dart';
import '../../models/device.dart';
import '../device_repository.dart';

/// Mock 设备 Repository
class MockDeviceRepository implements DeviceRepository {
  final List<Device> _devices = [
    const Device(
      deviceId: 'dev_001',
      uuid: 'uuid-001',
      productId: 'prod_001',
      name: '客厅音箱',
      onlineStatusCode: 1,
      firmwareVersion: '1.2.0',
      networkType: 'wifi',
      signalStrength: 85,
      macAddress: 'AA:BB:CC:DD:EE:01',
    ),
    const Device(
      deviceId: 'dev_002',
      uuid: 'uuid-002',
      productId: 'prod_001',
      name: '卧室音箱',
      onlineStatusCode: 0,
      firmwareVersion: '1.1.0',
      networkType: 'wifi',
      signalStrength: 60,
      macAddress: 'AA:BB:CC:DD:EE:02',
    ),
    const Device(
      deviceId: 'dev_003',
      uuid: 'uuid-003',
      productId: 'prod_002',
      name: '便携音箱',
      onlineStatusCode: 1,
      firmwareVersion: '2.0.1',
      networkType: 'wired',
      signalStrength: 95,
      macAddress: 'AA:BB:CC:DD:EE:03',
    ),
  ];

  @override
  Future<List<Asset>> getAssetTree() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      Asset(assetId: 'asset_001', name: '我的家', currentSelected: true),
    ];
  }

  @override
  Future<List<Device>> getDeviceList(List<String> assetIds) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_devices);
  }

  @override
  Future<Device> getDeviceInfo(String productId, String uuid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _devices.firstWhere(
      (d) => d.uuid == uuid && d.productId == productId,
      orElse: () => throw Exception('Device not found'),
    );
  }

  @override
  Future<void> bindDevice(String assetId, String uuid) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> bindDeviceByBarcode(String assetId, String barCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> bindDeviceBy4gBindCode(String assetId, String bindCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> unbindDevice(String deviceId, {bool cleanData = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _devices.removeWhere((d) => d.deviceId == deviceId);
  }

  @override
  Future<int> checkBindResult(String uuid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 1;
  }

  @override
  Future<String> encryptPairingData(Map<String, dynamic> content) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'mock_encrypted_data';
  }

  @override
  Future<void> renameDevice(String assetId, String deviceUuid, String newName) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<Device> getDeviceById(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _devices.firstWhere((d) => d.deviceId == deviceId,
        orElse: () => throw Exception('Device not found'));
  }

  @override
  Future<bool> propsIssue(String deviceId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<void> checkSignal(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
