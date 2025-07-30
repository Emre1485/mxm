/*
  
  Auth Page - Determines whether to show the login or register page

 */

import 'package:flutter/widgets.dart';
import 'package:mobile_exam/features/auth/presentation/pages/login_page.dart';
import 'package:mobile_exam/features/auth/presentation/pages/register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Initially Show LOGIN PAGE
  bool showLoginPage = true;

  // toggle between pages
  void togglePages() => setState(() => showLoginPage = !showLoginPage);

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(togglePages: togglePages);
    }
    return RegisterPage(togglePages: togglePages);
  }
}
