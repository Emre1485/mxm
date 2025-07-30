/*

Auth Repository - Outlines the possible auth operations for this app. 

*/

import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';

abstract class AuthRepo {
  Future<AppUser?> loginWithEmailPassword(String email, String password);
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
    UserRole role,
  );
  Future<void> logOut();
  Future<AppUser?> getCurrentUser();
}
