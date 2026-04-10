import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/device_provider.dart';
import '../../repositories/api/api_device_repository.dart';
import '../../routes/app_router.dart';
import '../../services/ble_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_client.dart';
import '../../utils/app_config.dart';
import '../../utils/storage.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/radar_scan_widget.dart';

enum BlePairingStep { scanning, connecting, configuring, polling, success, failed }

/// BLE pairing page with radar scan animation
class BlePairingPage extends StatefulWidget {
  const BlePairingPage({super.key});
  @override
  State<BlePairingPage> createState() => _BlePairingPageState();
}

class _BlePairingPageState extends State<BlePairingPage> {
  final _bleService = BleService();
  BlePairingStep _step = BlePairingStep.scanning;
  List<BleDeviceInfo> _scannedDevices = [];
  String? _errorMessage;
  BleDeviceInfo? _currentDevice;
  StreamSubscription? _scanSub;
  bool _scanStarted = false;

  @override
  void initState() { super.initState(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scanStarted) return;
    _scanStarted = true;
    _startScan();
  }

  @override
  void dispose() { _scanSub?.cancel(); _bleService.stopScan(); super.dispose(); }

  Future<void> _startScan() async {
    setState(() { _step = BlePairingStep.scanning; _scannedDevices = []; _errorMessage = null; });

    // 检查蓝牙和位置权限
    if (Platform.isAndroid || Platform.isIOS) {
      final permOk = await _checkPermissions();
      if (!permOk) return;
    }

    final available = await _bleService.isBluetoothAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() { _step = BlePairingStep.failed;
        _errorMessage = AppLocalizations.of(context)!.bluetoothNotAvailable; });
      return;
    }
    _scanSub?.cancel();
    _scanSub = _bleService.scanResults.listen((devices) {
      if (mounted) {
        setState(() => _scannedDevices = devices);
        _fetchDeviceInfos(devices);
      }
    });
    await _bleService.startScan(timeout: const Duration(seconds: 0));
  }

  /// 异步获取扫描到的设备的名称和图片
  Future<void> _fetchDeviceInfos(List<BleDeviceInfo> devices) async {
    if (AppConfig.useMock) return;
    for (final d in devices) {
      if (d.infoLoaded || d.uuid == null || d.uuid!.isEmpty) continue;
      if (d.productId == null || d.productId!.isEmpty) continue;
      d.infoLoaded = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageUtil(prefs);
        final api = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
        final repo = ApiDeviceRepository(api: api);
        final device = await repo.getDeviceInfo(d.productId!, d.uuid!);
        if (mounted) {
          setState(() {
            if (device.name != null && device.name!.isNotEmpty) d.name = device.name!;
            if (device.imageUrl != null && device.imageUrl!.isNotEmpty) d.imageUrl = device.imageUrl;
          });
        }
      } catch (e) {
        debugPrint('BleService: fetchDeviceInfo error for ${d.uuid}: $e');
      }
    }
  }

  /// 检查蓝牙和位置权限，未授权时弹窗提示并引导设置
  Future<bool> _checkPermissions() async {
    final l = AppLocalizations.of(context)!;
    final permissions = <Permission>[];

    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ]);
    } else if (Platform.isIOS) {
      permissions.add(Permission.bluetooth);
    }

    final statuses = await permissions.request();
    final denied = statuses.entries
        .where((e) => !e.value.isGranted)
        .map((e) => e.key)
        .toList();

    if (denied.isEmpty) return true;

    // 有权限被拒绝
    if (!mounted) return false;
    final isPermanent = denied.any((p) => statuses[p] == PermissionStatus.permanentlyDenied);

    final goSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.permissionRequired),
        content: Text(l.blePermissionHint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          if (isPermanent)
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.goSettings, style: const TextStyle(color: AppColors.primary))),
        ],
      ),
    ) ?? false;

    if (goSettings) {
      AppSettings.openAppSettings();
    }

    if (mounted) {
      setState(() { _step = BlePairingStep.failed;
        _errorMessage = l.blePermissionDenied; });
    }
    return false;
  }

  void _showAllDevices(AppLocalizations l) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _AllDevicesPage(
        devices: _scannedDevices,
        scanStream: _bleService.scanResults,
        onSelect: (device) {
          Navigator.pop(context);
          _selectDevice(device);
        },
      ),
    ));
  }

  Future<void> _selectDevice(BleDeviceInfo device) async {
    setState(() { _step = BlePairingStep.connecting; _currentDevice = device; });
    await _bleService.stopScan();
    final connected = await _bleService.connectDevice(device);
    if (connected == null || !mounted) {
      setState(() { _step = BlePairingStep.failed;
        _errorMessage = AppLocalizations.of(context)!.connectFailed; });
      return;
    }
    if (mounted) {
      final result = await context.push<Map<String, String>>(AppRoutes.wifiInput);
      if (result != null && mounted) {
        await _startPairing(device, result);
      } else if (mounted) {
        await _bleService.disconnect(connected);
        setState(() => _step = BlePairingStep.scanning);
      }
    }
  }

  Future<void> _startPairing(BleDeviceInfo device, Map<String, String> wifiInfo) async {
    final l = AppLocalizations.of(context)!;
    final isBleDirectConnect = wifiInfo['bleDirectConnect'] == '1';
    setState(() => _step = BlePairingStep.configuring);
    final char = await _bleService.findPairingCharacteristic(device.device);
    if (char == null || !mounted) {
      setState(() { _step = BlePairingStep.failed; _errorMessage = l.deviceNotSupport; });
      return;
    }

    bool sent;
    if (isBleDirectConnect) {
      // 蓝牙直连模式：发送 bind 命令
      final bindData = {
        'type': 'thing.network.set',
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': {'ble': 'bind', 'force_bind': false},
      };
      sent = await _bleService.sendPairingData(char, bindData);
    } else {
      // WiFi+BLE 配网模式：构造完整配网数据并加密
      try {
        final provider = context.read<DeviceProvider>();
        final assetId = provider.assets.isNotEmpty ? provider.assets.first.assetId : '';
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageUtil(prefs);
        final userId = storage.getUserId() ?? '';

        // 构造配网内容（与 Android ActivatorBusiness.sendWifiDisNetworkData 一致）
        final content = {
          'sid': wifiInfo['ssid'] ?? '',
          'pw': wifiInfo['password'] ?? '',
          'mq': AppConfig.mqttHost,
          'port': AppConfig.mqttPort,
          'bid': assetId,
          'userId': userId,
          'force_bind': false,
          'country': AppConfig.dataCenterCode.toUpperCase(),
          'tz': DateTime.now().timeZoneName,
        };

        // 调用服务端加密 API（与 Android DualModeConnectNetworkManager.dataEncrypt 一致）
        final api = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
        final repo = ApiDeviceRepository(api: api);
        final encryptedData = await repo.encryptPairingData({
          'content': jsonEncode(content),
          'encryptType': device.encryptType,
          'protocol': '1',
          'type': 'thing.network.set',
        });

        debugPrint('BLE pairing: encryptedData length=${encryptedData.length}, first100=${encryptedData.length > 100 ? encryptedData.substring(0, 100) : encryptedData}');

        if (encryptedData.isEmpty) {
          if (mounted) setState(() { _step = BlePairingStep.failed; _errorMessage = l.sendPairingFailed; });
          return;
        }

        // 发送加密后的数据（带重试，与 Android WifiConfigResetManager 一致）
        sent = false;
        for (var retry = 0; retry < 3; retry++) {
          sent = await _bleService.sendPairingDataRaw(char, encryptedData);
          if (sent) break;
          await Future.delayed(const Duration(seconds: 5));
          if (!mounted) return;
        }
      } catch (e) {
        debugPrint('BLE pairing encrypt error: $e');
        if (mounted) setState(() { _step = BlePairingStep.failed; _errorMessage = e.toString(); });
        return;
      }
    }

    if (!sent || !mounted) {
      setState(() { _step = BlePairingStep.failed; _errorMessage = l.sendPairingFailed; });
      return;
    }
    if (!isBleDirectConnect) {
      await _bleService.disconnect(device.device);
    }
    setState(() => _step = BlePairingStep.polling);
    if (!mounted) return;

    // 轮询检测绑定结果（与 Android CheckBindResultManager 一致，每10秒检查一次）
    final provider = context.read<DeviceProvider>();
    final deviceUuid = device.uuid ?? '';
    for (var i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      try {
        if (deviceUuid.isNotEmpty) {
          final result = await provider.deviceService.checkBindResult(deviceUuid);
          debugPrint('BLE pairing: checkBindResult=$result for uuid=$deviceUuid');
          // Android: "0" = 绑定成功
          if (result == 0) {
            setState(() => _step = BlePairingStep.success);
            final assetIds = provider.assets.map((a) => a.assetId).toList();
            if (assetIds.isNotEmpty) await provider.loadDevices(assetIds);
            return;
          }
        }
      } catch (e) {
        debugPrint('BLE pairing: checkBindResult error: $e');
      }
    }
    if (isBleDirectConnect) {
      await _bleService.disconnect(device.device);
    }
    if (mounted) setState(() { _step = BlePairingStep.failed; _errorMessage = l.bindTimeout; });
  }

  /// 雷达最多显示 5 个设备
  List<RadarDevice> get _radarDevices {
    final list = _scannedDevices.take(5).map((d) {
      final displayName = d.name.isEmpty || (d.name == 'RY' && d.infoLoaded)
          ? 'Unknown' : d.name;
      return RadarDevice(
          id: d.device.remoteId.str, name: displayName, imageUrl: d.imageUrl, raw: d);
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.blePairing)),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildContent(l)),
    );
  }

  Widget _buildContent(AppLocalizations l) {
    switch (_step) {
      case BlePairingStep.scanning:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          RadarScanWidget(
            size: 280,
            isScanning: true,
            devices: _radarDevices,
            onDeviceTap: (rd) {
              final bleDevice = _scannedDevices.firstWhere(
                  (d) => d.device.remoteId.str == rd.id);
              _selectDevice(bleDevice);
            },
          ),
          const SizedBox(height: 24),
          Text(l.scanning, style: TextStyle(color: Colors.grey[500])),
          if (_scannedDevices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l.foundDevices(_scannedDevices.length),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          if (_scannedDevices.length > 5)
            TextButton.icon(
              onPressed: () => _showAllDevices(l),
              icon: const Icon(Icons.devices, color: AppColors.primary),
              label: Text(l.moreDevices, style: const TextStyle(color: AppColors.primary)),
            ),
          const SizedBox(height: 8),
          if (_scannedDevices.isNotEmpty)
            AgButton(text: l.done, onPressed: () {
              _bleService.stopScan();
              _showAllDevices(l);
            }),
        ]));

      case BlePairingStep.connecting:
      case BlePairingStep.configuring:
      case BlePairingStep.polling:
      case BlePairingStep.success:
        return _buildPipelineUI(l);

      case BlePairingStep.failed:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_errorMessage ?? l.pairingFailed,
              style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          AgButton(text: l.rescan, onPressed: _startScan),
        ]));
    }
  }

  Widget _buildPipelineUI(AppLocalizations l) {
    final isConfiguring = _step == BlePairingStep.connecting || _step == BlePairingStep.configuring;
    final isPolling = _step == BlePairingStep.polling;
    final isSuccess = _step == BlePairingStep.success;
    final dev = _currentDevice;
    final displayName = (dev != null && dev.name.isNotEmpty && dev.name != 'RY')
        ? dev.name : 'Unknown';
    final imageUrl = dev?.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备信息
          Center(child: Column(children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultDeviceIcon()),
              )
            else
              _defaultDeviceIcon(),
            const SizedBox(height: 8),
            Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(height: 32),
          // Step 1: 正在配网
          _pipelineStep(
            label: l.pairingInProgress,
            isActive: isConfiguring,
            isDone: isPolling || isSuccess,
          ),
          _pipelineLine(isDone: isPolling || isSuccess),
          // Step 2: 等待设备绑定
          _pipelineStep(
            label: l.waitingDeviceBind,
            isActive: isPolling,
            isDone: isSuccess,
          ),
          _pipelineLine(isDone: isSuccess),
          // Step 3: 已连上设备云
          _pipelineStep(
            label: l.deviceCloudConnected,
            isActive: false,
            isDone: isSuccess,
          ),
          const Spacer(),
          if (isSuccess)
            AgButton(
              text: l.finishPairing,
              onPressed: () => context.go(AppRoutes.home),
            ),
        ],
      ),
    );
  }

  Widget _defaultDeviceIcon() {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: const Icon(Icons.speaker, color: AppColors.primary, size: 32),
    );
  }

  Widget _pipelineStep({required String label, required bool isActive, required bool isDone}) {
    return Row(
      children: [
        if (isDone)
          const Icon(Icons.check_circle, color: AppColors.success, size: 28)
        else if (isActive)
          const SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          )
        else
          Icon(Icons.radio_button_unchecked, color: Colors.grey[300], size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: (isActive || isDone) ? FontWeight.w600 : FontWeight.normal,
                color: isDone ? AppColors.success : (isActive ? AppColors.primary : Colors.grey[400]),
              )),
        ),
      ],
    );
  }

  Widget _pipelineLine({required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Container(
        width: 2, height: 32,
        color: isDone ? AppColors.success : Colors.grey[300],
      ),
    );
  }
}


