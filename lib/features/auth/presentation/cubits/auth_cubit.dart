/*
CUBIT: Simplified version of Bloc for state Management.

AUTH CUBIT: State Management

*/

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';
import 'package:mobile_exam/features/auth/domain/repos/auth_repo.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  // check if user is already authenticate
  void checkAuth() async {
    final AppUser? user = await authRepo.getCurrentUser();

    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  // get current user
  AppUser? get currentUser => _currentUser;

  // login with email + pw
  Future<void> login(String email, String pw) async {
    try {
      final user = await authRepo.loginWithEmailPassword(email, pw);
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // register with email + pw
  Future<void> register(
    String email,
    String name,
    String pw,
    UserRole role,
  ) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.registerWithEmailPassword(
        name,
        email,
        pw,
        role,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  // logout
  Future<void> logout() async {
    authRepo.logOut();
    emit(Unauthenticated());
  }
}
