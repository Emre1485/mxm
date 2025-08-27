import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentManualGradePage extends StatefulWidget {
  final String examId;
  final String studentId;

  const StudentManualGradePage({
    super.key,
    required this.examId,
    required this.studentId,
  });

  @override
  State<StudentManualGradePage> createState() => _StudentManualGradePageState();
}

class _StudentManualGradePageState extends State<StudentManualGradePage> {
  bool loading = true;
  bool saving = false;

  /// Essay soruların listesi:
  /// {questionId, questionText, maxScore, studentAnswer, earnedScore}
  List<Map<String, dynamic>> essayItems = [];

  /// questionId -> controller (girilen puan)
  final Map<String, TextEditingController> _scoreCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // 1) Öğrenci cevaplarını çek
      final ansDoc = await FirebaseFirestore.instance
          .collection('studentExamAnswers')
          .doc("${widget.examId}_${widget.studentId}")
          .get();

      if (!ansDoc.exists) {
        setState(() {
          essayItems = [];
          loading = false;
        });
        return;
      }

      final ansData = ansDoc.data() ?? {};
      final List<dynamic> answers = List<dynamic>.from(
        ansData['answers'] ?? [],
      );

      // 2) Essay olanları sorularla birleştir
      final List<Map<String, dynamic>> essays = [];
      for (final a in answers) {
        final map = Map<String, dynamic>.from(a as Map);
        if ((map['type'] ?? '') != 'essay') continue;

        final qid = map['questionId'] as String? ?? '';
        if (qid.isEmpty) continue;

        final qDoc = await FirebaseFirestore.instance
            .collection('exams')
            .doc(widget.examId)
            .collection('questions')
            .doc(qid)
            .get();

        if (!qDoc.exists) continue;

        final q = qDoc.data() ?? {};
        final maxScore = (q['score'] is num) ? q['score'] as num : 0;
        final earned = (map['earnedScore'] is num)
            ? map['earnedScore'] as num
            : null;

        essays.add({
          'questionId': qid,
          'questionText': (q['questionText'] ?? '') as String,
          'maxScore': maxScore,
          'studentAnswer': (map['answer'] ?? '') as String,
          'earnedScore': earned, // önceki varsa doldur
        });
      }

      // 3) Controller'ları hazırla
      for (final e in essays) {
        final qid = e['questionId'] as String;
        final init = e['earnedScore'];
        _scoreCtrls[qid] = TextEditingController(
          text: (init is num) ? init.toString() : '',
        );
      }

      setState(() {
        essayItems = essays;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yükleme hatası: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection('studentExamAnswers')
          .doc("${widget.examId}_${widget.studentId}");

      // güncel answers çek
      final snap = await ref.get();
      if (!snap.exists) {
        setState(() => saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Öğrenci cevabı bulunamadı.')),
          );
        }
        return;
      }

      final data = snap.data() ?? {};
      final List<dynamic> answers = List<dynamic>.from(data['answers'] ?? []);

      num manualTotal = 0;

      // Essay item'larına earnedScore yaz
      for (var i = 0; i < answers.length; i++) {
        final item = Map<String, dynamic>.from(answers[i] as Map);

        if ((item['type'] ?? '') == 'essay') {
          final qid = (item['questionId'] ?? '') as String;
          if (qid.isEmpty) continue;

          final ctrl = _scoreCtrls[qid];
          final raw = ctrl?.text.trim() ?? '';
          num val = num.tryParse(raw) ?? 0;

          // Max skor sınırı
          final maxEntry = essayItems.firstWhere(
            (e) => e['questionId'] == qid,
            orElse: () => {},
          );
          final maxScore = (maxEntry['maxScore'] is num)
              ? maxEntry['maxScore'] as num
              : 0;

          if (val < 0) val = 0;
          if (val > maxScore) val = maxScore;

          item['earnedScore'] = val;
          answers[i] = item;

          manualTotal += val;
        }
      }

      // autoScore + manualScore -> totalScore
      final auto = (data['autoScore'] is num) ? data['autoScore'] as num : 0;

      await ref.update({
        'answers': answers,
        'manualScore': manualTotal,
        'totalScore': auto + manualTotal,
        'status': 'graded', // Artık manuel puanlar girildi
        'evaluatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Puanlar kaydedildi.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kaydetme hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Essay Puanlama — ${widget.studentId}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: essayItems.isEmpty
            ? const Center(child: Text('Essay sorusu bulunamadı.'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: essayItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = essayItems[i];
                        final qid = e['questionId'] as String;
                        final qText = (e['questionText'] ?? '') as String;
                        final maxScore = (e['maxScore'] is num)
                            ? e['maxScore'] as num
                            : 0;
                        final studentAns = (e['studentAnswer'] ?? '') as String;
                        final ctrl = _scoreCtrls[qid]!;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soru ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(qText),
                                const SizedBox(height: 8),
                                Text(
                                  'Öğrenci cevabı:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                Text(studentAns.isEmpty ? '-' : studentAns),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Bu soru için verilen puan',
                                          hintText: 'örn. 8',
                                          border: const OutlineInputBorder(),
                                          suffixText: '/ $maxScore',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Tooltip(
                                      message: 'Maksimum puan: $maxScore',
                                      child: Chip(
                                        label: Text('Max: $maxScore'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const Icon(Icons.hourglass_top)
                          : const Icon(Icons.save),
                      label: Text(
                        saving ? 'Kaydediliyor...' : 'Puanları Kaydet',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
