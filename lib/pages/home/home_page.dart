import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
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
