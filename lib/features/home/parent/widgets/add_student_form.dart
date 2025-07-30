import 'package:flutter/material.dart';

class AddStudentForm extends StatefulWidget {
  const AddStudentForm({super.key});

  @override
  State<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  void submitStudent() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm alanları doldurmalısınız')),
      );
      return;
    }

    // TODO: Firebase'e öğrenci oluşturmayı buraya bağlanacak
    debugPrint('Yeni öğrenci: $name - $email');

    // temizle
    nameController.clear();
    emailController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Öğrenci başarıyla eklendi!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yeni Öğrenci Ekle',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Öğrenci Adı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Öğrenci E-mail',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        ElevatedButton(onPressed: submitStudent, child: const Text('Ekle')),
      ],
    );
  }
}
