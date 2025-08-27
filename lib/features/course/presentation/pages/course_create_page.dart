import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/course/domain/entities/course.dart';
import 'package:mobile_exam/features/course/presentation/cubits/course_cubit.dart';

class CourseCreatePage extends StatefulWidget {
  final String teacherUid;
  const CourseCreatePage({super.key, required this.teacherUid});
  @override
  State<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends State<CourseCreatePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  String _generateJoinCode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - 6); // son 6
  }

  Future<void> _createCourse() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    final course = Course(
      id: '',
      name: name,
      teacherId: widget.teacherUid,
      studentIds: [],
      joinCode: _generateJoinCode(),
    );

    await context.read<CourseCubit>().createCourse(course);

    if (mounted) {
      Navigator.pop(context); // geri dön
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Ders Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Ders Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _createCourse,
              icon: Icon(Icons.check),
              label: Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
