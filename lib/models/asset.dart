import 'package:json_annotation/json_annotation.dart';

part 'asset.g.dart';

@JsonSerializable()
class Asset {
  @JsonKey(name: 'id')
  final String assetId;
  final String name;
  final bool currentSelected;
  @JsonKey(name: 'childrens')
  final List<Asset>? children;

  const Asset({
    required this.assetId,
    required this.name,
    this.currentSelected = false,
    this.children,
  });

  /// Alias for backward compatibility
  bool get isCurrentSelected => currentSelected;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
  Map<String, dynamic> toJson() => _$AssetToJson(this);
}
