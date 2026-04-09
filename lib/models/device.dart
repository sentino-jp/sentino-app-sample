import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

/// Device model - all String? fields use _nullableToString to handle int/String from API
@JsonSerializable()
class Device {
  @JsonKey(name: 'id', fromJson: _idToString)
  final String deviceId;
  @JsonKey(fromJson: _nullableToString)
  final String? uuid;
  @JsonKey(fromJson: _nullableToString)
  final String? productId;
  @JsonKey(fromJson: _nullableToString)
  final String? name;
  @JsonKey(fromJson: _nullableToString)
  final String? imageUrl;
  @JsonKey(name: 'onlineStatus')
  final int? onlineStatusCode;
  @JsonKey(fromJson: _nullableToString)
  final String? firmwareVersion;
  @JsonKey(fromJson: _nullableToString)
  final String? mcuVersion;
  @JsonKey(fromJson: _nullableToString)
  final String? protocolType;
  @JsonKey(fromJson: _nullableToString)
  final String? protocolTypeName;
  @JsonKey(name: 'ip', fromJson: _nullableToString)
  final String? ipAddress;
  @JsonKey(fromJson: _nullableToString)
  final String? currentSsid;
  final int? signalStrength;
  @JsonKey(name: 'mac', fromJson: _nullableToString)
  final String? macAddress;
  @JsonKey(fromJson: _nullableToString)
  final String? networkType;
  @JsonKey(fromJson: _nullableToString)
  final String? barcode;
  @JsonKey(fromJson: _nullableToString)
  final String? timeZone;
  final Map<String, dynamic>? propertiesInfoDTO;

  const Device({
    required this.deviceId,
    this.uuid,
    this.productId,
    this.name,
    this.imageUrl,
    this.onlineStatusCode,
    this.firmwareVersion,
    this.mcuVersion,
    this.protocolType,
    this.protocolTypeName,
    this.ipAddress,
    this.currentSsid,
    this.signalStrength,
    this.macAddress,
    this.networkType,
    this.barcode,
    this.timeZone,
    this.propertiesInfoDTO,
  });

  bool get online => onlineStatusCode == 1;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}

String _idToString(dynamic value) => value?.toString() ?? '';
String? _nullableToString(dynamic value) => value?.toString();
