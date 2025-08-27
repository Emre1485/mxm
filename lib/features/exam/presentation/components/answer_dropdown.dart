import 'package:flutter/material.dart';

class AnswerDropdown extends StatelessWidget {
  final List<DropdownMenuItem<String>> items;
  final String? value;
  final void Function(String?) onChanged;
  final String label;

  const AnswerDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (val) {
        if (val != null && !items.map((e) => e.value).contains(val)) {
          return "Geçersiz cevap";
        }
        return null;
      },
    );
  }
}
