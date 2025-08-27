import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_exam/features/auth/data/firebase_auth_repo.dart';
import 'package:mobile_exam/features/auth/domain/entities/app_user.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile_exam/features/auth/presentation/cubits/auth_states.dart';
import 'package:mobile_exam/features/auth/presentation/pages/auth_page.dart';
import 'package:mobile_exam/features/course/data/course_firestore_repo.dart';
import 'package:mobile_exam/features/course/presentation/cubits/course_cubit.dart';
import 'package:mobile_exam/features/home/parent/pages/parent_home_page.dart';
import 'package:mobile_exam/features/home/student/pages/student_home_page.dart';
import 'package:mobile_exam/features/home/teacher/pages/teacher_home_page.dart';
import 'package:mobile_exam/themes/light_mode.dart';

/*
  APP - ROOT LEVEL
  --------------------------------------------------------------------------------------------------
  Repositories: for the DB
  - firebase

  BLOC Providers: for the state mangement  
    - auth
    - theme
    - profile
  
  Check Auth STATE
   - unauthenticated -> auth page (login/register)
   - authenticated -> home page
 */

class MobileExams extends StatelessWidget {
  final authRepo = FirebaseAuthRepo();
  final courseRepo = CourseFirestoreRepo();

  MobileExams({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepo: authRepo)..checkAuth(),
        ),
        BlocProvider<CourseCubit>(
          create: (context) => CourseCubit(courseRepo: courseRepo),
        ),
      ],
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

              switch (user.role) {
                case UserRole.teacher:
                  return TeacherHomePage(teacher: user);
                case UserRole.parent:
                  return ParentHomePage(parentId: user.uid);
                case UserRole.student:
                  return StudentHomePage(studentUid: user.uid);
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
