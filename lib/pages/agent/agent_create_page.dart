import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../repositories/api/api_agent_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_client.dart';
import '../../utils/app_config.dart';
import '../../utils/storage.dart';
import '../../utils/toast_util.dart';
import '../../widgets/ag_button.dart';

/// 自定义角色页（创建 / 编辑）
class AgentCreatePage extends StatefulWidget {
  final Agent? agent;
  const AgentCreatePage({super.key, this.agent});
  @override
  State<AgentCreatePage> createState() => _AgentCreatePageState();
}

class _AgentCreatePageState extends State<AgentCreatePage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _avatarPath;
  String? _networkAvatarUrl;
  String? _selectedLangId, _selectedLangName;
  String? _selectedVoiceId, _selectedVoiceName;
  String? _selectedModelId, _selectedModelName;
  bool _isPolishing = false;

  // Cached lists
  List<Map<String, dynamic>> _languages = [];
  List<Map<String, dynamic>> _voices = [];
  List<Map<String, dynamic>> _models = [];

  ApiAgentRepository? _agentRepo;

  @override
  void initState() {
    super.initState();
    _initRepo();
    final a = widget.agent;
    if (a != null) {
      _nameController.text = a.name ?? '';
      _descController.text = a.description ?? '';
      _networkAvatarUrl = a.avatarUrl;
      _selectedLangId = a.languageId;
      _selectedLangName = a.languageName;
      _selectedVoiceId = a.voiceId;
      _selectedVoiceName = a.voiceName;
      _selectedModelId = a.modelId;
      _selectedModelName = a.modelName;
    }
  }

  Future<void> _initRepo() async {
    if (AppConfig.useMock) return;
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageUtil(prefs);
    _agentRepo = ApiAgentRepository(
        api: ApiClient(baseUrl: AppConfig.baseUrl, storage: storage));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 256);
    if (image != null && mounted) setState(() { _avatarPath = image.path; _networkAvatarUrl = null; });
  }

  bool get _isEditMode => widget.agent != null;

  Future<void> _handleCreate() async {
    String? avatarUrl = _isEditMode ? widget.agent?.avatarUrl : null;

    // Upload avatar if selected
    if (_avatarPath != null && _agentRepo != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageUtil(prefs);
        final apiClient = ApiClient(baseUrl: AppConfig.baseUrl, storage: storage);
        final file = await MultipartFile.fromFile(_avatarPath!, filename: 'avatar.jpg');
        final formData = FormData.fromMap({'file': file});
        final response = await apiClient.dio.post(
          'business-app/v1/file/uploadFile',
          data: formData,
        );
        final data = response.data as Map<String, dynamic>;
        if (data['code'] == 200) {
          avatarUrl = data['data']?.toString();
        }
      } catch (e) {
        if (mounted) ToastUtil.showError('Avatar upload failed: $e');
        return;
      }
    }

    if (!mounted) return;

    if (_isEditMode) {
      // 编辑模式：调用 update API
      try {
        final updateData = <String, dynamic>{
          'agentId': widget.agent!.agentId,
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (_selectedLangId != null) 'langId': _selectedLangId,
          if (_selectedModelId != null) 'llmModelId': _selectedModelId,
          if (_selectedVoiceId != null) 'ttsVoiceId': _selectedVoiceId,
        };
        await _agentRepo?.updateCustomAgent(updateData);
        if (mounted) {
          await context.read<AgentProvider>().loadCustomAgents();
          ToastUtil.showSuccess(AppLocalizations.of(context)!.save);
          context.pop();
        }
      } catch (e) {
        if (mounted) ToastUtil.showError(e.toString());
      }
    } else {
      // 创建模式
      final agent = Agent(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        avatarUrl: avatarUrl,
        languageId: _selectedLangId,
        languageName: _selectedLangName,
        voiceId: _selectedVoiceId,
        voiceName: _selectedVoiceName,
        modelId: _selectedModelId,
        modelName: _selectedModelName,
      );
      final ok = await context.read<AgentProvider>().createCustomAgent(agent);
      if (ok && mounted) context.pop();
    }
  }

  Future<void> _polishDescription() async {
    final content = _descController.text.trim();
    if (content.isEmpty || _agentRepo == null) return;
    setState(() => _isPolishing = true);
    try {
      final result = await _agentRepo!.refinementText(content, language: _selectedLangName);
      if (mounted) {
        _descController.text = result;
        ToastUtil.showSuccess('Polish complete');
      }
    } catch (e) {
      if (mounted) ToastUtil.showError(e.toString());
    }
    if (mounted) setState(() => _isPolishing = false);
  }

  Future<void> _showLanguagePicker() async {
    if (_languages.isEmpty && _agentRepo != null) {
      try { _languages = await _agentRepo!.getLanguageList(); } catch (_) {}
    }
    if (!mounted || _languages.isEmpty) return;
    _showListPicker(
      items: _languages,
      idKey: 'langId', nameKey: 'name',
      onSelect: (id, name) => setState(() { _selectedLangId = id; _selectedLangName = name; }),
    );
  }

  Future<void> _showVoicePicker() async {
    if (_voices.isEmpty && _agentRepo != null) {
      try { _voices = await _agentRepo!.getVoiceList(); } catch (_) {}
    }
    if (!mounted || _voices.isEmpty) return;
    _showListPicker(
      items: _voices,
      idKey: 'voiceId', nameKey: 'name',
      onSelect: (id, name) => setState(() { _selectedVoiceId = id; _selectedVoiceName = name; }),
    );
  }

  Future<void> _showModelPicker() async {
    if (_models.isEmpty && _agentRepo != null) {
      try { _models = await _agentRepo!.getLlmList(); } catch (_) {}
    }
    if (!mounted || _models.isEmpty) return;
    _showListPicker(
      items: _models,
      idKey: 'modelId', nameKey: 'name',
      onSelect: (id, name) => setState(() { _selectedModelId = id; _selectedModelName = name; }),
    );
  }

  void _showListPicker({
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required void Function(String id, String name) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item[nameKey]?.toString() ?? ''),
            onTap: () {
              Navigator.pop(context);
              onSelect(item[idKey]?.toString() ?? '', item[nameKey]?.toString() ?? '');
            },
          );
        },
      ),
    );
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
            Center(child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(children: [
                CircleAvatar(radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _avatarPath != null
                        ? FileImage(File(_avatarPath!))
                        : (_networkAvatarUrl != null && _networkAvatarUrl!.isNotEmpty
                            ? NetworkImage(_networkAvatarUrl!) as ImageProvider
                            : null),
                    child: _avatarPath == null && (_networkAvatarUrl == null || _networkAvatarUrl!.isEmpty)
                        ? const Icon(Icons.smart_toy, size: 48, color: AppColors.primary) : null),
                Positioned(bottom: 0, right: 0, child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 16, color: Colors.white))),
              ]),
            )),
            const SizedBox(height: 24),
            // Name
            _fieldCard(required: true, label: l.roleName, child: TextField(
                controller: _nameController,
                decoration: InputDecoration(hintText: l.enterRoleName, border: InputBorder.none),
                onChanged: (_) => setState(() {}))),
            const SizedBox(height: 12),
            // Description + polish
            _fieldCard(
              required: true, label: l.roleIntro,
              trailing: GestureDetector(
                onTap: _isPolishing ? null : _polishDescription,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_isPolishing)
                    const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.auto_fix_high, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(l.polish, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ]),
              ),
              child: TextField(controller: _descController, maxLines: 5,
                  decoration: InputDecoration(hintText: l.roleIntroExample, border: InputBorder.none)),
            ),
            const SizedBox(height: 12),
            // Language
            _selectCard(required: true, label: l.languageLabel,
                value: _selectedLangName ?? l.selectLanguageOption, onTap: _showLanguagePicker),
            // Voice
            _selectCard(required: true, label: l.voiceTone,
                value: _selectedVoiceName ?? l.editVoice, onTap: _showVoicePicker),
            // Model
            _selectCard(required: true, label: l.modelLabel,
                value: _selectedModelName ?? l.selectModel, onTap: _showModelPicker),
            const SizedBox(height: 24),
            Consumer<AgentProvider>(builder: (context, provider, _) {
              return AgButton(text: l.save, isLoading: provider.isLoading,
                  onPressed: _canSubmit ? _handleCreate : null);
            }),
          ]),
        ),
      ),
    );
  }

  Widget _fieldCard({bool required = false, required String label, Widget? trailing, required Widget child}) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (required) const Text('* ', style: TextStyle(color: AppColors.error, fontSize: 14)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            ?trailing,
          ]),
          const SizedBox(height: 8), child,
        ])));
  }

  Widget _selectCard({bool required = false, required String label, required String value, required VoidCallback onTap}) {
    return Card(child: ListTile(
      title: Row(children: [
        if (required) const Text('* ', style: TextStyle(color: AppColors.error, fontSize: 14)),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ]),
      onTap: onTap,
    ));
  }
}
