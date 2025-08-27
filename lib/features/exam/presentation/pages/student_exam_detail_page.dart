import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/data/evaluate_student_exams.dart';
import 'package:mobile_exam/features/exam/domain/entities/question.dart';

class StudentExamDetailPage extends StatefulWidget {
  final String examId;
  final String studentId;

  const StudentExamDetailPage({
    super.key,
    required this.examId,
    required this.studentId,
  });

  @override
  State<StudentExamDetailPage> createState() => _StudentExamDetailPageState();
}

class _StudentExamDetailPageState extends State<StudentExamDetailPage> {
  bool isLoading = true;
  bool isAllowedToTakeExam = false;
  bool isSubmitting = false;

  List<Question> questions = [];
  final Map<String, dynamic> answers = {};
  final Map<String, TextEditingController> _essayControllers = {};

  DateTime? startTime;
  int durationMinutes = 60;
  DateTime? _endTime;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExamData() async {
    // 1) Sınav bilgisi
    final examDoc = await FirebaseFirestore.instance
        .collection("exams")
        .doc(widget.examId)
        .get();

    if (!examDoc.exists) {
      setState(() {
        isAllowedToTakeExam = false;
        isLoading = false;
      });
      return;
    }

    final data = examDoc.data()!;
    final published = data["isPublished"] == true;

    startTime = DateTime.parse(data["startTime"]);
    durationMinutes = data["durationMinutes"];
    _endTime = startTime!.add(Duration(minutes: durationMinutes));

    final now = DateTime.now();

    // 2) Öğrenci daha önce bu sınavı gönderdi mi?
    final answerDoc = await FirebaseFirestore.instance
        .collection("studentExamAnswers")
        .doc("${widget.examId}_${widget.studentId}")
        .get();

    if (answerDoc.exists) {
      setState(() {
        isAllowedToTakeExam = false;
        isLoading = false;
      });
      return;
    }

    // 3) Zaman + yayın kontrolü
    final allowedByTime = now.isAfter(startTime!) && now.isBefore(_endTime!);
    isAllowedToTakeExam = published && allowedByTime;

    if (!isAllowedToTakeExam) {
      setState(() => isLoading = false);
      return;
    }

    // 4) Soruları yükle
    final questionsSnap = await FirebaseFirestore.instance
        .collection("exams")
        .doc(widget.examId)
        .collection("questions")
        .get();

    questions = questionsSnap.docs.map((doc) {
      return Question.fromMap(doc.data(), doc.id);
    }).toList();

    for (final q in questions.where((q) => q.type == QuestionType.essay)) {
      _essayControllers[q.id] = TextEditingController();
    }

    // 5) Geri sayım
    _startTicker();
    setState(() => isLoading = false);
  }

  void _startTicker() {
    if (_endTime == null) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final now = DateTime.now();
      final remaining = _endTime!.difference(now);
      if (mounted) {
        setState(() {
          _remaining = remaining.isNegative ? Duration.zero : remaining;
        });
      }
      if (remaining.isNegative || remaining.inSeconds == 0) {
        _ticker?.cancel();
        if (mounted && !isSubmitting) {
          await _submitAnswers(auto: true);
        }
      }
    });
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _submitAnswers({bool auto = false}) async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    // Non-essay sorular boş mu? (auto submit'te zorlamıyoruz)
    if (!auto) {
      final missing = questions.any((q) {
        if (q.type == QuestionType.essay) return false;
        final v = answers[q.id];
        return v == null || (v is String && v.isEmpty);
      });
      if (missing) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lütfen tüm zorunlu soruları cevaplayın."),
            ),
          );
        }
        setState(() => isSubmitting = false);
        return;
      }
    }

    final answerList = questions.map((q) {
      return {"questionId": q.id, "answer": answers[q.id], "type": q.type.name};
    }).toList();

    final docRef = FirebaseFirestore.instance
        .collection("studentExamAnswers")
        .doc("${widget.examId}_${widget.studentId}");

    await docRef.set({
      "examId": widget.examId,
      "studentId": widget.studentId,
      "submittedAt": FieldValue.serverTimestamp(),
      "answers": answerList,
      "totalScore": null,
      "status": "submitted",
    }, SetOptions(merge: true));

    await evaluateStudentExam(widget.examId, widget.studentId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auto
              ? "Süre doldu, cevaplarınız gönderildi."
              : "Cevaplarınız gönderildi ve puanlandı.",
        ),
      ),
    );

    Navigator.pop(context);
    setState(() => isSubmitting = false);
  }

  Widget _buildQuestionCard(Question q) {
    final image = (q.imageUrl != null && q.imageUrl!.trim().isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.network(q.imageUrl!),
          )
        : const SizedBox.shrink();

    if (q.type == QuestionType.essay) {
      final controller = _essayControllers[q.id]!;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Konu: ${q.topic}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(q.questionText),
              image,
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Cevabınızı yazınız...",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => answers[q.id] = val,
              ),
            ],
          ),
        ),
      );
    }

    if (q.type == QuestionType.multipleChoice) {
      final choices = q.choices ?? const <String>[];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Konu: ${q.topic}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(q.questionText),
              image,
              const SizedBox(height: 12),
              if (choices.isEmpty)
                const Text(
                  "Bu soru için seçenek bulunamadı.",
                  style: TextStyle(color: Colors.red),
                )
              else
                Column(
                  children: List.generate(choices.length, (i) {
                    final label = String.fromCharCode(65 + i);
                    return RadioListTile<String>(
                      title: Text("$label. ${choices[i]}"),
                      value: label,
                      groupValue: answers[q.id] as String?,
                      onChanged: (val) => setState(() => answers[q.id] = val),
                    );
                  }),
                ),
            ],
          ),
        ),
      );
    }

    // True/False
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Konu: ${q.topic}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(q.questionText),
            image,
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text("Doğru"),
              value: "D",
              groupValue: answers[q.id] as String?,
              onChanged: (val) => setState(() => answers[q.id] = val),
            ),
            RadioListTile<String>(
              title: const Text("Yanlış"),
              value: "Y",
              groupValue: answers[q.id] as String?,
              onChanged: (val) => setState(() => answers[q.id] = val),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!isAllowedToTakeExam) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sınav")),
        body: const Center(
          child: Text(
            "Bu sınav şu anda erişilebilir değil veya zaten tamamladınız.",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınavı Cevapla"),
        actions: [
          if (_endTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text("Süre: ${_formatRemaining(_remaining)}"),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (_, i) => _buildQuestionCard(questions[i]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: isSubmitting
                  ? const Icon(Icons.hourglass_top)
                  : const Icon(Icons.send),
              label: Text(
                isSubmitting ? "Gönderiliyor..." : "Cevapları Gönder",
              ),
              onPressed: isSubmitting ? null : () => _submitAnswers(),
            ),
          ],
        ),
      ),
    );
  }
}
