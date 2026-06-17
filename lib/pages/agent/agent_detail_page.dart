import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
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

  /// /detail 返回的完整详情（仅本人创建的智能体可获取）
  Agent? _detail;
  bool _detailLoading = true;

  /// 是否本人创建（=可编辑/删除）。由 /detail 是否成功判定。
  bool get _isMine => _detail != null;

  @override
  void initState() {
    super.initState();
    _loadPanelUrl();
    _loadDetail();
  }

  Future<void> _loadPanelUrl() async {
    // 暂时所有平台都使用原生详情页
    setState(() => _panelError = true);
  }

  Future<void> _loadDetail() async {
    final detail =
        await context.read<AgentProvider>().fetchAgentDetail(widget.agentId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _detailLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.agentDetail),
        actions: [
          if (_isMine) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () async {
                await context.push(AppRoutes.agentCreate, extra: _detail);
                if (mounted) _loadDetail();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(l),
            ),
          ],
        ],
      ),
      body: _buildBody(l),
    );
  }

  Future<void> _confirmDelete(AppLocalizations l) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (dlg) => AlertDialog(
            title: Text(l.deleteConfirmTitle),
            content: Text(l.deleteConfirmMessage),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dlg, false),
                  child: Text(l.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(dlg, true),
                  child: Text(l.confirm,
                      style: const TextStyle(color: AppColors.error))),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;
    // 删除失败（如已关联设备）时 Provider 会弹出后端错误提示，这里仅在成功后返回。
    final ok =
        await context.read<AgentProvider>().deleteCustomAgent(widget.agentId);
    if (ok && mounted) context.pop();
  }

  /// 掩码 api key: 前 3 后 2，中间星号；长度 < 6 全星
  String _maskApiKey(String? key) {
    if (key == null || key.isEmpty) return '-';
    if (key.length < 6) return '*' * key.length;
    return '${key.substring(0, 3)}***${key.substring(key.length - 2)}';
  }

  Widget _buildBody(AppLocalizations l) {
    if (_webController != null && !_panelError) {
      return Stack(children: [
        WebViewWidget(controller: _webController!),
        if (!_panelLoaded) Center(child: AgLoading(message: l.loadingPanel)),
      ]);
    }

    // 优先展示 /detail 返回的完整数据，回退到列表传入的基本信息
    final agent = _detail ?? widget.agent;
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
        // 本人创建的智能体：展示绑定凭证（refAgentId 完整、apiKey 掩码）+ 欢迎语
        if (_isMine) ...[
          _infoRow(l.agentIdLabel, agent.refAgentId ?? '-'),
          _infoRow(l.apiKeyLabel, _maskApiKey(agent.apiKey)),
          if (agent.greetingMessage != null &&
              agent.greetingMessage!.isNotEmpty)
            _infoRow(l.greetingMessageLabel, agent.greetingMessage!),
        ],
        const SizedBox(height: 24),
        // 对话记录入口：仅本人创建的智能体可见
        if (_isMine)
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary),
              title: Text(l.chatHistory),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                context.push('/chat-history/${widget.agentId}', extra: {
                  'targetId': '',
                  'targetType': 'device',
                  'agentAvatarUrl': agent.avatarUrl ?? ''
                });
              },
            ),
          ),
        if (_detailLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
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
              Flexible(child: Text(value, textAlign: TextAlign.end))
            ]));
  }
}
