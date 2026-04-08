import 'package:flutter/material.dart';
import '../models/ota_info.dart';
import '../services/ota_service.dart';

/// OTA 升级状态
enum OtaStatus { idle, checking, available, upgrading, success, failed }

/// OTA 固件升级状态管理 Provider
class OtaProvider extends ChangeNotifier {
  final OtaService _otaService;

  OtaProvider({required OtaService otaService}) : _otaService = otaService;

  OtaStatus _status = OtaStatus.idle;
  OtaInfo? _otaInfo;
  String? _errorMessage;
  int _progress = 0; // 0-100

  OtaStatus get status => _status;
  OtaInfo? get otaInfo => _otaInfo;
  String? get errorMessage => _errorMessage;
  int get progress => _progress;

  /// 检查固件升级
  Future<void> checkUpgrade(String deviceId) async {
    _status = OtaStatus.checking;
    _errorMessage = null;
    _otaInfo = null;
    notifyListeners();

    try {
      _otaInfo = await _otaService.checkUpgrade(deviceId);
      _status = _otaInfo != null ? OtaStatus.available : OtaStatus.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = OtaStatus.failed;
      notifyListeners();
    }
  }

  /// 开始升级（模拟进度）
  Future<void> startUpgrade() async {
    _status = OtaStatus.upgrading;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();

    // 模拟下载和烧录进度
    for (var i = 1; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      _progress = i;
      notifyListeners();
    }

    _progress = 100;
    _status = OtaStatus.success;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _status = OtaStatus.idle;
    _otaInfo = null;
    _errorMessage = null;
    _progress = 0;
    notifyListeners();
  }
}
