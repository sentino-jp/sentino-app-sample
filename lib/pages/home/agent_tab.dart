import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/api/coucou_api.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ag_loading.dart';
import '../../l10n/app_localizations.dart';

class AgentTab extends StatefulWidget {
  const AgentTab({super.key});
  @override
  State<AgentTab> createState() => _AgentTabState();
}

class _AgentTabState extends State<AgentTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().loadAll();
    });
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
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
          tabs: [const Tab(text: 'Coucou'),
                 Tab(text: AppLocalizations.of(context)!.recommendAgents),
                 Tab(text: AppLocalizations.of(context)!.customAgents)],
        ),
      ),
      Expanded(child: Consumer<AgentProvider>(builder: (context, provider, _) {
        debugPrint('[AgentTab] isLoading=${provider.isLoading} recommend=${provider.recommendAgents.length} custom=${provider.customAgents.length} error=${provider.errorMessage}');
        if (provider.isLoading && provider.recommendAgents.isEmpty && provider.customAgents.isEmpty) {
          return AgLoading(message: AppLocalizations.of(context)!.loading);
        }
        return TabBarView(controller: _tabController, children: [
          const _CoucouAgentsView(),
          _AgentListView(agents: provider.recommendAgents, onRefresh: () => context.read<AgentProvider>().loadAll()),
          _CustomAgentView(provider: provider),
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
    return FutureBuilder<List<Agent>>(
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
                    Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('暂无 Coucou 角色',
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
    );
  }
}

class _CustomAgentView extends StatelessWidget {
  final AgentProvider provider;
  const _CustomAgentView({required this.provider});
  @override
  Widget build(BuildContext context) {
    return _AgentListView(
      agents: provider.customAgents,
      onRefresh: () => context.read<AgentProvider>().loadAll(),
      canDelete: true,
    );
  }
}

class _AgentListView extends StatelessWidget {
  final List<Agent> agents;
  final Future<void> Function() onRefresh;
  final bool canDelete;
  const _AgentListView({required this.agents, required this.onRefresh, this.canDelete = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (agents.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(l.noAgent, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      ]));
    }
    return RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: agents.length,
        separatorBuilder: (context, i) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final agent = agents[index];
          if (!canDelete) return _AgentCard(agent: agent);
          return _AgentCard(
            agent: agent,
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              onPressed: () => context.push(AppRoutes.agentCreate, extra: agent),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            onLongPress: () => _showDeleteSheet(context, agent, l),
          );
        }));
  }

  void _showDeleteSheet(BuildContext context, Agent agent, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: Text(l.delete, style: const TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, agent, l);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(l.cancel),
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Agent agent, AppLocalizations l) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(dlg, true),
              child: Text(l.confirm, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    ) ?? false;
    if (confirm && context.mounted) {
      final agentId = agent.agentId;
      if (agentId != null) {
        context.read<AgentProvider>().deleteCustomAgent(agentId);
      }
    }
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  final Widget? trailing;
  final VoidCallback? onLongPress;
  const _AgentCard({required this.agent, this.trailing, this.onLongPress});
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () { if (agent.agentId != null) context.push('/agent/${agent.agentId}', extra: agent); },
      onLongPress: onLongPress,
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.subtle),
          clipBehavior: Clip.antiAlias,
          child: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
              ? Image.network(agent.avatarUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.smart_toy, color: AppColors.primary, size: 24))
              : const Icon(Icons.smart_toy, color: AppColors.primary, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(agent.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (agent.displayDescription.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(agent.displayDescription, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]))],
          if (agent.displayTags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 2,
                children: agent.displayTags.take(4).map((t) => _MiniTag(text: t)).toList())],
        ])),
        if (trailing != null) trailing! else Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
      ]))));
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.tagBg, borderRadius: BorderRadius.circular(3)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.tagText, fontWeight: FontWeight.w500, height: 1.2)));
  }
}
