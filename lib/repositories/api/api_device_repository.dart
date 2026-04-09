import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/asset.dart';
import '../../models/device.dart';
import '../../utils/api_client.dart';
import '../device_repository.dart';

/// Real API device repository
class ApiDeviceRepository implements DeviceRepository {
  final ApiClient _api;

  ApiDeviceRepository({required ApiClient api}) : _api = api;

  @override
  Future<List<Asset>> getAssetTree() async {
    final resp = await _api.post<List<dynamic>>(
        'business-app/v1/asset/assetTree',
        fromData: (d) => List<dynamic>.from(d));
    return (resp.data ?? [])
        .map((e) => Asset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Device>> getDeviceList(List<String> assetIds) async {
    // Log raw response for debugging
    try {
      final rawResp = await _api.dio.post(
        'business-app/v1/device/getHomeDeviceAndGroupList',
        data: {'assetIds': assetIds},
      );
      final rawData = rawResp.data;
      debugPrint('=== getDeviceList raw response ===');
      debugPrint(const JsonEncoder.withIndent('  ').convert(rawData));
      debugPrint('=================================');

      final body = rawData as Map<String, dynamic>;
      final code = body['code'] as int? ?? -1;
      if (code != 200) {
        throw ApiException(bizCode: code, message: body['message']?.toString() ?? 'Failed');
      }
      final data = body['data'];
      if (data == null) return [];

      final deviceList = (data is Map<String, dynamic>)
          ? data['deviceList'] as List<dynamic>? ?? []
          : (data is List ? data : []);

      debugPrint('deviceList count: ${deviceList.length}');
      if (deviceList.isNotEmpty) {
        debugPrint('first device: ${const JsonEncoder.withIndent('  ').convert(deviceList.first)}');
      }

      return deviceList
          .whereType<Map<String, dynamic>>()
          .map((e) {
            try {
              return Device.fromJson(e);
            } catch (err) {
              debugPrint('Device.fromJson error: $err for data: $e');
              return null;
            }
          })
          .whereType<Device>()
          .toList();
    } catch (e) {
      debugPrint('getDeviceList error: $e');
      rethrow;
    }
  }

  @override
  Future<Device> getDeviceInfo(String productId, String uuid) async {
    final resp = await _api.post('business-app/v1/device/getSimpleDeviceInfo',
        data: {'productId': productId, 'uuid': uuid},
        fromData: (d) => Device.fromJson(d as Map<String, dynamic>));
    return resp.data!;
  }

  @override
  Future<void> bindDevice(String assetId, String uuid) async {
    await _api.post('business-app/v1/device/bind/bindDevice',
        data: {'assetId': assetId, 'deviceUuid': uuid});
  }

  @override
  Future<void> bindDeviceByBarcode(String assetId, String barCode) async {
    await _api.post('business-app/v1/device/bind/bindDeviceFromBarcode',
        data: {'assetId': assetId, 'barcode': barCode});
  }

  @override
  Future<void> bindDeviceBy4gBindCode(String assetId, String bindCode) async {
    await _api.post('business-app/v1/device/bind/bindDeviceBy4gCode',
        data: {'assetId': assetId, 'bindCode': bindCode});
  }

  @override
  Future<void> unbindDevice(String deviceId, {bool cleanData = false}) async {
    await _api.post('business-app/v1/device/unbindFromAsset',
        data: {'deviceId': deviceId, 'isCleanData': cleanData ? 1 : 0});
  }

  @override
  Future<int> checkBindResult(String uuid) async {
    final resp = await _api
        .post<String>('business-app/v1/device/bind/checkBindResult/$uuid');
    return int.tryParse(resp.data?.toString() ?? '0') ?? 0;
  }

  @override
  Future<String> encryptPairingData(Map<String, dynamic> content) async {
    final resp = await _api.post<String>(
        'business-app/v1/distributionNet/dataEncrypt',
        data: content);
    return resp.data?.toString() ?? '';
  }

  @override
  Future<void> renameDevice(String assetId, String deviceUuid, String newName) async {
    await _api.post('business-app/v1/device/initDevice', data: {
      'assetId': assetId,
      'deviceUuid': deviceUuid,
      'deviceName': newName,
    });
  }

  @override
  Future<Device> getDeviceById(String deviceId) async {
    final resp = await _api.post('business-app/v1/device/getByDeviceId/$deviceId',
        fromData: (d) => Device.fromJson(d as Map<String, dynamic>));
    return resp.data!;
  }

  @override
  Future<bool> propsIssue(String deviceId, Map<String, dynamic> data) async {
    debugPrint('[DeviceRepo] propsIssue deviceId=$deviceId data=$data');
    await _api.post('business-app/v1/device/command/propsIssue',
        data: {'deviceId': deviceId, 'data': data});
    return true;
  }

  @override
  Future<void> checkSignal(String deviceId) async {
    await _api.post('business-app/v1/device/command/checkSignal',
        data: {'deviceId': deviceId});
  }
}
