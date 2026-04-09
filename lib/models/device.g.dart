// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  deviceId: _idToString(json['id']),
  uuid: _nullableToString(json['uuid']),
  productId: _nullableToString(json['productId']),
  name: _nullableToString(json['name']),
  imageUrl: _nullableToString(json['imageUrl']),
  onlineStatusCode: (json['onlineStatus'] as num?)?.toInt(),
  firmwareVersion: _nullableToString(json['firmwareVersion']),
  mcuVersion: _nullableToString(json['mcuVersion']),
  protocolType: _nullableToString(json['protocolType']),
  ipAddress: _nullableToString(json['ip']),
  currentSsid: _nullableToString(json['currentSsid']),
  signalStrength: (json['signalStrength'] as num?)?.toInt(),
  macAddress: _nullableToString(json['mac']),
  networkType: _nullableToString(json['networkType']),
  barcode: _nullableToString(json['barcode']),
  timeZone: _nullableToString(json['timeZone']),
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'id': instance.deviceId,
  'uuid': instance.uuid,
  'productId': instance.productId,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'onlineStatus': instance.onlineStatusCode,
  'firmwareVersion': instance.firmwareVersion,
  'mcuVersion': instance.mcuVersion,
  'protocolType': instance.protocolType,
  'ip': instance.ipAddress,
  'currentSsid': instance.currentSsid,
  'signalStrength': instance.signalStrength,
  'mac': instance.macAddress,
  'networkType': instance.networkType,
  'barcode': instance.barcode,
  'timeZone': instance.timeZone,
};
