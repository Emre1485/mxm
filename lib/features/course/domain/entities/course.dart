import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String name;
  final String teacherId;
  final List<String> studentIds;
  final DateTime? createdAt;
  final String joinCode;

  Course({
    required this.id,
    required this.name,
    required this.teacherId,
    this.studentIds = const [],
    this.createdAt,
    required this.joinCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'createdAt': createdAt,
      'joinCode': joinCode,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json, String id) {
    return Course(
      id: id,
      name: json['name'] ?? '',
      teacherId: json['teacherId'] ?? '',
      studentIds: List<String>.from(json['studentIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      joinCode: json['joinCode'],
    );
  }
}
