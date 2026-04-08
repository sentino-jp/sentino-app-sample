import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/device_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/device_card.dart';
import '../device/fourg_pairing_page.dart';

/// 设备 Tab：设备管理列表视图，提供 3 种配网入口
class DeviceTab extends StatelessWidget {
  const DeviceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _pairingButton(context, Icons.bluetooth,
                      l.blePairing, () => context.push(AppRoutes.blePairing))),
                  const SizedBox(width: 8),
                  Expanded(child: _pairingButton(context, Icons.pin,
                      l.verifyCode, () => context.push(AppRoutes.fourgPairing))),
                  const SizedBox(width: 8),
                  Expanded(child: _pairingButton(context, Icons.qr_code,
                      l.barcode, () => context.push(AppRoutes.fourgPairing, extra: PairingMode.barcode))),
                ],
              ),
            ),
            Expanded(
              child: provider.devices.isEmpty
                  ? Center(child: Text(l.noDeviceAddFirst))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: provider.devices.length,
                      itemBuilder: (context, index) {
                        final device = provider.devices[index];
                        return DeviceCard(device: device,
                            onTap: () => context.push('/device/${device.deviceId}'));
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _pairingButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12))],
      ),
    );
  }
}
