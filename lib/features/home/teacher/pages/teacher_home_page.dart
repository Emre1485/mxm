import 'package:flutter/material.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';

class TeacherHomePage extends StatelessWidget {
  final AppUser teacher;

  const TeacherHomePage({Key? key, required this.teacher}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğretmen Paneli'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // TODO: Logout işlemi
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Hoş geldin ${teacher.name} 👋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Yeni Ders Oluştur'),
              onPressed: () {
                // TODO: Ders oluşturma sayfasına git
              },
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dersleriniz:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            // Expanded(
            //   child: _TeacherCoursesList(teacherUid: teacher.uid),
            // ),
          ],
        ),
      ),
    );
  }
}
