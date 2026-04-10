import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_text_field.dart';

/// WiFi 配置页面：支持 WiFi 扫描列表、密码缓存、蓝牙直连入口
class WifiInputPage extends StatefulWidget {
  const WifiInputPage({super.key});
  @override
  State<WifiInputPage> createState() => _WifiInputPageState();
}

class _WifiInputPageState extends State<WifiInputPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _bleDirectConnect = false;
  List<WiFiAccessPoint> _wifiList = [];
  Map<String, String> _savedPasswords = {};
  String? _lastSsid;

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
    // 自动填充上次使用的 WiFi
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
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // 请求位置权限（WiFi 扫描需要）
    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
    }
    try {
      final can = await WiFiScan.instance.canStartScan();
      if (can == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
      }
      final can2 = await WiFiScan.instance.canGetScannedResults();
      if (can2 == CanGetScannedResults.yes) {
        final results = await WiFiScan.instance.getScannedResults();
        if (mounted) {
          // 去重：同 SSID 只保留信号最强的，过滤空名称
          final seen = <String>{};
          final deduped = <WiFiAccessPoint>[];
          final sorted = results..sort((a, b) => b.level.compareTo(a.level));
          for (final ap in sorted) {
            if (ap.ssid.isEmpty) continue;
            if (seen.contains(ap.ssid)) continue;
            seen.add(ap.ssid);
            deduped.add(ap);
          }
          setState(() => _wifiList = deduped);
        }
      }
    } catch (e) {
      debugPrint('WiFi scan error: $e');
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

  bool get _canSubmit =>
      _ssidController.text.trim().isNotEmpty &&
      (_bleDirectConnect || _passwordController.text.isNotEmpty);

  IconData _signalIcon(int level) {
    if (level >= -50) return Icons.wifi;
    if (level >= -60) return Icons.wifi_2_bar;
    if (level >= -70) return Icons.wifi_1_bar;
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
                  // 蓝牙直连开关
                  Row(children: [
                    Text(l.bleDirectConnect),
                    const Spacer(),
                    Switch(
                      value: _bleDirectConnect,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _bleDirectConnect = v),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  AgTextField(
                    controller: _ssidController,
                    hintText: l.wifiName,
                    prefixIcon: const Icon(Icons.wifi),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (!_bleDirectConnect) ...[
                    const SizedBox(height: 12),
                    AgTextField(
                      controller: _passwordController,
                      hintText: l.wifiPassword,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AgButton(
                    text: l.startPairing,
                    onPressed: _canSubmit
                        ? () {
                            final ssid = _ssidController.text.trim();
                            final pwd = _passwordController.text;
                            _saveWifiData(ssid, pwd);
                            context.pop<Map<String, String>>({
                              'ssid': ssid,
                              'password': pwd,
                              'bleDirectConnect': _bleDirectConnect ? '1' : '0',
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            // WiFi 列表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Text(l.nearbyWifi,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _scanWifi,
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _wifiList.isEmpty
                  ? Center(child: Text(l.noWifiFound,
                      style: TextStyle(color: Colors.grey[400])))
                  : ListView.separated(
                      itemCount: _wifiList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ap = _wifiList[index];
                        final ssid = ap.ssid;
                        final isLast = ssid == _lastSsid;
                        return ListTile(
                          leading: Icon(_signalIcon(ap.level),
                              color: isLast ? AppColors.primary : Colors.grey),
                          title: Row(children: [
                            Expanded(child: Text(ssid,
                                style: TextStyle(
                                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                                    color: isLast ? AppColors.primary : null))),
                            if (isLast)
                              Text(AppLocalizations.of(context)!.savedWifi,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                          ]),
                          onTap: () => _selectWifi(ssid),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
