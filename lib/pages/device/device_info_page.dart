import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../services/mqtt_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/mqtt_logger.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_loading.dart';

/// 设备信息页（含网络信息查询与检测，�?Android 版保持一致）
class DeviceInfoPage extends StatefulWidget {
  final String deviceId;
  const DeviceInfoPage({super.key, required this.deviceId});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  bool _isChecking = false;
  int? _signalLevel; // 1�?2�?3�?4超时
  int? _signalValue; // 0-100
  Timer? _timeoutTimer;
  StreamSubscription? _mqttSub;
  int _signalTapCount = 0;
  DateTime? _lastSignalTap;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _mqttSub?.cancel();
    super.dispose();
  }

  /// Get default signal value from propertiesInfoDTO
  String _getDefaultSignalValue(Device device) {
    final props = device.propertiesInfoDTO;
    if (props != null) {
      final sv = props['signalValue'] as int?;
      if (sv != null && sv > 0) return '$sv%';
    }
    if (device.signalStrength != null && device.signalStrength! > 0) {
      return '${device.signalStrength}%';
    }
    return '- -';
  }

  /// Get default signal level from propertiesInfoDTO
  int? _getDefaultSignalLevel(Device device) {
    final props = device.propertiesInfoDTO;
    if (props != null) {
      return props['signal'] as int?;
    }
    return null;
  }

  void _onSignalRowTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastSignalTap != null && now.difference(_lastSignalTap!).inSeconds > 3) {
      _signalTapCount = 0;
    }
    _lastSignalTap = now;
    _signalTapCount++;
    if (_signalTapCount >= 5) {
      _signalTapCount = 0;
      _showMqttLogs(context);
    }
  }

  Future<void> _showMqttLogs(BuildContext context) async {
    final logs = await AppMqttLogger.getLogs();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('MQTT Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('No logs'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: logs.length,
                        itemBuilder: (_, i) {
                          final log = logs[logs.length - 1 - i]; // 最新的在上�?
                          final ts = DateTime.fromMillisecondsSinceEpoch(log['ts'] as int? ?? 0);
                          final time = '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
                          final type = log['type'] ?? '';
                          final msg = log['msg'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '[$time] [$type] $msg',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
  }

  void _showRenameDialog(String currentName, String? uuid) {
    final controller = TextEditingController(text: currentName);
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deviceInfo),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == currentName) return;
              try {
                final provider = context.read<DeviceProvider>();
                final device = provider.devices
                    .where((d) => d.deviceId == widget.deviceId)
                    .firstOrNull;
                if (device == null) return;
                final assetId = provider.assets.isNotEmpty
                    ? provider.assets.first.assetId
                    : '';
                await provider.renameDevice(
                    assetId, device.uuid ?? device.deviceId, newName);
                if (mounted) ToastUtil.showSuccess('OK');
              } catch (e) {
                if (mounted) ToastUtil.showError(e.toString());
              }
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }

  /// 是否�?WiFi 直连设备（networkType==0 且无 gatewayId�?
  bool _isWifiDevice(Device device) {
    final nt = device.networkType;
    return (nt == null || nt == '0' || nt.toLowerCase() == 'wifi');
  }

  Future<void> _handleCheckSignal() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _signalLevel = null;
      _signalValue = null;
    });

    // 监听 MQTT device_property_update 消息
    final mqtt = context.read<MqttService>();
    debugPrint('[DeviceInfo] MQTT connected: ${mqtt.isConnected}, deviceId: ${widget.deviceId}');
    _mqttSub?.cancel();
    _mqttSub = mqtt.messages.listen((data) {
      debugPrint('[DeviceInfo] MQTT message received: $data');
      final code = data['code']?.toString() ?? '';
      // 匹配 device_property_update �?signal_check_result
      if (code == 'device_property_update' || code == 'signal_check_result') {
        final msgData = data['data'] as Map<String, dynamic>? ?? {};
        final deviceId = msgData['deviceId']?.toString() ?? '';
        if (deviceId != widget.deviceId) return;

        // �?propertiesInfo 中提取信号数�?
        final props = msgData['propertiesInfo'] as Map<String, dynamic>? ?? msgData;
        final signal = props['signal'] as int?;
        final signalValue = props['signalValue'] as int?;

        if (signal != null) {
          _timeoutTimer?.cancel();
          _mqttSub?.cancel();
          if (mounted) {
            setState(() {
              _isChecking = false;
              _signalLevel = signal;
              _signalValue = signalValue ?? 0;
            });
          }
        }
      }
    });

    // 30 秒超�?
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      _mqttSub?.cancel();
      if (mounted) {
        setState(() {
          _isChecking = false;
          _signalLevel = 4;
          _signalValue = 0;
        });
      }
    });

    // 调用 checkSignal API 触发检�?
    try {
      final provider = context.read<DeviceProvider>();
      await provider.deviceService.checkSignal(widget.deviceId);
    } catch (e) {
      debugPrint('[NetworkDetection] checkSignal error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.deviceInfo)),
      body: Consumer<DeviceProvider>(builder: (context, provider, _) {
        final device = provider.devices
            .where((d) => d.deviceId == widget.deviceId)
            .firstOrNull;
        if (device == null) return AgLoading(message: l.loading);

        final isWifi = _isWifiDevice(device);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 设备名称卡片
                    _buildNameCard(context, device, l),
                    const SizedBox(height: 8),
                    // 设备信息卡片
                    _buildDeviceInfoCard(context, device, l),
                    const SizedBox(height: 8),
                    // 网络信息卡片
                    _buildNetworkInfoCard(context, device, l, isWifi),
                  ],
                ),
              ),
            ),
            // 网络检测按钮（�?WiFi 设备显示�?
            if (isWifi)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: AgButton(
                  text: _isChecking ? l.networkChecking : l.networkCheck,
                  isLoading: _isChecking,
                  onPressed: _isChecking ? null : _handleCheckSignal,
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildNameCard(
      BuildContext context, Device device, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            device.imageUrl != null && device.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(device.imageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => const _DeviceIcon()),
                  )
                : const _DeviceIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(device.name ?? '',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () =>
                  _showRenameDialog(device.name ?? '', device.uuid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(
      BuildContext context, Device device, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.deviceInfo,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _infoRow(l.deviceSn, device.uuid ?? '- -', copyable: true),
            _infoRow(l.deviceId, device.deviceId, copyable: true),
            _infoRow(l.deviceTimezone, device.timeZone ?? 'Asia/Shanghai'),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfoCard(
      BuildContext context, Device device, AppLocalizations l, bool isWifi) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.networkInfo,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            // IP 地址（仅 WiFi 设备�?
            if (isWifi)
              _infoRow(
                l.ipAddress,
                (device.ipAddress == null ||
                        device.ipAddress!.isEmpty ||
                        device.ipAddress == '0.0.0.0')
                    ? '- -'
                    : device.ipAddress!,
              ),
            // 信号连接
            GestureDetector(
              onTap: () => _onSignalRowTap(context),
              child: _infoRow(l.signalConnection,
                  device.protocolTypeName ?? device.protocolType ?? device.networkType ?? '- -'),
            ),
            // 信号强度（仅 WiFi 设备�?
            if (isWifi)
              _infoRow(
                l.signalStrength,
                _signalValue != null
                    ? '$_signalValue%'
                    : _getDefaultSignalValue(device),
              ),
            // 网络检测结�?
            if (_signalLevel != null) ...[
              const SizedBox(height: 16),
              _buildSignalResult(l),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignalResult(AppLocalizations l) {
    IconData icon;
    Color color;
    String text;

    switch (_signalLevel) {
      case 1:
        icon = Icons.signal_wifi_4_bar;
        color = AppColors.success;
        text = l.signalGood;
        break;
      case 2:
        icon = Icons.network_wifi_3_bar;
        color = Colors.orange;
        text = l.signalMedium;
        break;
      case 3:
        icon = Icons.network_wifi_1_bar;
        color = Colors.redAccent;
        text = l.signalBad;
        break;
      default:
        icon = Icons.signal_wifi_off;
        color = Colors.grey;
        text = l.signalCheckFail;
    }

    return Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w600)),
          if (_signalValue != null && _signalLevel != 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$_signalValue%',
                  style: TextStyle(color: color, fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value, style: TextStyle(color: Colors.grey[600]))),
          if (copyable)
            GestureDetector(
              onTap: () => _copy(value),
              child: Text(AppLocalizations.of(context)!.copy,
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: const Icon(Icons.speaker, color: AppColors.primary, size: 24),
    );
  }
}
