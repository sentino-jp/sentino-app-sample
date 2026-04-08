import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/device_provider.dart';
import '../../routes/app_router.dart';
import '../../services/ble_service.dart';
import '../../theme/app_colors.dart';
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

  @override
  void initState() { super.initState(); _startScan(); }

  @override
  void dispose() { _scanSub?.cancel(); _bleService.stopScan(); super.dispose(); }

  Future<void> _startScan() async {
    setState(() { _step = BlePairingStep.scanning; _scannedDevices = []; _errorMessage = null; });
    final available = await _bleService.isBluetoothAvailable();
    if (!available) {
      setState(() { _step = BlePairingStep.failed;
        _errorMessage = AppLocalizations.of(context)!.bluetoothNotAvailable; });
      return;
    }
    _scanSub?.cancel();
    _scanSub = _bleService.scanResults.listen((devices) {
      if (mounted) setState(() => _scannedDevices = devices);
    });
    await _bleService.startScan(timeout: const Duration(seconds: 15));
    if (mounted && _scannedDevices.isEmpty) {
      setState(() { _step = BlePairingStep.failed;
        _errorMessage = AppLocalizations.of(context)!.noDeviceFound; });
    }
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
    setState(() => _step = BlePairingStep.configuring);
    final char = await _bleService.findPairingCharacteristic(device.device);
    if (char == null || !mounted) {
      setState(() { _step = BlePairingStep.failed; _errorMessage = l.deviceNotSupport; });
      return;
    }
    final sent = await _bleService.sendPairingData(char, {
      'ssid': wifiInfo['ssid'], 'password': wifiInfo['password']});
    if (!sent || !mounted) {
      setState(() { _step = BlePairingStep.failed; _errorMessage = l.sendPairingFailed; });
      return;
    }
    await _bleService.disconnect(device.device);
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
    if (mounted) setState(() { _step = BlePairingStep.failed; _errorMessage = l.bindTimeout; });
  }

  List<RadarDevice> get _radarDevices => _scannedDevices.map((d) => RadarDevice(
      id: d.device.remoteId.str, name: d.name, imageUrl: null, raw: d)).toList();

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
          const SizedBox(height: 24),
          if (_scannedDevices.isNotEmpty)
            AgButton(text: l.done, onPressed: () {
              _bleService.stopScan();
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
