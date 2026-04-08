// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Asset _$AssetFromJson(Map<String, dynamic> json) => Asset(
  assetId: json['id'] as String,
  name: json['name'] as String,
  currentSelected: json['currentSelected'] as bool? ?? false,
  children: (json['childrens'] as List<dynamic>?)
      ?.map((e) => Asset.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AssetToJson(Asset instance) => <String, dynamic>{
  'id': instance.assetId,
  'name': instance.name,
  'currentSelected': instance.currentSelected,
  'childrens': instance.children,
};
