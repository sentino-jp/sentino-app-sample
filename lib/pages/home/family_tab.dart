import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_loading.dart';
import '../../widgets/device_card.dart';
import '../../l10n/app_localizations.dart';

/// 首页 Tab：展示设备数量和设备列表
class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<DeviceProvider>();
    debugPrint('FamilyTab: loading assets...');
    await provider.loadAssets();
    debugPrint('FamilyTab: assets loaded: ${provider.assets.length}, error: ${provider.errorMessage}');
    final assetIds = provider.assets.map((a) => a.assetId).toList();
    debugPrint('FamilyTab: assetIds=$assetIds');
    if (assetIds.isNotEmpty) {
      await provider.loadDevices(assetIds);
      debugPrint('FamilyTab: devices loaded: ${provider.devices.length}, error: ${provider.errorMessage}');
    } else {
      debugPrint('FamilyTab: no assets found, skipping device load');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.devices.isEmpty) {
          return AgLoading(message: AppLocalizations.of(context)!.loading);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 设备数量
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  AppLocalizations.of(context)!.deviceCount(provider.devices.length),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
              // 设备列表
              Expanded(
                child: provider.devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.devices_other,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.noDevice,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(AppLocalizations.of(context)!.addDeviceHint,
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
                            onTap: () => context
                                .push('/device/${device.deviceId}'),
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
