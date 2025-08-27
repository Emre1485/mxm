import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/presentation/pages/student_exam_result_page.dart';
import 'package:mobile_exam/features/exam/presentation/pages/exam_stats_student_page.dart';

class ParentStudentDashboardPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const ParentStudentDashboardPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final coursesQuery = FirebaseFirestore.instance
        .collection('courses')
        .where('studentIds', arrayContains: studentId);

    return Scaffold(
      appBar: AppBar(title: Text('$studentName • Dersler')),
      body: StreamBuilder<QuerySnapshot>(
        stream: coursesQuery.snapshots(),
        builder: (context, courseSnap) {
          if (courseSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!courseSnap.hasData || courseSnap.data!.docs.isEmpty) {
            return const Center(
              child: Text('Bu öğrenci için ders bulunamadı.'),
            );
          }

          final courses = courseSnap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = courses[i].data() as Map<String, dynamic>;
              final courseName = (c['name'] ?? 'Ders').toString();
              final courseId = courses[i].id;

              final examsQuery = FirebaseFirestore.instance
                  .collection('exams')
                  .where('courseId', isEqualTo: courseId);

              return Card(
                elevation: 1,
                child: ExpansionTile(
                  title: Text(
                    courseName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: examsQuery.snapshots(),
                      builder: (context, examSnap) {
                        if (examSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!examSnap.hasData || examSnap.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Bu ders için sınav yok.'),
                          );
                        }

                        final exams = examSnap.data!.docs;

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: exams.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, j) {
                            final e = exams[j].data() as Map<String, dynamic>;
                            final examId = exams[j].id;
                            final examName = (e['name'] ?? 'Sınav').toString();
                            final isPublished =
                                (e['isPublished'] ?? false) == true;
                            final answersPublished =
                                (e['answersPublished'] ?? false) == true;

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Başlık (uzunsa kısalt)
                                    Text(
                                      examName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),

                                    // Rozetler: Wrap ile satır taşsınca alta aksın
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _Badge(
                                          text: isPublished
                                              ? 'Yayınlandı'
                                              : 'Taslak',
                                          color: isPublished
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        _Badge(
                                          text: answersPublished
                                              ? 'Sonuç Yayında'
                                              : 'Sonuç Kapalı',
                                          color: answersPublished
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Aksiyon butonları: OverflowBar/W​rap ile sardır
                                    OverflowBar(
                                      spacing: 8,
                                      overflowSpacing: 8,
                                      alignment: MainAxisAlignment.start,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    StudentExamResultPage(
                                                      examId: examId,
                                                      studentId: studentId,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: const Text('Sonuç'),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.pie_chart,
                                            size: 18,
                                          ),
                                          label: const Text('İstatistik'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ExamStatsStudentPage(
                                                      examId: examId,
                                                      studentId: studentId,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
