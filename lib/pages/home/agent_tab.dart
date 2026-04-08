import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
          indicatorColor: AppColors.primary, indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [Tab(text: AppLocalizations.of(context)!.recommendAgents),
                 Tab(text: AppLocalizations.of(context)!.customAgents)],
        ),
      ),
      Expanded(child: Consumer<AgentProvider>(builder: (context, provider, _) {
        debugPrint('[AgentTab] isLoading=${provider.isLoading} recommend=${provider.recommendAgents.length} custom=${provider.customAgents.length} error=${provider.errorMessage}');
        if (provider.isLoading && provider.recommendAgents.isEmpty && provider.customAgents.isEmpty) {
          return AgLoading(message: AppLocalizations.of(context)!.loading);
        }
        return TabBarView(controller: _tabController, children: [
          _AgentListView(agents: provider.recommendAgents, onRefresh: () => context.read<AgentProvider>().loadAll()),
          _CustomAgentView(provider: provider),
        ]);
      })),
    ]);
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
    );
  }
}

class _AgentListView extends StatelessWidget {
  final List<Agent> agents;
  final Future<void> Function() onRefresh;
  const _AgentListView({required this.agents, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.noAgent, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      ]));
    }
    return RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: agents.length,
        separatorBuilder: (context, i) => const SizedBox(height: 2),
        itemBuilder: (context, index) => _AgentCard(agent: agents[index])));
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  const _AgentCard({required this.agent});
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () { if (agent.agentId != null) context.push('/agent/${agent.agentId}', extra: agent); },
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
          if (agent.tagNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 2,
                children: agent.tagNames.take(4).map((t) => _MiniTag(text: t)).toList())],
        ])),
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
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
