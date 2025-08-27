import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_exam/features/exam/data/evaluate_student_exams.dart';

Future<void> reEvaluateAllSubmissions(String examId) async {
  final col = FirebaseFirestore.instance.collection('studentExamAnswers');
  final snap = await col.where('examId', isEqualTo: examId).get();

  for (final d in snap.docs) {
    final data = d.data();
    final studentId = (data['studentId'] ?? '') as String? ?? '';
    if (studentId.isEmpty) continue;

    final prevStatus = (data['status'] ?? '') as String;

    await evaluateStudentExam(examId, studentId);

    if (prevStatus == 'released') {
      await d.reference.update({'status': 'released'});
    }
  }
}
