import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/agent.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_config.dart';
import '../../widgets/ag_loading.dart';

/// Agent detail page with chat history entry
class AgentDetailPage extends StatefulWidget {
  final String agentId;
  final Agent? agent;
  const AgentDetailPage({super.key, required this.agentId, this.agent});

  @override
  State<AgentDetailPage> createState() => _AgentDetailPageState();
}

class _AgentDetailPageState extends State<AgentDetailPage> {
  WebViewController? _webController;
  bool _panelLoaded = false;
  bool _panelError = false;

  @override
  void initState() {
    super.initState();
    _loadPanelUrl();
  }

  Future<void> _loadPanelUrl() async {
    // 暂时所有平台都使用原生详情页
    setState(() => _panelError = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.agentDetail)),
      body: _buildBody(l),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_webController != null && !_panelError) {
      return Stack(children: [
        WebViewWidget(controller: _webController!),
        if (!_panelLoaded) Center(child: AgLoading(message: l.loadingPanel)),
      ]);
    }

    final agent = widget.agent;
    if (agent == null) return Center(child: Text(l.noAgentData));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Avatar
        agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 48, backgroundImage: NetworkImage(agent.avatarUrl!))
            : CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.smart_toy,
                    size: 48, color: AppColors.primary)),
        const SizedBox(height: 16),
        Text(agent.displayName,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        // Description
        if (agent.displayDescription.isNotEmpty)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      width: double.infinity,
                      child: Text(agent.displayDescription,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis)))),
        const SizedBox(height: 16),
        // Tags
        if (agent.tagNames.isNotEmpty)
          Wrap(
              spacing: 8,
              children: agent.tagNames
                  .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12))))
                  .toList()),
        // Info rows
        if (agent.modelName != null) _infoRow(l.modelLabel, agent.modelName!),
        if (agent.languageName != null)
          _infoRow(l.languageLabel, agent.languageName!),
        if (agent.voiceName != null) _infoRow(l.voiceTone, agent.voiceName!),
        const SizedBox(height: 24),
        // Chat history entry（sentino 类型智能体禁用，自定义智能体保留）
        if (agent.agentType != 'sentino')
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
              title: Text(l.chatHistory),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                context.push('/chat-history/${widget.agentId}',
                    extra: {'targetId': '', 'targetType': 'device'});
              },
            ),
          ),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600])),
              Text(value)
            ]));
  }
}
