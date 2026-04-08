import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_button.dart';
import '../../widgets/ag_loading.dart';

/// 设备信息页（含网络信息查询与检测，与 Android 版保持一致）
class DeviceInfoPage extends StatefulWidget {
  final String deviceId;
  const DeviceInfoPage({super.key, required this.deviceId});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  bool _isChecking = false;
  int? _signalLevel; // 1好 2中 3差 4超时
  int? _signalValue; // 0-100

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

  /// 是否为 WiFi 直连设备（networkType==0 且无 gatewayId）
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

    try {
      final provider = context.read<DeviceProvider>();
      final result = await provider.checkSignal(widget.deviceId);
      if (!mounted) return;

      if (result != null && result.signalStrength != null) {
        final sv = result.signalStrength!;
        int level;
        if (sv >= 70) {
          level = 1; // 好
        } else if (sv >= 40) {
          level = 2; // 中
        } else {
          level = 3; // 差
        }
        setState(() {
          _signalLevel = level;
          _signalValue = sv;
          _isChecking = false;
        });
      } else {
        setState(() {
          _signalLevel = 4; // 超时
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signalLevel = 4;
          _isChecking = false;
        });
      }
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
            // 网络检测按钮（仅 WiFi 设备显示）
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
            // IP 地址（仅 WiFi 设备）
            if (isWifi)
              _infoRow(
                l.ipAddress,
                (device.ipAddress == null ||
                        device.ipAddress!.isEmpty ||
                        device.ipAddress == '0.0.0.0')
                    ? '- -'
                    : device.ipAddress!,
              ),
            // MAC 地址
            _infoRow(l.macAddress, device.macAddress ?? '- -'),
            // 信号连接
            _infoRow(l.signalConnection,
                device.protocolType ?? device.networkType ?? '- -'),
            // 信号强度（仅 WiFi 设备）
            if (isWifi)
              _infoRow(
                l.signalStrength,
                _signalValue != null
                    ? '$_signalValue%'
                    : (device.signalStrength != null &&
                            device.signalStrength! > 0)
                        ? '${device.signalStrength}%'
                        : '- -',
              ),
            // 网络检测结果
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
