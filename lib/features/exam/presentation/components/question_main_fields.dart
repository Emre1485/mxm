import 'package:flutter/material.dart';

class QuestionMainFields extends StatelessWidget {
  final TextEditingController textController;
  final TextEditingController topicController;
  final TextEditingController pointController;
  final TextEditingController imageUrlController;

  const QuestionMainFields({
    super.key,
    required this.textController,
    required this.topicController,
    required this.pointController,
    required this.imageUrlController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: textController,
          decoration: const InputDecoration(labelText: "Soru Metni"),
          maxLength: 500,
          maxLines: 3,
          validator: (val) => val == null || val.isEmpty ? "Zorunlu" : null,
        ),
        TextFormField(
          controller: topicController,
          decoration: const InputDecoration(labelText: "Konu"),
          maxLength: 100,
          validator: (val) => val == null || val.isEmpty ? "Zorunlu" : null,
        ),
        TextFormField(
          controller: pointController,
          decoration: const InputDecoration(labelText: "Puan"),
          keyboardType: TextInputType.number,
          validator: (val) {
            final point = int.tryParse(val ?? "");
            if (point == null || point <= 0) return "Geçerli puan girin";
            return null;
          },
        ),
        TextFormField(
          controller: imageUrlController,
          decoration: const InputDecoration(
            labelText: "Görsel URL (opsiyonel)",
          ),
          maxLength: 500,
        ),
      ],
    );
  }
}
