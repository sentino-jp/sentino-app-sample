// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
  agentId: json['agentId'] as String?,
  name: json['name'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  description: json['description'] as String?,
  languageId: json['languageId'] as String?,
  languageName: json['languageName'] as String?,
  modelId: json['modelId'] as String?,
  modelName: json['modelName'] as String?,
  voiceId: json['voiceId'] as String?,
  voiceName: json['voiceName'] as String?,
  agentType: json['agentType'] as String?,
  tagList: (json['tagList'] as List<dynamic>?)
      ?.map((e) => AgentTag.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
  'agentId': instance.agentId,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'description': instance.description,
  'languageId': instance.languageId,
  'languageName': instance.languageName,
  'modelId': instance.modelId,
  'modelName': instance.modelName,
  'voiceId': instance.voiceId,
  'voiceName': instance.voiceName,
  'agentType': instance.agentType,
  'tagList': instance.tagList,
};

AgentTag _$AgentTagFromJson(Map<String, dynamic> json) =>
    AgentTag(tagId: json['tagId'] as String?, name: json['name'] as String?);

Map<String, dynamic> _$AgentTagToJson(AgentTag instance) => <String, dynamic>{
  'tagId': instance.tagId,
  'name': instance.name,
};
