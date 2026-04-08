import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: 'id', readValue: _readUserId)
  final String? uid;
  @JsonKey(name: 'access_token')
  final String? accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final String? areaCode;
  @JsonKey(name: 'phone')
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? nickname;
  final String? userName;
  final int userType;
  final String? tz;
  final String? tempUnit;

  const User({
    this.uid,
    this.accessToken,
    this.refreshToken,
    this.areaCode,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.nickname,
    this.userName,
    this.userType = 1,
    this.tz,
    this.tempUnit,
  });

  /// Display name: nickname > userName > email > phone > uid
  String get displayName =>
      nickname ??
      userName ??
      email ??
      phoneNumber ??
      uid ??
      '';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Read userId from multiple possible field names
  static Object? _readUserId(Map<dynamic, dynamic> json, String key) =>
      json['id'] ?? json['userId'] ?? json['memberId'];
}