/// 所有扫描到的蓝牙设备列表页（实时刷新）
class _AllDevicesPage extends StatefulWidget {
  final List<BleDeviceInfo> devices;
  final void Function(BleDeviceInfo) onSelect;
  final Stream<List<BleDeviceInfo>> scanStream;

  const _AllDevicesPage({
    required this.devices,
    required this.onSelect,
    required this.scanStream,
  });

  @override
  State<_AllDevicesPage> createState() => _AllDevicesPageState();
}

class _AllDevicesPageState extends State<_AllDevicesPage> {
  late List<BleDeviceInfo> _devices;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _devices = List.from(widget.devices);
    _sub = widget.scanStream.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.moreDevices),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: _devices.isEmpty
          ? Center(child: Text(l.noDeviceFound, style: TextStyle(color: Colors.grey[400])))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = _devices[index];
                final displayName = d.name.isEmpty || d.name == 'RY' && !d.infoLoaded
                    ? 'Unknown'
                    : d.name;
                return ListTile(
                  leading: d.imageUrl != null && d.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(d.imageUrl!, width: 44, height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultIcon()))
                      : _defaultIcon(),
                  title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(d.device.remoteId.str,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                    onPressed: () => widget.onSelect(d),
                  ),
                );
              },
            ),
    );
  }

  Widget _defaultIcon() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: const Icon(Icons.speaker, color: AppColors.primary, size: 24),
    );
  }
}
