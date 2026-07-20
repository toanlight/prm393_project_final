import 'dart:convert';

class RoleModel {
  final String roleId;
  final String roleName;
  final String description;

  const RoleModel({
    required this.roleId,
    required this.roleName,
    required this.description,
  });

  RoleModel copyWith({
    String? roleId,
    String? roleName,
    String? description,
  }) {
    return RoleModel(
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'description': description,
    };
  }

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      roleId: map['roleId'] ?? map['id'] ?? '',
      roleName: map['roleName'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RoleModel.fromJson(String source) => RoleModel.fromMap(json.decode(source));

  @override
  String toString() => 'RoleModel(roleId: $roleId, roleName: $roleName, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is RoleModel &&
      other.roleId == roleId &&
      other.roleName == roleName &&
      other.description == description;
  }

  @override
  int get hashCode => roleId.hashCode ^ roleName.hashCode ^ description.hashCode;
}
