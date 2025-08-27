import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal istatistik servisi.
/// Not: Burada essay soruları "soru doğruluk oranı" ve "yanlış konu" istatistiklerine dahil ETMİYORUZ.
/// (İstersek earnedScore'la başka bir mantık eklenebilir.)
class ExamStatsService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, Map<String, dynamic>>> _fetchQuestions(
    String examId,
  ) async {
    final qs = await _db
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .get();
    final map = <String, Map<String, dynamic>>{};
    for (final d in qs.docs) {
      final data = d.data();
      map[d.id] = {
        'questionText': data['questionText'] ?? '',
        'topic': data['topic'] ?? '',
        'score': (data['score'] is num) ? data['score'] as num : 0,
        'answer': data['answer'], // null olabilir (essay)
        'type': data['type'] ?? '',
      };
    }
    return map;
  }

  /// GENEL (sınıf) istatistikleri: toplam öğrenci, ortalama, soru doğruluk, yanlış konu dağılımı
  Future<Map<String, dynamic>> getExamStatsOverall(String examId) async {
    final questions = await _fetchQuestions(examId);

    // Bu sınava cevap veren tüm öğrenciler
    final allAnsSnap = await _db
        .collection('studentExamAnswers')
        .where('examId', isEqualTo: examId)
        .get();

    final totalStudents = allAnsSnap.docs.length;
    num totalScoreSum = 0;

    // Soru bazlı doğru sayısı, yanlış konu dağılımı
    final correctCountPerQuestion = <String, int>{};
    final topicWrongCount = <String, int>{};

    for (final doc in allAnsSnap.docs) {
      final data = doc.data();
      // sadece numeric totalScore varsa ortalamaya dahil edelim
      final ts = data['totalScore'];
      if (ts is num) totalScoreSum += ts;

      final answers = (data['answers'] ?? []) as List<dynamic>;
      for (final a in answers) {
        final qid = a['questionId'];
        if (qid == null) continue;

        final q = questions[qid];
        if (q == null) continue;

        final type = (q['type'] ?? '').toString();
        final correct = q['answer']; // essay'de yok
        final studentAns = a['answer'];

        if (type == 'essay') {
          // Minimal: essay'i doğruluk/yanlış konu istatistiklerinden çıkarıyoruz
          continue;
        }

        if (correct != null && studentAns != null && studentAns == correct) {
          correctCountPerQuestion[qid] =
              (correctCountPerQuestion[qid] ?? 0) + 1;
        } else {
          final topic = (q['topic'] ?? 'Bilinmiyor').toString();
          topicWrongCount[topic] = (topicWrongCount[topic] ?? 0) + 1;
        }
      }
    }

    final classAverage = (totalStudents > 0)
        ? (totalScoreSum / totalStudents)
        : 0;

    // Maksimum puanı da vermek iyi olur (sum of question scores)
    num maxTotalScore = 0;
    questions.forEach((_, q) => maxTotalScore += (q['score'] as num? ?? 0));

    return {
      'totalStudents': totalStudents,
      'classAverage': classAverage,
      'maxTotalScore': maxTotalScore,
      'correctCountPerQuestion':
          correctCountPerQuestion, // {questionId: correctCount}
      'topicWrongCount': topicWrongCount, // {topic: wrongCount}
      'questions': questions, // UI için gerekli metinler
    };
  }

  /// ÖĞRENCİ bazlı istatistikler: öğrencinin puanı, yanlış konu dağılımı, soru bazlı performans
  Future<Map<String, dynamic>> getExamStatsForStudent(
    String examId,
    String studentId,
  ) async {
    final questions = await _fetchQuestions(examId);
    final ansDoc = await _db
        .collection('studentExamAnswers')
        .doc('${examId}_$studentId')
        .get();
    final answerData = ansDoc.data() ?? {};
    final answers = (answerData['answers'] ?? []) as List<dynamic>;

    // Öğrencinin toplam puanı: varsa totalScore kullan, yoksa hesapla
    num studentScore = (answerData['totalScore'] is num)
        ? answerData['totalScore'] as num
        : 0;

    if (!(answerData['totalScore'] is num)) {
      // totalScore yoksa non-essay için correct==answer ile, essay için earnedScore varsa ondan hesapla
      for (final a in answers) {
        final q = questions[a['questionId']];
        if (q == null) continue;
        final type = (q['type'] ?? '').toString();
        final score = (q['score'] is num) ? q['score'] as num : 0;

        if (type == 'essay') {
          final es = a['earnedScore'];
          if (es is num) studentScore += es;
        } else {
          final correct = q['answer'];
          if (a['answer'] != null &&
              correct != null &&
              a['answer'] == correct) {
            studentScore += score;
          }
        }
      }
    }

    // Yanlış konu dağılımı (non-essay)
    final studentWrongTopics = <String, int>{};

    // Soru bazlı performans listesi (UI için)
    final perQuestion = <Map<String, dynamic>>[];

    for (final a in answers) {
      final qid = a['questionId'];
      final q = questions[qid];
      if (q == null) continue;

      final type = (q['type'] ?? '').toString();
      final correct = q['answer'];
      final studentAns = a['answer'];
      final score = (q['score'] is num) ? q['score'] as num : 0;

      // earnedScore öğrenci item'ında olabilir
      num earnedScore = (a['earnedScore'] is num)
          ? a['earnedScore'] as num
          : -1;
      if (earnedScore < 0) {
        if (type == 'essay') {
          earnedScore = 0; // manuel girilmemişse 0
        } else if (correct != null &&
            studentAns != null &&
            studentAns == correct) {
          earnedScore = score;
        } else {
          earnedScore = 0;
        }
      }

      if (type != 'essay') {
        if (!(studentAns != null && correct != null && studentAns == correct)) {
          final topic = (q['topic'] ?? 'Bilinmiyor').toString();
          studentWrongTopics[topic] = (studentWrongTopics[topic] ?? 0) + 1;
        }
      }

      perQuestion.add({
        'questionId': qid,
        'questionText': q['questionText'] ?? '',
        'topic': q['topic'] ?? '',
        'score': score,
        'studentAnswer': studentAns,
        'correctAnswer': correct,
        'type': type,
        'earnedScore': earnedScore,
      });
    }

    // maxTotalScore
    num maxTotalScore = 0;
    questions.forEach((_, q) => maxTotalScore += (q['score'] as num? ?? 0));

    return {
      'studentScore': studentScore,
      'maxTotalScore': maxTotalScore,
      'studentWrongTopics': studentWrongTopics,
      'perQuestion': perQuestion, // liste
      'questions': questions, // UI için de lazım olabilir
    };
  }
}
