import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_exam/features/exam/domain/entities/exam.dart';
import 'package:mobile_exam/features/exam/domain/entities/question.dart';
import 'package:mobile_exam/features/exam/presentation/pages/exam_submissions_page.dart';
import 'package:mobile_exam/features/exam/data/re_evaluate_all.dart';
import 'package:mobile_exam/features/exam/presentation/pages/exam_stats_teacher_page.dart';

class ExamDetailPage extends StatelessWidget {
  final Exam exam;

  const ExamDetailPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final questionsRef = FirebaseFirestore.instance
        .collection('exams')
        .doc(exam.id)
        .collection('questions');

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.name),
        actions: [
          // 1) Birincil eylem: Sonuçları yayınla (ikon + tooltip)
          IconButton(
            icon: const Icon(Icons.publish),
            tooltip: 'Sonuçları yayınla',
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('exams')
                  .doc(exam.id)
                  .update({
                    'answersPublished': true,
                    'releasedAt': FieldValue.serverTimestamp(),
                  });

              final ans = await FirebaseFirestore.instance
                  .collection('studentExamAnswers')
                  .where('examId', isEqualTo: exam.id)
                  .get();

              for (final d in ans.docs) {
                final st = (d.data()['status'] ?? '') as String;
                if (st == 'graded' || st == 'auto_scored') {
                  await d.reference.update({'status': 'released'});
                }
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sonuçlar yayınlandı.")),
                );
              }
            },
          ),

          // 2) Diğerleri menüye: Cevapları Değerlendir & İstatistikler
          PopupMenuButton<String>(
            tooltip: 'Diğer',
            onSelected: (value) {
              if (value == 'review') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamSubmissionsPage(examId: exam.id),
                  ),
                );
              } else if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamStatsTeacherPage(examId: exam.id),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'review',
                child: ListTile(
                  leading: Icon(Icons.rate_review),
                  title: Text('Cevapları değerlendir'),
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.pie_chart),
                  title: Text('İstatistikler'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Açıklama: ${exam.description}'),
            const SizedBox(height: 8),
            Text('Süre: ${exam.durationMinutes} dakika'),
            const SizedBox(height: 8),
            Text('Başlangıç: ${exam.startTime}'),
            const SizedBox(height: 8),
            Text('Yayın Durumu: ${exam.isPublished ? 'Yayınlandı' : 'Taslak'}'),
            const Divider(height: 32),
            const Text(
              'Sorular:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: questionsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("Henüz soru eklenmemiş.");
                  }

                  final questions = snapshot.data!.docs.map((doc) {
                    return Question.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();

                  return ListView.separated(
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return ListTile(
                        title: Text(q.questionText),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Konu: ${q.topic}  •  Puan: ${q.score}"),
                            if (q.answer != null && q.answer!.isNotEmpty)
                              Text(
                                "Doğru Cevap: ${q.answer}",
                                style: const TextStyle(color: Colors.green),
                              ),
                            if (q.answer == null || q.answer!.isEmpty)
                              const Text(
                                "Doğru cevap tanımlı değil!",
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        trailing: (q.type == QuestionType.essay)
                            ? const SizedBox.shrink()
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Doğru cevabı düzelt',
                                onPressed: () async {
                                  await _showFixAnswerDialog(
                                    context,
                                    exam.id,
                                    q,
                                  );
                                },
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFixAnswerDialog(
    BuildContext context,
    String examId,
    Question q,
  ) async {
    String? selected;

    await showDialog(
      context: context,
      builder: (_) {
        if (q.type == QuestionType.multipleChoice) {
          final n = (q.choices ?? []).length;
          final labels = List.generate(n, (i) => String.fromCharCode(65 + i));
          selected = q.answer ?? (labels.isNotEmpty ? labels.first : null);

          return AlertDialog(
            title: const Text('Doğru cevabı seç'),
            content: DropdownButtonFormField<String>(
              value: selected,
              items: labels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => selected = v,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selected == null) return;
                  await FirebaseFirestore.instance
                      .collection('exams')
                      .doc(examId)
                      .collection('questions')
                      .doc(q.id)
                      .update({'answer': selected});

                  if (context.mounted) Navigator.pop(context);

                  await reEvaluateAllSubmissions(examId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Doğru cevap güncellendi ve sonuçlar yeniden hesaplandı.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        }

        if (q.type == QuestionType.trueFalse) {
          selected = q.answer ?? 'D';
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Doğru cevabı seç'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Doğru (D)'),
                    value: 'D',
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  RadioListTile<String>(
                    title: const Text('Yanlış (Y)'),
                    value: 'Y',
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selected == null) return;
                    await FirebaseFirestore.instance
                        .collection('exams')
                        .doc(examId)
                        .collection('questions')
                        .doc(q.id)
                        .update({'answer': selected});

                    if (context.mounted) Navigator.pop(context);

                    await reEvaluateAllSubmissions(examId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Doğru cevap güncellendi ve sonuçlar yeniden hesaplandı.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          );
        }

        return const AlertDialog(
          content: Text('Essay sorularda doğru cevap tanımlanmaz.'),
        );
      },
    );
  }
}
