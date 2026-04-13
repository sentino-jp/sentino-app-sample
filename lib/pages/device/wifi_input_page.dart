import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/ble_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// WiFi configuration page. WiFi list is scanned by the device over BLE.
class WifiInputPage extends StatefulWidget {
  final BleDeviceInfo? deviceInfo;

  const WifiInputPage({super.key, this.deviceInfo});

  @override
  State<WifiInputPage> createState() => _WifiInputPageState();
}

class _WifiInputPageState extends State<WifiInputPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bleService = BleService();
  bool _obscurePassword = true;
  bool _isScanning = false;
  List<BleWifiNetwork> _wifiList = [];
  Map<String, String> _savedPasswords = {};
  String? _lastSsid;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _scanWifi();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wifi_passwords');
    if (raw != null) {
      _savedPasswords = Map<String, String>.from(jsonDecode(raw));
    }
    _lastSsid = prefs.getString('last_wifi_ssid');
    if (_lastSsid != null && _lastSsid!.isNotEmpty) {
      _ssidController.text = _lastSsid!;
      if (_savedPasswords.containsKey(_lastSsid)) {
        _passwordController.text = _savedPasswords[_lastSsid]!;
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveWifiData(String ssid, String password) async {
    final prefs = await SharedPreferences.getInstance();
    _savedPasswords[ssid] = password;
    await prefs.setString('wifi_passwords', jsonEncode(_savedPasswords));
    await prefs.setString('last_wifi_ssid', ssid);
  }

  Future<void> _scanWifi() async {
    final deviceInfo = widget.deviceInfo;
    if (deviceInfo == null) return;

    setState(() {
      _isScanning = true;
      _scanError = null;
      _wifiList = [];
    });

    try {
      final networks = await _bleService.requestDeviceWifiList(
        deviceInfo.device,
      );
      if (!mounted) return;
      setState(() {
        _wifiList = networks;
        _isScanning = false;
      });
    } catch (e) {
      debugPrint('Device WiFi scan error: $e');
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _selectWifi(String ssid) {
    _ssidController.text = ssid;
    if (_savedPasswords.containsKey(ssid)) {
      _passwordController.text = _savedPasswords[ssid]!;
    } else {
      _passwordController.clear();
    }
    setState(() {});
  }

  BleWifiNetwork? get _selectedNetwork {
    final ssid = _ssidController.text.trim();
    if (ssid.isEmpty) return null;

    for (final network in _wifiList) {
      if (network.ssid == ssid) {
        return network;
      }
    }
    return null;
  }

  bool get _canSubmit =>
      _ssidController.text.trim().isNotEmpty &&
      (_selectedNetwork?.security == false ||
          _passwordController.text.isNotEmpty);

  IconData _signalIcon(int? rssi) {
    if (rssi == null) return Icons.wifi;
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -60) return Icons.wifi_2_bar;
    if (rssi >= -70) return Icons.wifi_1_bar;
    return Icons.wifi_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.wifiConfig)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AgTextField(
                    controller: _ssidController,
                    hintText: l.wifiName,
                    prefixIcon: const Icon(Icons.wifi),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AgTextField(
                    controller: _passwordController,
                    hintText: l.wifiPassword,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AgButton(
                    text: l.startPairing,
                    onPressed: _canSubmit
                        ? () {
                            final ssid = _ssidController.text.trim();
                            final password = _passwordController.text;
                            _saveWifiData(ssid, password);
                            context.pop<Map<String, String>>({
                              'ssid': ssid,
                              'password': password,
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    l.nearbyWifi,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (_isScanning)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _scanWifi,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildWifiList(l)),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiList(AppLocalizations l) {
    if (_isScanning && _wifiList.isEmpty) {
      return Center(
        child: Text(l.scanning, style: TextStyle(color: Colors.grey[500])),
      );
    }

    if (_scanError != null && _wifiList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _scanError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Text(l.noWifiFound, style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    if (_wifiList.isEmpty) {
      return Center(
        child: Text(l.noWifiFound, style: TextStyle(color: Colors.grey[400])),
      );
    }

    return ListView.separated(
      itemCount: _wifiList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final network = _wifiList[index];
        final ssid = network.ssid;
        final isLast = ssid == _lastSsid;

        return ListTile(
          leading: Icon(
            _signalIcon(network.rssi),
            color: isLast ? AppColors.primary : Colors.grey,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  ssid,
                  style: TextStyle(
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    color: isLast ? AppColors.primary : null,
                  ),
                ),
              ),
              if (isLast)
                Text(
                  l.savedWifi,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          trailing: network.security == null
              ? null
              : Icon(
                  network.security! ? Icons.lock_outline : Icons.lock_open,
                  size: 18,
                  color: Colors.grey[500],
                ),
          subtitle: network.rssi == null
              ? null
              : Text(
                  'RSSI ${network.rssi}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
          onTap: () => _selectWifi(ssid),
        );
      },
    );
  }
}
