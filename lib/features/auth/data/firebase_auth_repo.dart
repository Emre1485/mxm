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

    // Firestore'dan user bilgisi al
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
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) throw Exception("Kullanıcı verisi bulunamadı");

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
    UserRole role, // 👈 Yeni parametre
  ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      final user = AppUser(uid: uid, email: email, name: name, role: role);

      // Firestore'a yaz
      await firestore.collection('users').doc(uid).set(user.toJson());

      return user;
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }
}
