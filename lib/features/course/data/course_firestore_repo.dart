import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_exam/features/course/domain/entities/course.dart';
import 'package:mobile_exam/features/course/domain/repos/course_repository.dart';

class CourseFirestoreRepo implements CourseRepository {
  final FirebaseFirestore _firestore;

  CourseFirestoreRepo({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  @override
  Future<void> createCourse(Course course) async {
    final docRef = _firestore.collection('courses').doc();
    await docRef.set({
      ...course.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Course>> getCourses(String userId, String role) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    if (role == 'teacher') {
      snapshot = await _firestore
          .collection('courses')
          .where('teacherId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
    } else {
      // Öğrenci veya veli için logic
      snapshot = await _firestore
          .collection('courses')
          .where('studentIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
    }

    return snapshot.docs
        .map((doc) => Course.fromJson(doc.data(), doc.id))
        .toList();
  }
}
