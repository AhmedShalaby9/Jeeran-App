import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../factories/auth_navigation_factory.dart';
import '../widgets/login_header.dart';
import '../widgets/login_phone_form.dart';
import '../widgets/terms_footer.dart';

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

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  String _lastPhone = '';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => AuthNavigationFactory.handleState(
        context,
        state,
        lastPhone: _lastPhone,
      ),
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
                      setState(() => _lastPhone = phone);
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
