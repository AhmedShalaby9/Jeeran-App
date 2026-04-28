content = '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'complete_profile_page.dart';
import 'widgets/login_header.dart';
import 'widgets/login_phone_form.dart';
import 'widgets/terms_footer.dart';
import '../../../main/presentation/pages/main_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPhoneChecked) {
          if (state.isNewUser || state.user == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainPage()),
              (_) => false,
            );
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const LoginHeader(),
            Expanded(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return LoginPhoneForm(
                    isLoading: isLoading,
                    onContinue: (phone) {
                      context.read<AuthBloc>().add(AuthLoginEvent(phone));
                    },
                  );
                },
              ),
            ),
            const TermsFooter(),
          ],
        ),
      ),
    );
  }
}
'''
with open('lib/features/auth/presentation/pages/login_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('login_page.dart written')
