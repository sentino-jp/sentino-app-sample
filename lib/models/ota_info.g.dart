// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ota_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtaInfo _$OtaInfoFromJson(Map<String, dynamic> json) => OtaInfo(
  version: json['version'] as String,
  url: json['url'] as String,
  md5sum: json['md5sum'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
  firmwareType: (json['firmwareType'] as num).toInt(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$OtaInfoToJson(OtaInfo instance) => <String, dynamic>{
  'version': instance.version,
  'url': instance.url,
  'md5sum': instance.md5sum,
  'fileSize': instance.fileSize,
  'firmwareType': instance.firmwareType,
  'description': instance.description,
};
