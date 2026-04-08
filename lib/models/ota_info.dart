import 'package:json_annotation/json_annotation.dart';

part 'ota_info.g.dart';

@JsonSerializable()
class OtaInfo {
  final String version;
  final String url;
  final String md5sum;
  final int fileSize;
  final int firmwareType;
  final String? description;

  const OtaInfo({
    required this.version,
    required this.url,
    required this.md5sum,
    required this.fileSize,
    required this.firmwareType,
    this.description,
  });

  factory OtaInfo.fromJson(Map<String, dynamic> json) => _$OtaInfoFromJson(json);
  Map<String, dynamic> toJson() => _$OtaInfoToJson(this);
}
