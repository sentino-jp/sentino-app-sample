import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_button.dart';

/// 设备详情页（菜单式）：设备信息、设备升级、移除设备
class DeviceDetailPage extends StatelessWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.deviceDetail)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _menuCard(context, l.deviceInfo, Icons.info_outline, () {
              context.push('/device-info/$deviceId');
            }),
            const SizedBox(height: 8),
            _menuCard(context, l.deviceUpgrade, Icons.system_update, () {
              context.push('/ota/$deviceId');
            }, trailing: Text(l.latestFirmware,
                style: TextStyle(color: Colors.grey[500], fontSize: 13))),
            const Spacer(),
            AgButton(
              text: l.removeDevice,
              onPressed: () => _showRemoveDialog(context, l),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {Widget? trailing}) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[trailing, const SizedBox(width: 4)],
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context, AppLocalizations l) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.unbindTitle),
        content: Text(l.unbindMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'unbind'),
              child: Text(l.unbindOnly)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'unbind_clean'),
              child: Text(l.unbindAndClean,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    final provider = context.read<DeviceProvider>();
    final ok = await provider.unbindDevice(deviceId,
        cleanData: result == 'unbind_clean');
    if (ok && context.mounted) context.pop();
  }
}
