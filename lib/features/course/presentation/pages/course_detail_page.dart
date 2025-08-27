import 'package:flutter/material.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile_exam/features/course/domain/entities/course.dart';
import 'package:mobile_exam/features/course/presentation/components/join_code_box.dart';
import 'package:mobile_exam/features/course/presentation/components/students_card.dart';
import 'package:mobile_exam/features/exam/presentation/components/exams_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(widget.course.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            JoinCodeBox(joinCode: widget.course.joinCode),
            const SizedBox(height: 20),
            StudentsCard(studentIds: widget.course.studentIds),
            const SizedBox(height: 12),
            if (currentUser != null)
              ExamsCard(courseId: widget.course.id, currentUser: currentUser),
          ],
        ),
      ),
    );
  }
}
