import 'package:mobile_exam/features/course/domain/entities/course.dart';

abstract class CourseRepository {
  Future<void> createCourse(Course course);
  Future<List<Course>> getCourses(String userId, String role);
}
