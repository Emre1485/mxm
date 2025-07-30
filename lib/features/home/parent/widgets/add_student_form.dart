import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStudentForm extends StatefulWidget {
  final String parentId; // Velinin uid'si

  const AddStudentForm({super.key, required this.parentId});

  @override
  State<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Yeni öğrenci Firebase Auth oluştur
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final studentUid = userCredential.user!.uid;

      // 2. Firestore'da student kaydı oluştur, parentId ile ilişkilendir
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentUid)
          .set({
            'uid': studentUid,
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'parentId': widget.parentId,
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Başarılı mesaj veya başka işlem (örn: geri dön)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci başarıyla eklendi!')),
      );
      Navigator.of(context).pop();

      // Formu temizle veya ekranı kapat
      nameController.clear();
      emailController.clear();
      passwordController.clear();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      errorMessage = e.message;
    } catch (e) {
      print('Other Exception: $e');
      errorMessage = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: bottomInset, // klavye açıldığında alt boşluk
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Yükseklik sarmalasın
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Öğrenci Adı'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ad girin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val != null && val.contains('@')
                    ? null
                    : 'Geçerli email girin',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (val) =>
                    val != null && val.length >= 6 ? null : 'En az 6 karakter',
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: registerStudent,
                        child: const Text('Öğrenci Ekle'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
