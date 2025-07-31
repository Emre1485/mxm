import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';
import 'package:mobile_exam/features/auth/domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromJson(doc.data()!);
  }

  @override
  Future<void> logOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final doc = await firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception("Kullanıcı verisi bulunamadı");
      }

      return AppUser.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final user = AppUser(
        uid: uid,
        email: email,
        name: name,
        role: role,
        createdAt: null, // Oluştururken null, Firestore kendisi ekleyecek
      );

      await firestore.collection('users').doc(uid).set({
        ...user.toJson(),
        'createdAt': FieldValue.serverTimestamp(), //sadece burada ekleniyor
      });

      // createdAt alanını okuma gerekebilirmiş, tekrar fetch:
      final createdDoc = await firestore.collection('users').doc(uid).get();
      return AppUser.fromJson(createdDoc.data()!);
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }
}
