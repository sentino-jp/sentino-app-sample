import '../models/asset.dart';
import '../models/device.dart';
import '../repositories/device_repository.dart';

/// 设备业务逻辑层
class DeviceService {
  final DeviceRepository _repository;

  DeviceService({required DeviceRepository repository})
    : _repository = repository;

  Future<List<Asset>> getAssetTree() => _repository.getAssetTree();

  Future<List<Device>> getDeviceList(List<String> assetIds) =>
      _repository.getDeviceList(assetIds);

  Future<Device> getDeviceInfo(String productId, String uuid) =>
      _repository.getDeviceInfo(productId, uuid);

  Future<void> bindDevice(String assetId, String uuid) =>
      _repository.bindDevice(assetId, uuid);

  Future<void> bindDeviceByBarcode(String assetId, String barCode) =>
      _repository.bindDeviceByBarcode(assetId, barCode);

  Future<void> bindDeviceBy4gBindCode(String assetId, String bindCode) =>
      _repository.bindDeviceBy4gBindCode(assetId, bindCode);

  Future<void> unbindDevice(String deviceId, {bool cleanData = false}) =>
      _repository.unbindDevice(deviceId, cleanData: cleanData);

  Future<int> checkBindResult(String uuid) => _repository.checkBindResult(uuid);

  Future<String> encryptPairingData(Map<String, dynamic> content) =>
      _repository.encryptPairingData(content);

  Future<void> renameDevice(
    String assetId,
    String deviceUuid,
    String newName,
  ) => _repository.renameDevice(assetId, deviceUuid, newName);

  Future<Device> getDeviceById(String deviceId) =>
      _repository.getDeviceById(deviceId);

  /// 网络检测（信号强度检查）
  Future<void> checkSignal(String deviceId) =>
      _repository.checkSignal(deviceId);

  /// Sort devices
  /// 排序 ID 列表中存在的设备按指定顺序排列，不在排序列表中的设备追加在末尾
  static List<Device> sortDevices(
    List<Device> devices,
    List<String> sortOrder,
  ) {
    final orderMap = <String, int>{};
    for (var i = 0; i < sortOrder.length; i++) {
      orderMap[sortOrder[i]] = i;
    }

    final sorted = List<Device>.from(devices);
    sorted.sort((a, b) {
      final aIndex = orderMap[a.deviceId];
      final bIndex = orderMap[b.deviceId];

      if (aIndex != null && bIndex != null) return aIndex.compareTo(bIndex);
      if (aIndex != null) return -1;
      if (bIndex != null) return 1;
      return 0;
    });

    return sorted;
  }
}
