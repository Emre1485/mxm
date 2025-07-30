import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/data/firebase_auth_repo.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_states.dart';
import 'package:mobile_exam/features/auth/presentation/pages/auth_page.dart';
import 'package:mobile_exam/features/home/parent/pages/parent_home_page.dart';
import 'package:mobile_exam/themes/light_mode.dart';

/*
  APP - ROOT LEVEL
  --------------------------------------------------------------------------------------------------
  Repositories: for the DB
  - firebase

  BLOC Providers: for the state mangement  
    - auth
    - post
    - search
    - theme
    - profile
  
  Check Auth STATE
   - unauthenticated -> auth page (login/register)
   - authenticated -> home page
 */

class MobileExams extends StatelessWidget {
  // auth repo
  final authRepo = FirebaseAuthRepo();

  MobileExams({super.key});

  @override
  Widget build(BuildContext context) {
    // provide cubit to app
    return BlocProvider(
      create: (context) => AuthCubit(authRepo: authRepo)..checkAuth(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        home: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, authState) {
            if (authState is Unauthenticated) {
              return const AuthPage();
            }

            if (authState is Authenticated) {
              final AppUser user = authState.user;

              // Role’a göre yönlendirme
              switch (user.role) {
                case UserRole.teacher:
                  return const Scaffold(); // TeacherHomePage();
                case UserRole.parent:
                  return ParentHomePage(parentId: user.uid); //ParentHomePage();
                case UserRole.student:
                  return const Scaffold(); //StudentHomePage();
              }
            }

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
