import 'package:cloud_firestore/cloud_firestore.dart';

/// MCQ + True/False otomatik puanlar. Essay'leri atlar.
/// Essay varsa status = 'needs_manual', yoksa 'auto_scored'.
Future<void> evaluateStudentExam(String examId, String studentId) async {
  final docRef = FirebaseFirestore.instance
      .collection("studentExamAnswers")
      .doc("$examId\_$studentId");

  final doc = await docRef.get();
  if (!doc.exists) return;

  final data = doc.data()!;
  final List<dynamic> answersList = (data["answers"] ?? []) as List<dynamic>;

  double autoScore = 0;
  int manualNeeded = 0;

  for (final item in answersList) {
    final qid = item["questionId"];
    final studentAnswer = item["answer"];
    final type = item["type"];

    final qDoc = await FirebaseFirestore.instance
        .collection("exams")
        .doc(examId)
        .collection("questions")
        .doc(qid)
        .get();
    if (!qDoc.exists) continue;

    final q = qDoc.data()!;
    final score = (q["score"] ?? 0) as num;

    if (type == "essay") {
      manualNeeded += 1;
      continue;
    }

    final correct = q["answer"];
    if (studentAnswer == correct) {
      autoScore += score.toDouble();
    }
  }

  final status = manualNeeded > 0 ? "needs_manual" : "auto_scored";

  await docRef.update({
    "autoScore": autoScore,
    "manualScore": data["manualScore"] ?? 0,
    "totalScore": manualNeeded > 0 ? null : autoScore,
    "status": status,
    "evaluatedAt": FieldValue.serverTimestamp(),
  });
}
