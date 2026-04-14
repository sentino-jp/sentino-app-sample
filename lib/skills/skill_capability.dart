/// 描述 Skill 的单个能力（公开方法名 + 简要说明）
class SkillCapability {
  final String name;
  final String description;

  const SkillCapability({
    required this.name,
    required this.description,
  });

  factory SkillCapability.fromJson(Map<String, dynamic> json) {
    return SkillCapability(
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillCapability &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => name.hashCode ^ description.hashCode;

  @override
  String toString() => 'SkillCapability(name: $name, description: $description)';
}
