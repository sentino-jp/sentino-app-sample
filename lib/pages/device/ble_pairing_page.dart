import 'dart:async';
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
        onSelect: (device) {
          Navigator.pop(context);
          _selectDevice(device);
        },
      ),
    ));
  }

  Future<void> _selectDevice(BleDeviceInfo device) async {
    setState(() => _step = BlePairingStep.connecting);
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
      // 蓝牙直连模式：发送 bind 命令（参考 Android BleSinglePanelManager）
      sent = await _bleService.sendPairingData(char, {
        'type': 'network_set',
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': {'ble': 'bind', 'force_bind': false},
      });
    } else {
      // WiFi+BLE 配网模式：发送 WiFi 信息
      sent = await _bleService.sendPairingData(char, {
        'ssid': wifiInfo['ssid'], 'password': wifiInfo['password']});
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
    final provider = context.read<DeviceProvider>();
    for (var i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      try {
        setState(() => _step = BlePairingStep.success);
        final assetIds = provider.assets.map((a) => a.assetId).toList();
        if (assetIds.isNotEmpty) await provider.loadDevices(assetIds);
        return;
      } catch (_) {}
    }
    if (isBleDirectConnect) {
      await _bleService.disconnect(device.device);
    }
    if (mounted) setState(() { _step = BlePairingStep.failed; _errorMessage = l.bindTimeout; });
  }

  /// 雷达最多显示 5 个设备
  List<RadarDevice> get _radarDevices {
    final list = _scannedDevices.take(5).map((d) => RadarDevice(
        id: d.device.remoteId.str, name: d.name, imageUrl: d.imageUrl, raw: d)).toList();
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
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          const SizedBox(height: 16), Text(l.connectingDevice),
        ]));

      case BlePairingStep.configuring:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          const SizedBox(height: 16), Text(l.sendingConfig),
        ]));

      case BlePairingStep.polling:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          const SizedBox(height: 16), Text(l.waitingBind),
        ]));

      case BlePairingStep.success:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text(l.pairingSuccess, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          AgButton(text: l.done, onPressed: () => context.pop()),
        ]));

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
}


/// 所有扫描到的蓝牙设备列表页
class _AllDevicesPage extends StatelessWidget {
  final List<BleDeviceInfo> devices;
  final void Function(BleDeviceInfo) onSelect;

  const _AllDevicesPage({required this.devices, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.moreDevices)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final d = devices[index];
          return ListTile(
            leading: d.imageUrl != null && d.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(d.imageUrl!, width: 44, height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultIcon()))
                : _defaultIcon(),
            title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(d.device.remoteId.str,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              onPressed: () => onSelect(d),
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
