// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  uid: User._readUserId(json, 'id') as String?,
  accessToken: json['access_token'] as String?,
  refreshToken: json['refresh_token'] as String?,
  areaCode: json['areaCode'] as String?,
  phoneNumber: json['phone'] as String?,
  email: json['email'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  nickname: json['nickname'] as String?,
  userName: json['userName'] as String?,
  userType: (json['userType'] as num?)?.toInt() ?? 1,
  tz: json['tz'] as String?,
  tempUnit: json['tempUnit'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.uid,
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'areaCode': instance.areaCode,
  'phone': instance.phoneNumber,
  'email': instance.email,
  'avatarUrl': instance.avatarUrl,
  'nickname': instance.nickname,
  'userName': instance.userName,
  'userType': instance.userType,
  'tz': instance.tz,
  'tempUnit': instance.tempUnit,
};
