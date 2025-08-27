import 'package:flutter/material.dart';

class MultipleChoiceInputs extends StatelessWidget {
  final List<TextEditingController> choiceControllers;
  final VoidCallback onChanged;

  const MultipleChoiceInputs({
    super.key,
    required this.choiceControllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return TextFormField(
          controller: choiceControllers[index],
          maxLength: 100,
          decoration: InputDecoration(
            labelText: "Seçenek ${String.fromCharCode(65 + index)}",
          ),
          validator: (val) {
            if (index < 3 && (val == null || val.isEmpty)) {
              return "İlk 3 seçenek zorunlu";
            }
            return null;
          },
          onChanged: (_) => onChanged(), // Bu satır dropdown'ı tetikler
        );
      }),
    );
  }
}
