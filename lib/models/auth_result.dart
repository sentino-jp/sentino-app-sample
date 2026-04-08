import 'package:json_annotation/json_annotation.dart';

part 'auth_result.g.dart';

@JsonSerializable()
class AuthResult {
  final String accessToken;
  final String uid;

  const AuthResult({
    required this.accessToken,
    required this.uid,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => _$AuthResultFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResultToJson(this);
}
