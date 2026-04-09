import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mqtt_service.dart';
import '../device/fourg_pairing_page.dart';
import 'agent_tab.dart';
import 'device_tab.dart';
import 'mine_tab.dart';

/// Main page
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  static const _tabs = [AgentTab(), DeviceTab(), MineTab()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<AuthProvider>().loadUserProfile();
      } catch (e) {
        debugPrint('[HomePage] loadUserProfile error: $e');
      }
      await _initMqtt();
    });
  }

  Future<void> _initMqtt() async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.userProfile?.uid;
      debugPrint('[HomePage] _initMqtt userId=$userId');
      if (userId == null || userId.isEmpty) {
        debugPrint('[HomePage] _initMqtt: userId is empty, skipping MQTT');
        return;
      }

      final mqtt = context.read<MqttService>();
      debugPrint('[HomePage] _initMqtt: connecting MQTT...');
      await mqtt.connect(userId);
      debugPrint('[HomePage] _initMqtt: MQTT connected=${mqtt.isConnected}');
      mqtt.subscribeUser(userId);

      // 订阅设备 asset topics
      final deviceProvider = context.read<DeviceProvider>();
      if (deviceProvider.assets.isEmpty) {
        debugPrint('[HomePage] _initMqtt: loading assets...');
        await deviceProvider.loadAssets();
      }
      debugPrint('[HomePage] _initMqtt: assets count=${deviceProvider.assets.length}');
      for (final asset in deviceProvider.assets) {
        debugPrint('[HomePage] subscribing asset: ${asset.assetId}');
        mqtt.subscribeAsset(asset.assetId);
      }
    } catch (e) {
      debugPrint('[HomePage] _initMqtt error: $e');
    }
  }

  Future<void> _reloadDevices() async {
    final provider = context.read<DeviceProvider>();
    await provider.loadAssets();
    final assetIds = provider.assets.map((a) => a.assetId).toList();
    if (assetIds.isNotEmpty) {
      await provider.loadDevices(assetIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final titles = [l.agent, l.device, l.mine];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        automaticallyImplyLeading: false,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push(AppRoutes.agentCreate),
            ),
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showPairingMenu(context, l),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) context.read<AgentProvider>().loadAll();
          if (i == 1) _reloadDevices();
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.smart_toy_outlined),
              activeIcon: const Icon(Icons.smart_toy),
              label: l.agent),
          BottomNavigationBarItem(
              icon: const Icon(Icons.devices_outlined),
              activeIcon: const Icon(Icons.devices),
              label: l.device),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l.mine),
        ],
      ),
    );
  }

  void _showPairingMenu(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(context: context, builder: (ctx) {
      return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.bluetooth, color: AppColors.primary),
          title: Text(l.blePairing),
          onTap: () { Navigator.pop(ctx); context.push(AppRoutes.blePairing); }),
        ListTile(
          leading: const Icon(Icons.pin, color: AppColors.primary),
          title: Text(l.verifyCode),
          onTap: () { Navigator.pop(ctx); context.push(AppRoutes.fourgPairing); }),
        ListTile(
          leading: const Icon(Icons.qr_code, color: AppColors.primary),
          title: Text(l.barcode),
          onTap: () {
            Navigator.pop(ctx);
            context.push(AppRoutes.fourgPairing, extra: PairingMode.barcode);
          }),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
          title: Text(l.scanBarcode),
          onTap: () { Navigator.pop(ctx); context.push(AppRoutes.barcodeScanner); }),
      ]));
    });
  }
}
