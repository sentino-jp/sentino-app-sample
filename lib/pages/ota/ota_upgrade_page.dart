import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ota_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_button.dart';

/// OTA 升级页面
class OtaUpgradePage extends StatefulWidget {
  final String deviceId;
  const OtaUpgradePage({super.key, required this.deviceId});

  @override
  State<OtaUpgradePage> createState() => _OtaUpgradePageState();
}

class _OtaUpgradePageState extends State<OtaUpgradePage> {
  @override
  void initState() {
    super.initState();
    context.read<OtaProvider>().checkUpgrade(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.firmwareUpgrade)),
      body: Consumer<OtaProvider>(
        builder: (context, provider, _) {
          return Padding(padding: const EdgeInsets.all(24),
              child: _buildContent(provider, l));
        },
      ),
    );
  }

  Widget _buildContent(OtaProvider provider, AppLocalizations l) {
    switch (provider.status) {
      case OtaStatus.checking:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          const SizedBox(height: 16), Text(l.checkingUpdate),
        ]));
      case OtaStatus.idle:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text(l.latestVersion, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          AgButton(text: l.back, onPressed: () => context.pop()),
        ]));
      case OtaStatus.available:
        final info = provider.otaInfo!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.newVersionFound, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _infoRow(l.versionNumber, info.version),
              _infoRow(l.fileSize, '${(info.fileSize / 1024).toStringAsFixed(0)} KB'),
              if (info.description != null) ...[
                const SizedBox(height: 12),
                Text(l.upgradeNotes, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4), Text(info.description!),
              ],
            ]))),
          const Spacer(),
          AgButton(text: l.upgradeNow, onPressed: () => provider.startUpgrade()),
        ]);
      case OtaStatus.upgrading:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 120, height: 120, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: provider.progress / 100, strokeWidth: 8,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: Colors.grey[200]),
            Text('${provider.progress}%', style: Theme.of(context).textTheme.headlineSmall),
          ])),
          const SizedBox(height: 24),
          Text(provider.progress < 80 ? l.downloadingFirmware : l.flashingFirmware,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(l.doNotDisconnect, style: const TextStyle(color: Colors.grey)),
        ]));
      case OtaStatus.success:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text(l.upgradeSuccess, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          AgButton(text: l.done, onPressed: () => context.pop()),
        ]));
      case OtaStatus.failed:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(provider.errorMessage ?? l.upgradeFailed, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          AgButton(text: l.retry, onPressed: () => provider.checkUpgrade(widget.deviceId)),
        ]));
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]));
  }
}
