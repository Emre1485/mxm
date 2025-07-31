import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';

class StudentHomePage extends StatelessWidget {
  final String studentUid;

  const StudentHomePage({super.key, required this.studentUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Ana Sayfası'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              // AuthCubit'ten çıkış yapılır
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hoş geldin, ($studentUid)'),
            const SizedBox(height: 16),
            const Text('Katıldığın dersler burada listelenecek.'),
          ],
        ),
      ),
    );
  }
}
