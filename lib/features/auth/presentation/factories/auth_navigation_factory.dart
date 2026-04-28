import 'package:flutter/material.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../bloc/auth_state.dart';
import '../pages/complete_profile_page.dart';

class AuthNavigationFactory {
  const AuthNavigationFactory._();

  static void handleState(
    BuildContext context,
    AuthState state, {
    required String lastPhone,
  }) {
    if (state is AuthPhoneChecked) {
      _navigateAfterPhoneCheck(context, state, lastPhone);
    } else if (state is AuthProfileCompleted) {
      _goToMain(context);
    } else if (state is AuthError) {
      _showError(context, state.message);
    }
  }

  static void _navigateAfterPhoneCheck(
    BuildContext context,
    AuthPhoneChecked state,
    String lastPhone,
  ) {
    if (!state.isProfileComplete) {
      _goToCompleteProfile(context, lastPhone);
    } else {
      _goToMain(context);
    }
  }

  static void _goToCompleteProfile(BuildContext context, String phone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteProfilePage(phone: phone),
      ),
    );
  }

  static void _goToMain(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
      (_) => false,
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
