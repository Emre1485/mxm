import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile_exam/features/home/student/widgets/join_course_dialog.dart';
import 'package:mobile_exam/features/home/student/widgets/student_course_list.dart';

class StudentHomePage extends StatefulWidget {
  final String studentUid;

  const StudentHomePage({super.key, required this.studentUid});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  late Future<String?> _studentNameFuture;

  Future<String?> _getStudentName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentUid)
        .get();
    return doc.data()?['name'];
  }

  @override
  void initState() {
    super.initState();
    _studentNameFuture = _getStudentName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Öğrenci Ana Sayfası')),
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Kullanıcı adı
            FutureBuilder<String?>(
              future: _studentNameFuture,
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Öğrenci';
                return Text(
                  'Hoş geldin, $name',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text('Katıldığın dersler:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // Ders listesi
            Expanded(child: StudentCourseList(studentUid: widget.studentUid)),

            // Alt buton
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SafeArea(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Derse Katıl'),
                  onPressed: () =>
                      showJoinCourseDialog(context, widget.studentUid),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
