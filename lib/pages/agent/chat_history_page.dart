import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/api/api_agent_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_client.dart';
import '../../utils/app_config.dart';
import '../../utils/storage.dart';
import '../../widgets/ag_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 对话历史页面
class ChatHistoryPage extends StatefulWidget {
  final String agentId;
  final String targetId;
  final String targetType;
  final String? agentAvatarUrl;

  const ChatHistoryPage({
    super.key,
    required this.agentId,
    required this.targetId,
    this.targetType = 'device',
    this.agentAvatarUrl,
  });

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      if (AppConfig.useMock) {
        _messages = [];
      } else {
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageUtil(prefs);
        final apiClient = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
        final repo = ApiAgentRepository(api: apiClient);
        _messages = await repo.getConversationHistory(
            widget.agentId, widget.targetId, widget.targetType);
        // 按时间降序排列（最新消息在上）
        _messages.sort((a, b) {
          final ta = a['createTime'] as int? ?? 0;
          final tb = b['createTime'] as int? ?? 0;
          return tb.compareTo(ta);
        });
        debugPrint('[ChatHistory] loaded ${_messages.length} messages');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[ChatHistory] error: $_error');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmClear(AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.clearChatConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirm, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
    if (ok && mounted) {
      try {
        if (!AppConfig.useMock) {
          final prefs = await SharedPreferences.getInstance();
          final storage = StorageUtil(prefs);
          final apiClient = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
          final repo = ApiAgentRepository(api: apiClient);
          await repo.clearConversationHistory(widget.agentId);
        }
        if (mounted) setState(() => _messages.clear());
      } catch (e) {
        debugPrint('[ChatHistory] clear error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.chatHistory),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(l),
            ),
        ],
      ),
      body: _isLoading
          ? AgLoading(message: l.loading)
          : _error != null
              ? Center(child: Text(_error!))
              : _messages.isEmpty
                  ? Center(child: Text(l.noConversation))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';
                        return _buildMessageBubble(context, l, msg, isUser);
                      },
                    ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      final ms = timestamp is int ? timestamp : int.parse(timestamp.toString());
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp.toString();
    }
  }

  Widget _buildMessageBubble(BuildContext context, AppLocalizations l,
      Map<String, dynamic> msg, bool isUser) {
    final userProfile = context.read<AuthProvider>().userProfile;
    final userAvatarUrl = userProfile?.avatarUrl;
    final agentAvatarUrl = widget.agentAvatarUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            _buildAvatar(agentAvatarUrl, Icons.smart_toy, AppColors.primary.withValues(alpha: 0.1), AppColors.primary),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(isUser ? l.you : l.assistant,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg['content']?.toString() ?? '',
                      style: TextStyle(fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            _buildAvatar(userAvatarUrl, Icons.person, AppColors.primary, Colors.white),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, IconData fallbackIcon, Color bgColor, Color iconColor) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: bgColor,
      child: Icon(fallbackIcon, size: 18, color: iconColor),
    );
  }
}
