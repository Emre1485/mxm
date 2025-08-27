import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_exam/features/exam/domain/entities/question.dart';

class QuestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addQuestion(String examId, Question question) async {
    await _firestore
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .add(question.toMap());
  }
}
