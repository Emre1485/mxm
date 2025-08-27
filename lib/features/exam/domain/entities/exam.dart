class Exam {
  final String id;
  final String name;
  final String description;
  final String courseId;
  final DateTime startTime;
  final int durationMinutes;
  final bool isPublished;
  final bool isDeleted;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.name,
    required this.description,
    required this.courseId,
    required this.startTime,
    required this.durationMinutes,
    required this.isPublished,
    required this.isDeleted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'courseId': courseId,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isPublished': isPublished,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map, String id) {
    return Exam(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      courseId: map['courseId'],
      startTime: DateTime.parse(map['startTime']),
      durationMinutes: map['durationMinutes'],
      isPublished: map['isPublished'],
      isDeleted: map['isDeleted'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Exam copyWith({
    String? id,
    String? name,
    String? description,
    String? courseId,
    DateTime? startTime,
    int? durationMinutes,
    bool? isPublished,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isPublished: isPublished ?? this.isPublished,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
