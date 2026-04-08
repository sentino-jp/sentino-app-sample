// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResult _$AuthResultFromJson(Map<String, dynamic> json) => AuthResult(
  accessToken: json['accessToken'] as String,
  uid: json['uid'] as String,
);

Map<String, dynamic> _$AuthResultToJson(AuthResult instance) =>
    <String, dynamic>{'accessToken': instance.accessToken, 'uid': instance.uid};
