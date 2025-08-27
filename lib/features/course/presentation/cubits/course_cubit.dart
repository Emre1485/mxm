import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/course.dart';
import '../../domain/repos/course_repository.dart';

part 'course_state.dart';

class CourseCubit extends Cubit<CourseState> {
  final CourseRepository courseRepo;

  CourseCubit({required this.courseRepo}) : super(CourseInitial());

  Future<void> getCourses(String userId, String role) async {
    emit(CourseLoading());
    try {
      final courses = await courseRepo.getCourses(userId, role);
      emit(CourseLoaded(courses));
    } catch (e) {
      emit(CourseError(message: 'Dersler yüklenemedi: $e'));
    }
  }

  Future<void> createCourse(Course course) async {
    emit(CourseLoading());
    try {
      await courseRepo.createCourse(course);
      final updatedCourses = await courseRepo.getCourses(
        course.teacherId,
        'teacher',
      );
      emit(CourseLoaded(updatedCourses));
    } catch (e) {
      emit(CourseError(message: 'Ders oluşturulamadı: $e'));
    }
  }
}
