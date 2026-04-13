import '../models/asset.dart';
import '../models/device.dart';

/// 设备数据访问抽象接口
abstract class DeviceRepository {
  Future<List<Asset>> getAssetTree();

  Future<List<Device>> getDeviceList(List<String> assetIds);

  Future<Device> getDeviceInfo(String productId, String uuid);

  Future<void> bindDevice(String assetId, String uuid);

  Future<void> bindDeviceByBarcode(String assetId, String barCode);

  Future<void> bindDeviceBy4gBindCode(String assetId, String bindCode);

  Future<void> unbindDevice(String deviceId, {bool cleanData = false});

  Future<int> checkBindResult(String uuid);

  Future<String> encryptPairingData(Map<String, dynamic> content);

  Future<void> renameDevice(String assetId, String deviceUuid, String newName);

  Future<Device> getDeviceById(String deviceId);

  /// 属性下发
  Future<bool> propsIssue(String deviceId, Map<String, dynamic> data);

  /// 网络检测（信号强度检查）
  Future<void> checkSignal(String deviceId);

  /// 获取设备物模型 DP 点信息
  Future<List<Map<String, dynamic>>> getDpInfos(String deviceId);
}
