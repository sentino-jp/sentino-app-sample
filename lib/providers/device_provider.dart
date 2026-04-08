import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/device.dart';
import '../services/device_service.dart';

/// 设备状态管理 Provider
class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService;

  DeviceProvider({required DeviceService deviceService})
      : _deviceService = deviceService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Asset> _assets = [];
  List<Device> _devices = [];
  List<String> _sortOrder = [];
  Device? _selectedDevice;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Asset> get assets => _assets;
  List<Device> get devices =>
      DeviceService.sortDevices(_devices, _sortOrder);
  Device? get selectedDevice => _selectedDevice;

  /// 加载资产树
  Future<void> loadAssets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assets = await _deviceService.getAssetTree();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载设备列表
  Future<void> loadDevices(List<String> assetIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _devices = await _deviceService.getDeviceList(assetIds);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置自定义排序
  void setSortOrder(List<String> order) {
    _sortOrder = order;
    notifyListeners();
  }

  /// 加载设备详情
  Future<void> loadDeviceInfo(String productId, String uuid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedDevice = await _deviceService.getDeviceInfo(productId, uuid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 解绑设备
  Future<bool> unbindDevice(String deviceId, {bool cleanData = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.unbindDevice(deviceId, cleanData: cleanData);
      _devices.removeWhere((d) => d.deviceId == deviceId);
      if (_selectedDevice?.deviceId == deviceId) {
        _selectedDevice = null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 条形码绑定设备
  Future<void> bindDeviceByBarcode(String assetId, String barCode) async {
    await _deviceService.bindDeviceByBarcode(assetId, barCode);
  }

  /// 4G 绑定码绑定设备
  Future<void> bindDeviceBy4gCode(String assetId, String bindCode) async {
    await _deviceService.bindDeviceBy4gBindCode(assetId, bindCode);
  }

  /// Rename device
  Future<void> renameDevice(String assetId, String deviceUuid, String newName) async {
    await _deviceService.renameDevice(assetId, deviceUuid, newName);
    // Reload devices to reflect the name change
    final assetIds = _assets.map((a) => a.assetId).toList();
    if (assetIds.isNotEmpty) await loadDevices(assetIds);
  }
}
