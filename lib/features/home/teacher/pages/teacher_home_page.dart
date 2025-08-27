import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile_exam/features/course/presentation/cubits/course_cubit.dart';
import 'package:mobile_exam/features/course/domain/entities/course.dart';
import 'package:mobile_exam/features/course/presentation/pages/course_create_page.dart';
import 'package:mobile_exam/features/course/presentation/pages/course_detail_page.dart';

class TeacherHomePage extends StatelessWidget {
  final AppUser teacher;

  const TeacherHomePage({Key? key, required this.teacher}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Öğretmen Paneli')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Hoş geldiniz ${teacher.name} ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Yeni Ders Oluştur'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseCreatePage(teacherUid: teacher.uid),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Center(
                child: Text(
                  'Dersleriniz:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: TeacherCoursesList(teacherUid: teacher.uid)),
          ],
        ),
      ),
    );
  }
}

class TeacherCoursesList extends StatefulWidget {
  final String teacherUid;

  const TeacherCoursesList({Key? key, required this.teacherUid})
    : super(key: key);

  @override
  State<TeacherCoursesList> createState() => _TeacherCoursesListState();
}

class _TeacherCoursesListState extends State<TeacherCoursesList> {
  @override
  void initState() {
    super.initState();
    // Cubit'i çağırıp dersleri yükle
    context.read<CourseCubit>().getCourses(widget.teacherUid, 'teacher');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      builder: (context, state) {
        if (state is CourseLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CourseLoaded) {
          final courses = state.courses;
          if (courses.isEmpty) {
            return const Center(child: Text('Henüz dersiniz yok.'));
          }
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final Course course = courses[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailPage(course: course),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              course.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Öğrenci Sayısı: ${course.studentIds.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else if (state is CourseError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
