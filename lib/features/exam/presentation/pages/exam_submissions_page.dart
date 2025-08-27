import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/presentation/pages/student_manual_grade_page.dart';

class ExamSubmissionsPage extends StatelessWidget {
  final String examId;
  const ExamSubmissionsPage({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('studentExamAnswers')
        .where('examId', isEqualTo: examId);

    return Scaffold(
      appBar: AppBar(title: const Text('Öğrenci Gönderimleri')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz gönderim yok.'));
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final studentId = data['studentId'] ?? '-';
              final status = data['status'] ?? '-';
              final total = data['totalScore'];
              final auto = (data['autoScore'] ?? 0).toString();
              final manual = (data['manualScore'] ?? 0).toString();

              return ListTile(
                title: Text("Öğrenci: $studentId"),
                subtitle: Text(
                  "Durum: $status • Auto: $auto • Manual: $manual • Toplam: ${total ?? '-'}",
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentManualGradePage(
                          examId: examId,
                          studentId: studentId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Puanla'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
