import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/data/exam_stats_service.dart';
import 'package:mobile_exam/features/exam/presentation/components/stats/topic_pie.dart';
import 'package:mobile_exam/features/exam/presentation/components/stats/question_accuracy_bar.dart';

class ExamStatsStudentPage extends StatefulWidget {
  final String examId;
  final String studentId;

  const ExamStatsStudentPage({
    super.key,
    required this.examId,
    required this.studentId,
  });

  @override
  State<ExamStatsStudentPage> createState() => _ExamStatsStudentPageState();
}

class _ExamStatsStudentPageState extends State<ExamStatsStudentPage> {
  final _service = ExamStatsService();
  late Future<_Combined> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Combined> _load() async {
    final overall = await _service.getExamStatsOverall(widget.examId);
    final mine = await _service.getExamStatsForStudent(
      widget.examId,
      widget.studentId,
    );
    return _Combined(overall: overall, mine: mine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav İstatistikleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _load()),
          ),
        ],
      ),
      body: FutureBuilder<_Combined>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('İstatistikler yüklenemedi.'));
          }

          final overall = snap.data!.overall;
          final mine = snap.data!.mine;

          final totalStudents = overall['totalStudents'] as int? ?? 0;
          final classAverage = (overall['classAverage'] as num? ?? 0)
              .toDouble();
          final maxTotalScore = (overall['maxTotalScore'] as num? ?? 0)
              .toDouble();

          final studentScore = (mine['studentScore'] as num? ?? 0).toDouble();
          final studentWrongTopics =
              (mine['studentWrongTopics'] as Map<String, int>? ?? {});
          final perQuestion = (mine['perQuestion'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

          final correctCountPerQuestion =
              (overall['correctCountPerQuestion'] as Map<String, int>? ?? {});
          final questions =
              (overall['questions'] as Map<String, dynamic>? ?? {}).map(
                (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
              );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _kpis(
                  studentScore: studentScore,
                  classAverage: classAverage,
                  maxTotalScore: maxTotalScore,
                  totalStudents: totalStudents,
                ),
                const SizedBox(height: 16),

                // Yanlış yapılan konular (öğrenci)
                _sectionTitle('Yanlış Yaptığın Konular'),
                if (studentWrongTopics.isEmpty)
                  const Text('Harika! Yanlış yaptığın konu yok.'),
                if (studentWrongTopics.isNotEmpty) ...[
                  TopicPie(data: studentWrongTopics),
                ],

                const SizedBox(height: 16),

                // Soru bazlı doğruluk (genel)
                _sectionTitle('Soru Doğruluk Oranı (Sınıf)'),
                QuestionAccuracyBar(
                  questions: questions,
                  correctCountPerQuestion: correctCountPerQuestion,
                  totalStudents: totalStudents,
                ),

                const SizedBox(height: 16),

                // Öğrenci soru bazlı performansı
                _sectionTitle('Soru Bazlı Performansın'),
                if (perQuestion.isEmpty) const Text('Cevap verisi bulunamadı.'),
                if (perQuestion.isNotEmpty)
                  ...perQuestion.asMap().entries.map((e) {
                    final idx = e.key + 1;
                    final item = e.value;
                    final qText = (item['questionText'] ?? '').toString();
                    final studentAns = (item['studentAnswer'] ?? '-')
                        .toString();
                    final correctAns = (item['correctAnswer'])?.toString();
                    final score = (item['score'] as num? ?? 0).toDouble();
                    final earned = (item['earnedScore'] as num? ?? 0)
                        .toDouble();

                    final isCorrect =
                        (correctAns != null &&
                        correctAns.isNotEmpty &&
                        studentAns == correctAns);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(.1),
                          child: Text(
                            '$idx',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(_shorten(qText)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  'Senin cevabın: ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Expanded(child: Text(studentAns)),
                              ],
                            ),
                            if (correctAns != null && correctAns.isNotEmpty)
                              Row(
                                children: [
                                  const Text(
                                    'Doğru cevap: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(.4),
                                      ),
                                    ),
                                    child: Text(
                                      correctAns,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'Puan: $earned / $score',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: (correctAns == null || correctAns.isEmpty)
                            ? const Icon(
                                Icons.help_outline,
                                color: Colors.orange,
                              )
                            : (isCorrect
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : const Icon(
                                      Icons.cancel,
                                      color: Colors.redAccent,
                                    )),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpis({
    required double studentScore,
    required double classAverage,
    required double maxTotalScore,
    required int totalStudents,
  }) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            'Puanın',
            '${studentScore.toStringAsFixed(0)} / ${maxTotalScore.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiCard('Sınıf Ortalaması', classAverage.toStringAsFixed(1)),
        ),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard('Katılımcı', '$totalStudents')),
      ],
    );
  }

  Widget _kpiCard(String title, String value) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  String _shorten(String s) => s.length > 120 ? '${s.substring(0, 120)}…' : s;
}

class _Combined {
  final Map<String, dynamic> overall;
  final Map<String, dynamic> mine;
  _Combined({required this.overall, required this.mine});
}
