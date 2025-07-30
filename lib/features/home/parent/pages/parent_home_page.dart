import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile_exam/features/home/parent/widgets/add_student_form.dart';
import 'package:mobile_exam/features/home/parent/widgets/student_list.dart';

class ParentHomePage extends StatelessWidget {
  final String parentId;

  const ParentHomePage({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Öğrencilerim')),
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
      body: StudentList(parentId: parentId),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .where('parentId', isEqualTo: parentId)
                .snapshots(),
            builder: (context, snapshot) {
              final studentCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;
              final canAdd = studentCount < 8;

              return SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: canAdd
                      ? () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              final bottom = MediaQuery.of(
                                context,
                              ).viewInsets.bottom;
                              return AnimatedPadding(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                padding: EdgeInsets.only(bottom: bottom),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                        0.5,
                                  ),
                                  child: SingleChildScrollView(
                                    child: AddStudentForm(parentId: parentId),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      : null,

                  label: const Text('Yeni Öğrenci'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAdd ? Colors.blue : Colors.grey,
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
