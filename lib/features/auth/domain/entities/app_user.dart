import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { teacher, parent, student }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role; // teacher, student, parent
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  // Convert App User -> json
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // convert json -> App User
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    final raw = jsonUser['createdAt'];
    DateTime? parsed;

    if (raw is Timestamp) {
      parsed = raw.toDate();
    } else if (raw is String) {
      parsed = DateTime.tryParse(raw);
    }

    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      name: jsonUser['name'],
      role: UserRole.values.firstWhere((e) => e.name == jsonUser['role']),
      createdAt: parsed,
    );
  }
}
