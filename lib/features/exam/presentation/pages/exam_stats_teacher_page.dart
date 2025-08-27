import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/data/exam_stats_service.dart';
import 'package:mobile_exam/features/exam/presentation/pages/student_exam_result_page.dart';
import 'package:mobile_exam/features/exam/presentation/components/stats/topic_pie.dart';
import 'package:mobile_exam/features/exam/presentation/components/stats/question_accuracy_bar.dart';

class ExamStatsTeacherPage extends StatefulWidget {
  final String examId;
  const ExamStatsTeacherPage({super.key, required this.examId});

  @override
  State<ExamStatsTeacherPage> createState() => _ExamStatsTeacherPageState();
}

class _ExamStatsTeacherPageState extends State<ExamStatsTeacherPage> {
  final _service = ExamStatsService();
  late Future<_CombinedTeacher> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CombinedTeacher> _load() async {
    // 1) Genel istatistikler
    final overall = await _service.getExamStatsOverall(widget.examId);

    // 2) Öğrenci cevapları (puan listesi)
    final ansSnap = await FirebaseFirestore.instance
        .collection('studentExamAnswers')
        .where('examId', isEqualTo: widget.examId)
        .get();

    final studentsRaw = <Map<String, dynamic>>[];
    final ids = <String>[];
    for (final d in ansSnap.docs) {
      final data = d.data();
      final sid = (data['studentId'] ?? '') as String? ?? '';
      if (sid.isEmpty) continue;
      ids.add(sid);
      studentsRaw.add({
        'studentId': sid,
        'totalScore': (data['totalScore'] is num)
            ? data['totalScore'] as num
            : null,
        'status': (data['status'] ?? '').toString(),
      });
    }

    // 3) İsimleri çek (users koleksiyonundan). whereIn limit 10 olduğu için parça parça.
    final Map<String, String> nameMap = {};
    const chunk = 10;
    for (var i = 0; i < ids.length; i += chunk) {
      final sub = ids.sublist(
        i,
        i + chunk > ids.length ? ids.length : i + chunk,
      );
      if (sub.isEmpty) continue;
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', whereIn: sub)
          .get();
      for (final u in usersSnap.docs) {
        final ud = u.data();
        final uid = (ud['uid'] ?? '') as String? ?? '';
        final name = (ud['name'] ?? ud['email'] ?? uid).toString();
        if (uid.isNotEmpty) nameMap[uid] = name;
      }
    }

    // 4) Öğrencileri tek listeye hazırla (isim, puan, durum)
    final students = studentsRaw.map((e) {
      final sid = e['studentId'] as String;
      return {
        'studentId': sid,
        'name': nameMap[sid] ?? sid,
        'totalScore': e['totalScore'],
        'status': e['status'],
      };
    }).toList();

    // Skora göre azalan sırala (null'lar en sona)
    students.sort((a, b) {
      final an = a['totalScore'];
      final bn = b['totalScore'];
      if (an == null && bn == null) return 0;
      if (an == null) return 1;
      if (bn == null) return -1;
      return (bn as num).compareTo(an as num);
    });

    return _CombinedTeacher(overall: overall, students: students);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav İstatistikleri (Öğretmen)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _load()),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: FutureBuilder<_CombinedTeacher>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('İstatistikler yüklenemedi.'));
          }

          final overall = snap.data!.overall;
          final students = snap.data!.students;

          final totalStudents = (overall['totalStudents'] as int?) ?? 0;
          final classAverage = (overall['classAverage'] as num? ?? 0)
              .toDouble();
          final maxTotalScore = (overall['maxTotalScore'] as num? ?? 0)
              .toDouble();

          final topicWrongCount =
              (overall['topicWrongCount'] as Map<String, int>? ?? {});
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
                  classAverage: classAverage,
                  maxTotalScore: maxTotalScore,
                  totalStudents: totalStudents,
                ),
                const SizedBox(height: 16),

                // Konu bazlı yanlış dağılımı (sınıf)
                _sectionTitle('Konu Bazlı Yanlış Dağılımı (Sınıf)'),
                if (topicWrongCount.isEmpty) const Text('Veri yok.'),
                if (topicWrongCount.isNotEmpty) ...[
                  TopicPie(data: topicWrongCount),
                ],

                const SizedBox(height: 16),

                // Soru bazlı doğruluk yüzdesi (sınıf)
                _sectionTitle('Soru Doğruluk Yüzdesi (Sınıf)'),
                QuestionAccuracyBar(
                  questions: questions,
                  correctCountPerQuestion: correctCountPerQuestion,
                  totalStudents: totalStudents,
                ),
                const SizedBox(height: 16),

                // Öğrenci listesi (puan + durum)
                _sectionTitle('Öğrenciler'),
                if (students.isEmpty)
                  const Text('Bu sınava öğrenci katılımı bulunmuyor.'),
                if (students.isNotEmpty)
                  ...students.map((s) {
                    final name = s['name']?.toString() ?? '-';
                    final sid = s['studentId']?.toString() ?? '';
                    final status = s['status']?.toString() ?? '';
                    final scoreNum = s['totalScore'];
                    final score = (scoreNum is num)
                        ? scoreNum.toStringAsFixed(0)
                        : '-';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text('Durum: $status'),
                        trailing: Text(
                          score,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: sid.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentExamResultPage(
                                      examId: widget.examId,
                                      studentId: sid,
                                    ),
                                  ),
                                );
                              },
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
    required double classAverage,
    required double maxTotalScore,
    required int totalStudents,
  }) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard('Sınıf Ortalaması', classAverage.toStringAsFixed(1)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiCard('Maks. Puan', maxTotalScore.toStringAsFixed(0)),
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

  List<MapEntry<String, int>> _sortedTopicEntries(Map<String, int> m) {
    final list = m.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value)); // çokdan aza
    return list;
  }
}

class _CombinedTeacher {
  final Map<String, dynamic> overall;
  final List<Map<String, dynamic>> students;
  _CombinedTeacher({required this.overall, required this.students});
}
