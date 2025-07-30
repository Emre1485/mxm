import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

// Başlangıç durumu
class AuthInitial extends AuthState {}

// Yükleniyor
class AuthLoading extends AuthState {}

// Hata durumu
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Oturum açık ama genel, rol belirtilmemişse
class Authenticated extends AuthState {
  final AppUser user;
  Authenticated(this.user);
}

// Rol bazlı durumlar
class AuthTeacher extends AuthState {
  final AppUser user;
  AuthTeacher(this.user);
}

class AuthParent extends AuthState {
  final AppUser user;
  AuthParent(this.user);
}

class AuthStudent extends AuthState {
  final AppUser user;
  AuthStudent(this.user);
}

// Oturum kapalı
class Unauthenticated extends AuthState {}
