import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentList extends StatelessWidget {
  final String parentId;

  const StudentList({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Firestore HATA: ${snapshot.error}');
          return const Center(child: Text('Bir hata oluştu'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Henüz öğrenci eklenmemiş.'));
        }

        final students = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            itemCount: students.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 sütun
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2, // Kart oranı
            ),
            itemBuilder: (context, index) {
              final student = students[index].data() as Map<String, dynamic>;

              final name = student['name'] ?? 'İsimsiz';
              final email = student['email'] ?? '';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
