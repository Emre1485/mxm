import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';
import 'package:mobile_exam/features/exam/domain/entities/exam.dart';
import 'package:mobile_exam/features/exam/presentation/pages/exam_create_page.dart';

// alias'lar: isim çakışmasını önlemek için
import 'package:mobile_exam/features/exam/presentation/pages/exam_detail_page.dart'
    as teacher;
import 'package:mobile_exam/features/exam/presentation/pages/student_exam_detail_page.dart'
    as student;
import 'package:mobile_exam/features/exam/presentation/pages/student_exam_result_page.dart'
    as studentResult; // <-- EKLE

class ExamsCard extends StatelessWidget {
  final String courseId;
  final AppUser currentUser;

  const ExamsCard({
    super.key,
    required this.courseId,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final examsRef = FirebaseFirestore.instance
        .collection('exams')
        .where('courseId', isEqualTo: courseId);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Başlık + Ekle Butonu (Sadece Öğretmen)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sınavlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (currentUser.role == UserRole.teacher)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExamCreatePage(courseId: courseId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Sınav Ekle'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            /// Firestore Sınav Listeleme
            StreamBuilder<QuerySnapshot>(
              stream: examsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Henüz sınav yok.');
                }

                final exams = snapshot.data!.docs.map((doc) {
                  return Exam.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                return ListView.builder(
                  itemCount: exams.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return ListTile(
                      title: Text(exam.name),
                      subtitle: Text('Başlangıç: ${exam.startTime}'),
                      onTap: () async {
                        if (currentUser.role == UserRole.teacher) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  teacher.ExamDetailPage(exam: exam),
                            ),
                          );
                        } else {
                          // --- ÖĞRENCİ AKIŞI ---
                          final answersDocId = "${exam.id}_${currentUser.uid}";

                          // 1) Exam doc: answersPublished?
                          final examDoc = await FirebaseFirestore.instance
                              .collection('exams')
                              .doc(exam.id)
                              .get();
                          final published =
                              (examDoc.data()?['answersPublished'] ?? false) ==
                              true;

                          // 2) Student answer doc
                          final ansDoc = await FirebaseFirestore.instance
                              .collection('studentExamAnswers')
                              .doc(answersDocId)
                              .get();

                          final now = DateTime.now();
                          final start = exam.startTime; // Exam entity DateTime
                          final end = start.add(
                            Duration(minutes: exam.durationMinutes),
                          );
                          final inWindow =
                              now.isAfter(start) && now.isBefore(end);

                          if (ansDoc.exists) {
                            // Öğrenci daha önce göndermiş
                            final data = ansDoc.data()!;
                            final status = (data['status'] ?? '') as String;
                            final total = data['totalScore'];

                            if (published &&
                                status == 'released' &&
                                total != null) {
                              // -> SONUÇ SAYFASINA
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      studentResult.StudentExamResultPage(
                                        examId: exam.id,
                                        studentId: currentUser.uid,
                                      ),
                                ),
                              );
                            } else {
                              // Gönderim var ama henüz yayınlanmamış ya da totalScore hazır değil
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cevaplarınız alındı. Sonuçlar yayınlandığında burada görünecek.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            // Henüz cevap yok
                            if (inWindow && exam.isPublished) {
                              // -> SINAVA GİR
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => student.StudentExamDetailPage(
                                    examId: exam.id,
                                    studentId: currentUser.uid,
                                  ),
                                ),
                              );
                            } else if (published) {
                              // Sonuçlar yayınlanmış ama öğrenci hiç girmemiş
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bu sınava katılmadınız.'),
                                ),
                              );
                            } else {
                              // Ne yayınlanmış ne de zaman uygun
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sınav şu anda erişilebilir değil.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
