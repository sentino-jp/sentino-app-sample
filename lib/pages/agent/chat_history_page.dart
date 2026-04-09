import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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

  const ChatHistoryPage({
    super.key,
    required this.agentId,
    required this.targetId,
    this.targetType = 'device',
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
        // 按时间升序排列（旧消息在上）
        _messages.sort((a, b) {
          final ta = a['createTime'] as int? ?? 0;
          final tb = b['createTime'] as int? ?? 0;
          return ta.compareTo(tb);
        });
        debugPrint('[ChatHistory] loaded ${_messages.length} messages');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[ChatHistory] error: $_error');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.chatHistory)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.smart_toy, size: 18, color: AppColors.primary),
            ),
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
