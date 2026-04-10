import 'package:json_annotation/json_annotation.dart';

part 'agent.g.dart';

/// 智能体模型 — 字段名严格按照接口 JSON 定义
@JsonSerializable()
class Agent {
  final String? agentId;
  final String? name;
  final String? avatarUrl;
  final String? description;
  final String? languageId;
  final String? languageName;
  final String? modelId;
  final String? modelName;
  final String? voiceId;
  final String? voiceName;
  final String? agentType;
  final List<AgentTag>? tagList;

  const Agent({
    this.agentId,
    this.name,
    this.avatarUrl,
    this.description,
    this.languageId,
    this.languageName,
    this.modelId,
    this.modelName,
    this.voiceId,
    this.voiceName,
    this.agentType,
    this.tagList,
  });

  /// Display name
  String get displayName => name ?? agentId ?? '';

  /// Display description
  String get displayDescription => description ?? '';

  /// Tag names
  List<String> get tagNames =>
      tagList?.map((t) => t.name ?? '').where((n) => n.isNotEmpty).toList() ?? [];

  /// 所有可展示的 tag（包括 tagList + 语言/模型/音色）
  List<String> get displayTags {
    final tags = <String>[...tagNames];
    if (languageName != null && languageName!.isNotEmpty && !tags.contains(languageName)) {
      tags.add(languageName!);
    }
    if (modelName != null && modelName!.isNotEmpty && !tags.contains(modelName)) {
      tags.add(modelName!);
    }
    if (voiceName != null && voiceName!.isNotEmpty && !tags.contains(voiceName)) {
      tags.add(voiceName!);
    }
    return tags;
  }

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
  Map<String, dynamic> toJson() => _$AgentToJson(this);
}

/// 智能体标签
@JsonSerializable()
class AgentTag {
  final String? tagId;
  final String? name;

  const AgentTag({this.tagId, this.name});

  factory AgentTag.fromJson(Map<String, dynamic> json) => _$AgentTagFromJson(json);
  Map<String, dynamic> toJson() => _$AgentTagToJson(this);
}
