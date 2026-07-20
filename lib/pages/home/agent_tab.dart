import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/api/coucou_api.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_loading.dart';
import '../../l10n/app_localizations.dart';

class AgentTab extends StatefulWidget {
  const AgentTab({super.key});
  @override
  State<AgentTab> createState() => _AgentTabState();
}

class _AgentTabState extends State<AgentTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 统一 loadAll(withMine):coucou 模式内部走 coucou-server 代理(忽略 withMine),非 coucou 用 withMine /detail 探测「我的」
      context.read<AgentProvider>().loadAll(withMine: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(children: [
      Container(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor))),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightSecondaryText,
          indicatorColor: AppColors.primary,
          indicatorWeight: 0.5,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          tabs: [
            const Tab(text: 'Coucou'),
            Tab(text: l.recommendAgents),
            Tab(text: l.myAgents),
          ],
        ),
      ),
      Expanded(child: Consumer<AgentProvider>(builder: (context, provider, _) {
        if (provider.isLoading &&
            provider.recommendAgents.isEmpty &&
            provider.myAgents.isEmpty) {
          return AgLoading(message: l.loading);
        }
        return TabBarView(controller: _tabController, children: [
          const _CoucouAgentsView(),
          _AgentListView(
            agents: provider.recommendAgents,
            onRefresh: () =>
                context.read<AgentProvider>().loadAll(withMine: true),
          ),
          _AgentListView(
            agents: provider.myAgents,
            loading: provider.myLoading,
            onRefresh: () =>
                context.read<AgentProvider>().loadAll(withMine: true),
          ),
        ]);
      })),
    ]);
  }
}

/// Coucou 角色列表:coucou 模式下从 coucou-server 拉取(GET /api/coucou/agents)。
/// (扫码添加待 QR 契约敲定后接入。)
class _CoucouAgentsView extends StatefulWidget {
  const _CoucouAgentsView();
  @override
  State<_CoucouAgentsView> createState() => _CoucouAgentsViewState();
}

class _CoucouAgentsViewState extends State<_CoucouAgentsView> {
  Future<List<Agent>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AuthProvider>().isCoucouMode
        ? context.read<CoucouApi>().listCoucouAgents()
        : Future.value(const <Agent>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!context.read<AuthProvider>().isCoucouMode) {
      return Center(
        child: Text('登录 CouCou 账号后可用',
            style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _scanAndAdd,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('扫码添加 Coucou 角色'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Agent>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return AgLoading(message: l.loading);
            }
            final agents = snap.data ?? const <Agent>[];
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: agents.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      Center(
                          child: Column(children: [
                        Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('暂无 Coucou 角色，扫码添加',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      ])),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: agents.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 2),
                      itemBuilder: (context, i) => _AgentCard(agent: agents[i]),
                    ),
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _scanAndAdd() async {
    final raw = await context.push<String>(AppRoutes.barcodeScanner);
    if (raw == null || !mounted) return;
    final agentId = CoucouApi.parseCoucouAgentQr(raw);
    if (agentId == null) {
      ToastUtil.showError('不是有效的 Coucou 二维码');
      return;
    }
    final api = context.read<CoucouApi>();
    try {
      final agent = await api.agentPublic(agentId); // 预览
      if (!mounted) return;
      final ok = await showDialog<bool>(
            context: context,
            builder: (dlg) => AlertDialog(
              title: const Text('添加 Coucou 角色'),
              content: Text('添加「${agent.displayName}」到我的 Coucou 角色？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('取消')),
                TextButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('添加')),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
      await api.favoriteCoucouAgent(agentId);
      if (mounted) {
        ToastUtil.showSuccess('已添加 ${agent.displayName}');
        setState(_load);
      }
    } catch (e) {
      if (mounted) ToastUtil.showError(e.toString());
    }
  }
}

class _AgentListView extends StatelessWidget {
  final List<Agent> agents;
  final Future<void> Function() onRefresh;
  final bool loading;
  const _AgentListView({
    required this.agents,
    required this.onRefresh,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (agents.isEmpty) {
      if (loading) return Center(child: AgLoading(message: l.loading));
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(l.noAgent, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: agents.length,
        separatorBuilder: (context, i) => const SizedBox(height: 2),
        itemBuilder: (context, index) => _AgentCard(agent: agents[index]),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  const _AgentCard({required this.agent});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (agent.agentId != null) {
            context.push('/agent/${agent.agentId}', extra: agent);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.subtle),
              clipBehavior: Clip.antiAlias,
              child: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
                  ? Image.network(agent.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.smart_toy,
                          color: AppColors.primary,
                          size: 24))
                  : const Icon(Icons.smart_toy,
                      color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agent.displayName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    if (agent.displayDescription.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(agent.displayDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                    if (agent.displayTags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: agent.displayTags
                              .take(4)
                              .map((t) => _MiniTag(text: t))
                              .toList()),
                    ],
                  ]),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
          ]),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: AppColors.tagBg, borderRadius: BorderRadius.circular(3)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.tagText,
              fontWeight: FontWeight.w500,
              height: 1.2)),
    );
  }
}
