import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool isAnonymous;
  final DateTime createdAt;
  
  // New ERD fields
  final String fullName;
  final String roleId; // admin, chiefAccountant, accountant, salesperson, manager, partner, viewer
  final String? taxCode; // Nullable, only for 'partner' role
  final bool isActive;
  final String? passwordHash;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymous,
    required this.createdAt,
    required this.fullName,
    required this.roleId,
    this.taxCode,
    this.isActive = true,
    this.passwordHash,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
    String? fullName,
    String? roleId,
    String? taxCode,
    bool? isActive,
    String? passwordHash,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      taxCode: taxCode ?? this.taxCode,
      isActive: isActive ?? this.isActive,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'fullName': fullName,
      'roleId': roleId,
      'taxCode': taxCode,
      'isActive': isActive,
      'passwordHash': passwordHash,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return UserModel(
      uid: map['uid'] ?? map['userId'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: parsedDate,
      fullName: map['fullName'] ?? map['displayName'] ?? '',
      roleId: map['roleId'] ?? map['roleID'] ?? 'viewer', // default is viewer
      taxCode: map['taxCode'] ?? map['taxCode'],
      isActive: map['isActive'] ?? true,
      passwordHash: map['passwordHash'] ?? map['passwordHash'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, fullName: $fullName, roleId: $roleId, taxCode: $taxCode, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.isAnonymous == isAnonymous &&
      other.createdAt == createdAt &&
      other.fullName == fullName &&
      other.roleId == roleId &&
      other.taxCode == taxCode &&
      other.isActive == isActive &&
      other.passwordHash == passwordHash;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      isAnonymous.hashCode ^
      createdAt.hashCode ^
      fullName.hashCode ^
      roleId.hashCode ^
      taxCode.hashCode ^
      isActive.hashCode ^
      passwordHash.hashCode;
  }
}
