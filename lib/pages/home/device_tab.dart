import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_loading.dart';
import '../../widgets/device_card.dart';

/// 设备 Tab：展示设备数量统计和设备列表
class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key});

  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<DeviceProvider>();
    // coucou 模式：设备走 coucou-server（无 cetus 资产树/token），后端按 JWT 解析归属。
    if (context.read<AuthProvider>().isCoucouMode) {
      await provider.loadCoucouDevices();
      return;
    }
    await provider.loadAssets();
    final assetIds = provider.assets.map((a) => a.assetId).toList();
    if (assetIds.isNotEmpty) {
      await provider.loadDevices(assetIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.devices.isEmpty) {
          return AgLoading(message: l.loading);
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l.deviceCount(provider.devices.length),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              ),
              Expanded(
                child: provider.devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.devices_other,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(l.noDevice,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(l.addDeviceHint,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: provider.devices.length,
                        itemBuilder: (context, index) {
                          final device = provider.devices[index];
                          return DeviceCard(
                            device: device,
                            onTap: () =>
                                context.push('/device/${device.deviceId}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
