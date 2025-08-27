import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/presentation/pages/exam_stats_student_page.dart';

class StudentExamResultPage extends StatelessWidget {
  final String examId;
  final String studentId;

  const StudentExamResultPage({
    super.key,
    required this.examId,
    required this.studentId,
  });

  Future<_ResultData> _load() async {
    final examRef = FirebaseFirestore.instance.collection('exams').doc(examId);
    final ansRef = FirebaseFirestore.instance
        .collection('studentExamAnswers')
        .doc('${examId}_$studentId');
    final qsRef = examRef.collection('questions');

    final examSnap = await examRef.get();
    final ansSnap = await ansRef.get();
    final qsSnap = await qsRef.get();

    final exam = examSnap.data() ?? {};
    final ans = ansSnap.data() ?? {};
    final questions = {for (final d in qsSnap.docs) d.id: d.data()};

    return _ResultData(exam: exam, ans: ans, questions: questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Sonucu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'İstatistikleri Gör',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExamStatsStudentPage(
                    examId: examId,
                    studentId: studentId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_ResultData>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('Sonuçlar yüklenemedi.'));
          }

          final exam = snap.data!.exam;
          final ans = snap.data!.ans;
          final questions = snap.data!.questions;

          final published = (exam['answersPublished'] ?? false) == true;
          final status = (ans['status'] ?? '') as String;

          // null-safe numeric reads
          final totalRaw = ans['totalScore'];
          final bool hasTotal = totalRaw is num;
          final num total = hasTotal ? totalRaw as num : 0;

          final autoRaw = ans['autoScore'];
          final num autoScore = autoRaw is num ? autoRaw as num : 0;

          final manualRaw = ans['manualScore'];
          final num manualScore = manualRaw is num ? manualRaw as num : 0;

          final answers = (ans['answers'] ?? []) as List<dynamic>;

          final canShow = published && hasTotal && status == 'released';
          if (!canShow) {
            return const Center(
              child: Text('Sonuçlarınız henüz yayınlanmadı.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ScoreHeader(
                  total: total,
                  autoScore: autoScore,
                  manualScore: manualScore,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: answers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final a = answers[i] as Map<String, dynamic>;
                      final qid = (a['questionId'] ?? '') as String;
                      final studentAnswer = (a['answer'] ?? '').toString();
                      final type = (a['type'] ?? '').toString();

                      final q = questions[qid] ?? {};
                      final qText = (q['questionText'] ?? '') as String;
                      final correct = (q['answer'] ?? '')?.toString();

                      final rawChoices = q['choices'];
                      final List<String> choices = (rawChoices is List)
                          ? rawChoices.map((e) => e.toString()).toList()
                          : const <String>[];

                      final scoreRaw = q['score'];
                      final num totalScore = scoreRaw is num
                          ? scoreRaw as num
                          : 0;

                      // earnedScore null-safe: varsa kullan; yoksa MCQ/TF için hesapla; essay için 0
                      final esRaw = a['earnedScore'];
                      num earnedScore;
                      if (esRaw is num) {
                        earnedScore = esRaw;
                      } else {
                        if (type == 'essay') {
                          earnedScore = 0;
                        } else if ((correct ?? '').isNotEmpty &&
                            studentAnswer == correct) {
                          earnedScore = totalScore;
                        } else {
                          earnedScore = 0;
                        }
                      }

                      // True/False için görsel şık listesi
                      final displayChoices = choices.isNotEmpty
                          ? choices
                          : (type == 'trueFalse'
                                ? <String>['Doğru', 'Yanlış'] // sadece görsel
                                : const <String>[]);

                      // Doğru şık label'ı (MCQ A-E, TF D/Y)
                      String? correctLabel;
                      if (choices.isNotEmpty) {
                        correctLabel = correct; // "A".."E"
                      } else if (type == 'trueFalse' &&
                          (correct ?? '').isNotEmpty) {
                        correctLabel = correct; // "D" ya da "Y"
                      }

                      return _QuestionCard(
                        index: i + 1,
                        questionText: qText,
                        studentAnswer: studentAnswer,
                        correctAnswer: (correctLabel?.isEmpty ?? true)
                            ? null
                            : correctLabel,
                        choices: displayChoices,
                        isTrueFalse: type == 'trueFalse' && choices.isEmpty,
                        totalScore: totalScore,
                        earnedScore: earnedScore,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* -------------------- İç Modeller / Widget'lar -------------------- */

class _ResultData {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> ans;
  final Map<String, Map<String, dynamic>> questions;
  _ResultData({required this.exam, required this.ans, required this.questions});
}

class _ScoreHeader extends StatelessWidget {
  final num total;
  final num autoScore;
  final num manualScore;
  const _ScoreHeader({
    super.key,
    required this.total,
    required this.autoScore,
    required this.manualScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(.1),
              ),
              child: Icon(
                Icons.score,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Puan',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Otomatik: $autoScore  •  Manuel: $manualScore',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final String questionText;
  final String studentAnswer;
  final String? correctAnswer; // "A"-"E" veya "D"/"Y" ya da null (essay)
  final List<String>
  choices; // MCQ için A-E; TF için "Doğru","Yanlış"; essay boş
  final bool isTrueFalse;
  final num totalScore; // sorunun toplam puanı
  final num earnedScore; // öğrencinin aldığı puan

  const _QuestionCard({
    super.key,
    required this.index,
    required this.questionText,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.choices,
    required this.isTrueFalse,
    required this.totalScore,
    required this.earnedScore,
  });

  String _shorten(String s) => s.length > 140 ? '${s.substring(0, 140)}…' : s;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık: Soru No + Metin + Puan bilgisi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(.1),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shorten(questionText),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Puan: $earnedScore / $totalScore',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Öğrencinin cevabı
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Öğrencinin cevabı: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(studentAnswer.isEmpty ? '-' : studentAnswer),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tüm şıklar (varsa) — doğru şık yeşil arka plan
            if (choices.isNotEmpty) ...[
              const Text('Seçenekler:'),
              const SizedBox(height: 6),
              Column(
                children: List.generate(choices.length, (i) {
                  String label;
                  if (isTrueFalse) {
                    // D/Y etiketleri
                    label = i == 0 ? 'D' : 'Y';
                  } else {
                    label = String.fromCharCode(65 + i); // A,B,C...
                  }

                  final isCorrect =
                      (correctAnswer != null && correctAnswer == label);
                  final isSelected = (studentAnswer == label);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withOpacity(.12)
                          : Colors.grey.withOpacity(.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.withOpacity(.5)
                            : Colors.grey.withOpacity(.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isSelected ? '• $label' : label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(choices[i])),
                      ],
                    ),
                  );
                }),
              ),
            ],

            // Doğru cevap (varsa)
            if (correctAnswer != null && correctAnswer!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doğru cevap: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(.5)),
                    ),
                    child: Text(
                      correctAnswer!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
