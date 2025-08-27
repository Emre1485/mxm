import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> showJoinCourseDialog(BuildContext context, String studentUid) {
  final codeController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Join Kodu ile Derse Katıl'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: 'Join kodunu girin'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final joinCode = codeController.text.trim();
              if (joinCode.isNotEmpty) {
                Navigator.pop(context); // Önce dialog kapansın
                await _joinCourseByCode(context, studentUid, joinCode);
              }
            },
            child: const Text('Katıl'),
          ),
        ],
      );
    },
  );
}

Future<void> _joinCourseByCode(
  BuildContext context,
  String studentUid,
  String joinCode,
) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final matchingCourses = await firestore
        .collection('courses')
        .where('joinCode', isEqualTo: joinCode)
        .get();

    if (matchingCourses.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Böyle bir ders bulunamadı')),
      );
      return;
    }

    final courseDoc = matchingCourses.docs.first;
    final courseRef = firestore.collection('courses').doc(courseDoc.id);
    final studentIds = List<String>.from(courseDoc['studentIds'] ?? []);

    if (!studentIds.contains(studentUid)) {
      studentIds.add(studentUid);
      await courseRef.update({'studentIds': studentIds});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Derse başarıyla katıldınız')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zaten bu derstesiniz')));
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
  }
}
