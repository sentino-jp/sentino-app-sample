import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_client.dart';
import '../../utils/app_config.dart';
import '../../utils/storage.dart';
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
  String? _avatarPath;
  String? _networkAvatarUrl;
  bool _obscureApiKey = true;

  ApiClient? _apiClient;

  bool get _isEditMode => widget.agent != null;

  @override
  void initState() {
    super.initState();
    _initApiClient();
    final a = widget.agent;
    if (a != null) {
      _nameController.text = a.name ?? '';
      _descController.text = a.description ?? '';
      _networkAvatarUrl = a.avatarUrl;
      _agentIdController.text = a.sentinoAgentId ?? '';
      // 编辑模式 apiKey 不回填，用 hint 提示"留空则不修改"
    }
  }

  Future<void> _initApiClient() async {
    if (AppConfig.useMock) return;
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageUtil(prefs);
    _apiClient = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _agentIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_nameController.text.trim().isEmpty) return false;
    if (_agentIdController.text.trim().isEmpty) return false;
    // 创建模式必须填 apiKey；编辑模式可空（不修改）
    if (!_isEditMode && _apiKeyController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 256);
    if (image != null && mounted) {
      setState(() {
        _avatarPath = image.path;
        _networkAvatarUrl = null;
      });
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarPath == null || _apiClient == null) return _networkAvatarUrl;
    try {
      final file = await MultipartFile.fromFile(_avatarPath!, filename: 'avatar.jpg');
      final formData = FormData.fromMap({'file': file});
      final response = await _apiClient!.dio.post(
        'business-app/v1/file/uploadFile',
        data: formData,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['code'] == 200) return data['data']?.toString();
    } catch (e) {
      if (mounted) ToastUtil.showError('Avatar upload failed: $e');
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final avatarUrl = await _uploadAvatar();
    if (!mounted) return;

    final apiKeyInput = _apiKeyController.text.trim();
    final agent = Agent(
      agentId: widget.agent?.agentId,
      name: _nameController.text.trim(),
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      avatarUrl: avatarUrl ?? widget.agent?.avatarUrl,
      agentType: 'customize',
      sentinoAgentId: _agentIdController.text.trim(),
      // 编辑模式下空字符串 → 不覆盖
      sentinoApiKey: apiKeyInput.isEmpty ? null : apiKeyInput,
    );

    final provider = context.read<AgentProvider>();
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
              avatarPath: _avatarPath,
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
            const SizedBox(height: 24),
            Consumer<AgentProvider>(builder: (context, provider, _) {
              return AgButton(
                text: l.save,
                isLoading: provider.isLoading,
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
  final String? avatarPath;
  final String? networkUrl;
  final VoidCallback onTap;
  const _AvatarPicker({
    required this.avatarPath,
    required this.networkUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = avatarPath != null;
    final hasNetwork = networkUrl != null && networkUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: hasLocal
              ? FileImage(File(avatarPath!))
              : (hasNetwork ? NetworkImage(networkUrl!) as ImageProvider : null),
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
