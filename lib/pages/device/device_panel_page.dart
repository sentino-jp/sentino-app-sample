import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../providers/device_provider.dart';
import '../../repositories/api/api_agent_repository.dart';
import '../../repositories/api/api_device_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_client.dart';
import '../../utils/app_config.dart';
import '../../utils/storage.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_loading.dart';

/// Device panel page
class DevicePanelPage extends StatefulWidget {
  final String deviceId;
  const DevicePanelPage({super.key, required this.deviceId});
  @override
  State<DevicePanelPage> createState() => _DevicePanelPageState();
}

class _DevicePanelPageState extends State<DevicePanelPage> {
  double _volume = 50;
  Agent? _boundAgent;
  bool _loadingAgent = true;
  ApiDeviceRepository? _deviceRepo;
  Timer? _volumeDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().loadAll();
      _loadBoundAgent();
    });
  }

  @override
  void dispose() {
    _volumeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadBoundAgent() async {
    if (AppConfig.useMock) {
      setState(() => _loadingAgent = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageUtil(prefs);
      final apiClient = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
      final repo = ApiAgentRepository(api: apiClient);
      _deviceRepo = ApiDeviceRepository(api: apiClient);
      final agent = await repo.getAgentByDeviceId(widget.deviceId);
      debugPrint('DevicePanel: bound agent: ${agent?.agentId} ${agent?.displayName}');
      if (mounted) setState(() { _boundAgent = agent; _loadingAgent = false; });
    } catch (e) {
      debugPrint('DevicePanel: loadBoundAgent error: $e');
      if (mounted) setState(() => _loadingAgent = false);
    }
  }

  /// 音量变化时防抖下发属性
  void _onVolumeChanged(double value) {
    setState(() => _volume = value);
    _volumeDebounce?.cancel();
    _volumeDebounce = Timer(const Duration(milliseconds: 500), () {
      _sendVolume(value);
    });
  }

  Future<void> _sendVolume(double value) async {
    // 将 0~100 映射到 1~10
    final volumeLevel = (value / 10).round().clamp(1, 10);
    debugPrint('[DevicePanel] sendVolume: $volumeLevel (slider=$value)');
    try {
      await _deviceRepo?.propsIssue(widget.deviceId, {'volume_set': volumeLevel});
    } catch (e) {
      debugPrint('[DevicePanel] sendVolume error: $e');
      if (mounted) ToastUtil.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(icon: const Icon(Icons.menu),
            onPressed: () => context.push('/device-detail/${widget.deviceId}')),
      ]),
      body: Consumer<DeviceProvider>(builder: (context, dp, _) {
        final device = dp.devices.where((d) => d.deviceId == widget.deviceId).firstOrNull;
        if (device == null) return AgLoading(message: l.loading);
        return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
          _buildAgentCard(context, l),
          const SizedBox(height: 16),
          _buildVolumeCard(l),
          const SizedBox(height: 16),
          Card(child: ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            title: Text(l.chatHistory),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              final agentId = _boundAgent?.agentId ?? '';
              context.push('/chat-history/$agentId',
                  extra: {'targetId': widget.deviceId, 'targetType': 'device'});
            })),
        ]));
      }),
    );
  }

  Widget _buildAgentCard(BuildContext context, AppLocalizations l) {
    final agent = _boundAgent;
    if (_loadingAgent) {
      return const Card(child: Padding(padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator())));
    }
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      // Avatar
      agent?.avatarUrl != null && agent!.avatarUrl!.isNotEmpty
          ? CircleAvatar(radius: 40, backgroundImage: NetworkImage(agent.avatarUrl!))
          : CircleAvatar(radius: 40, backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.smart_toy, size: 40, color: AppColors.primary)),
      const SizedBox(height: 8),
      // Chat button
      Align(alignment: Alignment.centerRight, child: OutlinedButton(
        onPressed: () {
          final agentId = agent?.agentId ?? '';
          context.push('/chat-history/$agentId',
              extra: {'targetId': widget.deviceId, 'targetType': 'device'});
        },
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero),
        child: Text(l.enterChat, style: const TextStyle(fontSize: 12)))),
      // Name
      Text(agent?.displayName ?? '', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      // Tags
      if (agent != null && agent.tagNames.isNotEmpty)
        Wrap(spacing: 6, children: agent.tagNames
            .map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10)))).toList()),
      const SizedBox(height: 12),
      // Description
      if (agent != null && agent.displayDescription.isNotEmpty)
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8)),
          child: Text(agent.displayDescription, style: Theme.of(context).textTheme.bodySmall)),
      const SizedBox(height: 16),
      // Switch role
      Row(children: [Expanded(child: OutlinedButton.icon(
        onPressed: () => _showSwitchRoleSheet(context, l),
        icon: const Icon(Icons.swap_horiz, size: 18), label: Text(l.switchRole),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary))))]),
    ])));
  }

  Widget _buildVolumeCard(AppLocalizations l) {
    return Card(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.volume, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.volume_up, color: AppColors.primary),
          Expanded(child: Slider(value: _volume, min: 0, max: 100, activeColor: AppColors.primary,
              onChanged: _onVolumeChanged)),
        ]),
      ])));
  }

  void _showSwitchRoleSheet(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
        builder: (context, sc) {
          return DefaultTabController(length: 2, child: Consumer<AgentProvider>(
            builder: (context, provider, _) {
              return Column(children: [
                Padding(padding: const EdgeInsets.all(16),
                    child: Text(l.switchRole, style: Theme.of(context).textTheme.titleMedium)),
                TabBar(
                  labelColor: AppColors.primary, unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: [Tab(text: l.recommendAgents), Tab(text: l.customAgents)]),
                Expanded(child: TabBarView(children: [
                  _agentList(provider.recommendAgents, sc),
                  _agentList(provider.customAgents, sc),
                ])),
              ]);
            }));
        });
    });
  }

  Widget _agentList(List<Agent> agents, ScrollController sc) {
    if (agents.isEmpty) return const Center(child: Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey));
    return ListView.builder(controller: sc, itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return ListTile(
            leading: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
                ? CircleAvatar(backgroundImage: NetworkImage(agent.avatarUrl!))
                : const CircleAvatar(child: Icon(Icons.smart_toy)),
            title: Text(agent.displayName),
            subtitle: agent.displayDescription.isNotEmpty
                ? Text(agent.displayDescription, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
            onTap: () {
              Navigator.pop(context);
              // TODO: call bind agent API then reload
            });
        });
  }
}
