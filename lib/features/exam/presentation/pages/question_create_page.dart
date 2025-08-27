import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_exam/features/exam/domain/entities/question.dart';
import 'package:mobile_exam/features/exam/presentation/components/question_type_selector.dart';
import 'package:mobile_exam/features/exam/presentation/components/question_main_fields.dart';
import 'package:mobile_exam/features/exam/presentation/components/multiple_choice_inputs.dart';
import 'package:mobile_exam/features/exam/presentation/components/answer_dropdown.dart';

class QuestionCreatePage extends StatefulWidget {
  final String examId;

  const QuestionCreatePage({super.key, required this.examId});

  @override
  State<QuestionCreatePage> createState() => _QuestionCreatePageState();
}

class _QuestionCreatePageState extends State<QuestionCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final _textController = TextEditingController();
  final _topicController = TextEditingController();
  final _pointController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _scrollController = ScrollController();

  final List<TextEditingController> _choiceControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  QuestionType? _selectedType;
  String? _correctAnswer;

  @override
  Widget build(BuildContext context) {
    final correctAnswerOptions = _buildMultipleChoiceCorrectAnswerOptions();
    final correctAnswerValue =
        correctAnswerOptions.any((item) => item.value == _correctAnswer)
        ? _correctAnswer
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Soru Ekle")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  QuestionTypeSelector(
                    selectedType: _selectedType,
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val;
                        _correctAnswer = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  QuestionMainFields(
                    textController: _textController,
                    topicController: _topicController,
                    pointController: _pointController,
                    imageUrlController: _imageUrlController,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == QuestionType.multipleChoice)
                    MultipleChoiceInputs(
                      choiceControllers: _choiceControllers,
                      onChanged: () => setState(() {}),
                    ),

                  if (_selectedType == QuestionType.multipleChoice)
                    AnswerDropdown(
                      label: "Doğru Cevap (A-E)",
                      items: correctAnswerOptions,
                      value: correctAnswerValue,
                      onChanged: (val) => setState(() => _correctAnswer = val),
                    ),
                  if (_selectedType == QuestionType.trueFalse)
                    AnswerDropdown(
                      label: "Doğru Cevap (D/Y)",
                      items: const [
                        DropdownMenuItem(value: 'D', child: Text('Doğru (D)')),
                        DropdownMenuItem(value: 'Y', child: Text('Yanlış (Y)')),
                      ],
                      value: _correctAnswer,
                      onChanged: (val) => setState(() => _correctAnswer = val),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Soruyu Kaydet"),
                    onPressed: _saveQuestion,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Sınavı Yayınla'),
                    onPressed: _publishExam,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildMultipleChoiceCorrectAnswerOptions() {
    final options = <DropdownMenuItem<String>>[];
    for (var i = 0; i < 5; i++) {
      if (_choiceControllers[i].text.trim().isEmpty) continue;
      final label = String.fromCharCode(65 + i);
      options.add(DropdownMenuItem(value: label, child: Text(label)));
    }
    return options;
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final id = const Uuid().v4();
    final choices = _selectedType == QuestionType.multipleChoice
        ? _choiceControllers
              .map((c) => c.text.trim())
              .where((text) => text.isNotEmpty)
              .toList()
        : null;

    final question = Question(
      id: id,
      type: _selectedType!,
      questionText: _textController.text.trim(),
      topic: _topicController.text.trim(),
      score: int.parse(_pointController.text.trim()),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      choices: choices,
      answer: _selectedType == QuestionType.essay ? null : _correctAnswer,
    );

    await FirebaseFirestore.instance
        .collection('exams')
        .doc(widget.examId)
        .collection('questions')
        .doc(id)
        .set(question.toMap());

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Soru başarıyla eklendi")));
      _formKey.currentState!.reset();
      setState(() {
        _selectedType = null;
        _correctAnswer = null;
      });
      _textController.clear();
      _topicController.clear();
      _pointController.clear();
      _imageUrlController.clear();
      for (final controller in _choiceControllers) {
        controller.clear();
      }
    }
  }

  Future<void> _publishExam() async {
    await FirebaseFirestore.instance
        .collection('exams')
        .doc(widget.examId)
        .update({'isPublished': true});

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sınav yayınlandı')));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _topicController.dispose();
    _pointController.dispose();
    _imageUrlController.dispose();
    for (final controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
