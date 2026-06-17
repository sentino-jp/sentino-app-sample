import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_button.dart';

/// 自定义智能体页（创建 / 编辑）—— 绑定用户在 Sentino 平台申请到的 agent 凭证
class AgentCreatePage extends StatefulWidget {
  final Agent? agent;
  const AgentCreatePage({super.key, this.agent});
  @override
  State<AgentCreatePage> createState() => _AgentCreatePageState();
}

class _AgentCreatePageState extends State<AgentCreatePage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _agentIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _greetingController = TextEditingController();
  XFile? _picked;
  String? _networkAvatarUrl;
  String? _originalApiKey;
  bool _obscureApiKey = true;
  bool _uploading = false;

  bool get _isEditMode => widget.agent != null;

  /// 已选本地图的预览 provider。Web 上 XFile.path 是 blob: URL、dart:io File 不可用，
  /// 故用 NetworkImage 加载 blob；真机用 FileImage。
  ImageProvider? get _localAvatar {
    final p = _picked;
    if (p == null) return null;
    return kIsWeb ? NetworkImage(p.path) : FileImage(File(p.path));
  }

  @override
  void initState() {
    super.initState();
    final a = widget.agent;
    if (a != null) {
      _nameController.text = a.name ?? '';
      _descController.text = a.description ?? '';
      _networkAvatarUrl = a.avatarUrl;
      _agentIdController.text = a.refAgentId ?? '';
      _greetingController.text = a.greetingMessage ?? '';
      // 编辑模式总是拉 /detail：取原 apiKey（留空时回填，后端 update 必填）
      // + 补全 refAgentId/greeting。
      if (a.agentId != null) {
        _prefillFromDetail(a.agentId!);
      }
    }
  }

  Future<void> _prefillFromDetail(String agentId) async {
    final detail =
        await context.read<AgentProvider>().fetchAgentDetail(agentId);
    if (detail == null || !mounted) return;
    setState(() {
      _originalApiKey = detail.apiKey;
      _agentIdController.text = detail.refAgentId ?? _agentIdController.text;
      _greetingController.text =
          detail.greetingMessage ?? _greetingController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _agentIdController.dispose();
    _apiKeyController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_nameController.text.trim().isEmpty) return false;
    if (_agentIdController.text.trim().isEmpty) return false;
    // 创建模式必须填 apiKey；编辑模式可空（不修改）
    if (!_isEditMode && _apiKeyController.text.trim().isEmpty) return false;
    return true;
  }

  /// 过滤脱敏 apiKey：含掩码字符则视为脱敏，不回传（避免把脱敏串写回后端）。
  String? _safeApiKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    if (RegExp(r'[*•●·]').hasMatch(key)) return null;
    return key.trim();
  }

  /// 保证上传文件名带扩展名（Web 上 XFile.name 可能不含扩展名 → 后端生成的 URL 缺后缀）。
  String _avatarFilename(XFile file) {
    final name = file.name;
    if (name.contains('.') && !name.endsWith('.')) return name;
    final ext = switch (file.mimeType) {
      'image/png' => 'png',
      'image/gif' => 'gif',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      _ => 'jpg',
    };
    return 'avatar.$ext';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 256);
    if (image != null && mounted) {
      // 仅记录本地选图；不清空 _networkAvatarUrl —— 预览已优先显示本地图，
      // 且上传失败时原头像 URL 不丢、可继续沿用。
      setState(() => _picked = image);
    }
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<AgentProvider>();

    // 头像：选了新图就上传换取 URL；上传失败则中止提交并保留原头像，
    // 未选新图时沿用原有（编辑模式）网络头像。
    var avatarUrl = _networkAvatarUrl;
    final picked = _picked;
    if (picked != null) {
      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();
      final uploaded =
          await provider.uploadAvatar(bytes, filename: _avatarFilename(picked));
      if (!mounted) return;
      setState(() => _uploading = false);
      if (uploaded == null) return; // 上传失败（已 toast），原头像 URL 保留
      avatarUrl = uploaded;
    }

    final apiKeyInput = _apiKeyController.text.trim();
    final greetingInput = _greetingController.text.trim();
    // 编辑模式 apiKey 留空 → 沿用 /detail 取到的原 apiKey（后端 update 必填）。
    final effectiveApiKey =
        apiKeyInput.isNotEmpty ? apiKeyInput : _safeApiKey(_originalApiKey);
    final agent = Agent(
      agentId: widget.agent?.agentId,
      name: _nameController.text.trim(),
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      avatarUrl: avatarUrl,
      refAgentId: _agentIdController.text.trim(),
      apiKey: effectiveApiKey,
      greetingMessage: greetingInput.isEmpty ? null : greetingInput,
    );

    final ok = _isEditMode
        ? await provider.updateCustomAgent(agent)
        : await provider.createCustomAgent(agent);
    if (ok && mounted) {
      ToastUtil.showSuccess(AppLocalizations.of(context)!.save);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? l.editRole : l.customRole)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Center(child: _AvatarPicker(
              localImage: _localAvatar,
              networkUrl: _networkAvatarUrl,
              onTap: _pickAvatar,
            )),
            const SizedBox(height: 24),
            // Agent ID
            _fieldCard(required: true, label: l.agentIdLabel, child: TextField(
              controller: _agentIdController,
              decoration: InputDecoration(
                hintText: l.enterAgentId,
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(height: 12),
            // API Key
            _fieldCard(
              required: !_isEditMode,
              label: l.apiKeyLabel,
              child: TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  hintText: _isEditMode ? l.apiKeyEditHint : l.enterApiKey,
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      _obscureApiKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscureApiKey = !_obscureApiKey),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            _fieldCard(required: true, label: l.roleName, child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l.enterRoleName,
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(height: 12),
            // Description
            _fieldCard(label: l.roleIntro, child: TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(border: InputBorder.none),
            )),
            const SizedBox(height: 12),
            // Greeting message
            _fieldCard(label: l.greetingMessageLabel, child: TextField(
              controller: _greetingController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l.enterGreetingMessage,
                border: InputBorder.none,
              ),
            )),
            const SizedBox(height: 24),
            Consumer<AgentProvider>(builder: (context, provider, _) {
              return AgButton(
                text: l.save,
                isLoading: provider.isLoading || _uploading,
                onPressed: _canSubmit ? _handleSubmit : null,
              );
            }),
          ]),
        ),
      ),
    );
  }

  Widget _fieldCard({
    bool required = false,
    required String label,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (required)
              const Text('* ',
                  style: TextStyle(color: AppColors.error, fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final ImageProvider? localImage;
  final String? networkUrl;
  final VoidCallback onTap;
  const _AvatarPicker({
    required this.localImage,
    required this.networkUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localImage != null;
    final hasNetwork = networkUrl != null && networkUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: hasLocal
              ? localImage
              : (hasNetwork ? NetworkImage(networkUrl!) : null),
          child: !hasLocal && !hasNetwork
              ? const Icon(Icons.smart_toy, size: 48, color: AppColors.primary)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
