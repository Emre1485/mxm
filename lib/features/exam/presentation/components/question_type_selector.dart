import 'package:flutter/material.dart';
import 'package:mobile_exam/features/exam/domain/entities/question.dart';

class QuestionTypeSelector extends StatelessWidget {
  final QuestionType? selectedType;
  final void Function(QuestionType?) onChanged;

  const QuestionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<QuestionType>(
      value: selectedType,
      decoration: const InputDecoration(labelText: "Soru Tipi"),
      items: QuestionType.values.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.name));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Zorunlu alan" : null,
    );
  }
}
