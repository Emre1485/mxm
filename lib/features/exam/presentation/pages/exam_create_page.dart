import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_exam/features/exam/domain/entities/exam.dart';
import 'package:mobile_exam/features/exam/presentation/pages/question_create_page.dart';

class ExamCreatePage extends StatefulWidget {
  final String courseId;

  const ExamCreatePage({super.key, required this.courseId});

  @override
  State<ExamCreatePage> createState() => _ExamCreatePageState();
}

class _ExamCreatePageState extends State<ExamCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DateTime? _startTime;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sınav Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _scrollController,
              children: [
                // Sınav Adı
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Sınav Adı'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Süre
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Süre (dakika cinsinden)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Zorunlu';
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Geçersiz süre';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Başlangıç Tarihi/Saati
                ListTile(
                  title: Text(
                    _startTime == null
                        ? 'Başlangıç zamanı seçilmedi'
                        : DateFormat('yyyy-MM-dd – HH:mm').format(_startTime!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateTime,
                ),

                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Taslak Olarak Kaydet'),
                  onPressed: _saveExam,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (pickedTime == null) return;

    setState(() {
      _startTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate() || _startTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tüm alanları doldurun')));
      return;
    }

    final exam = Exam(
      id: '', // doc id'sini set edilcek
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      courseId: widget.courseId,
      startTime: _startTime!,
      durationMinutes: int.parse(_durationController.text),
      isPublished: false,
      isDeleted: false,
      createdAt: DateTime.now(),
    );

    try {
      // docRef ile ID al sonra exam nesnesine set et
      final docRef = FirebaseFirestore.instance.collection('exams').doc();
      final examWithId = exam.copyWith(id: docRef.id);

      await docRef.set(examWithId.toMap());

      // Kaydetme başarılıysa soru ekleme sayfasına geç
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionCreatePage(examId: docRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt başarısız: $e')));
    }
  }
}
