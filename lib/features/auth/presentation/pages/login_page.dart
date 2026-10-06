import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/social_auth_provider.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../factories/auth_navigation_factory.dart';
import '../../../../core/widgets/jv2.dart';
import '../widgets/login_phone_form.dart';
import '../widgets/social_login_section.dart';

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
  bool _socialLoading = false;
  bool _termsAccepted = false;

  Future<void> _onGoogleTap() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auth.accept_terms_first'.tr())));
      return;
    }
    if (_socialLoading) return;
    setState(() => _socialLoading = true);
    try {
      final result = await SocialAuthProvider.signInWithGoogle();
      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthSocialLoginEvent(
          provider: 'google',
          idToken: result.idToken,
          name: result.name,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  Future<void> _onAppleTap() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auth.accept_terms_first'.tr())));
      return;
    }
    if (_socialLoading) return;
    setState(() => _socialLoading = true);
    try {
      final result = await SocialAuthProvider.signInWithApple();
      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthSocialLoginEvent(
          provider: 'apple',
          idToken: result.idToken,
          name: result.name,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoading) {
          setState(() => _socialLoading = false);
        }
        AuthNavigationFactory.handleState(
          context,
          state,
          lastPhone: _lastPhone,
        );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: JV2.bgDeep,
          resizeToAvoidBottomInset: true,
          body: JV2Ambient(
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          MediaQuery.of(context).padding.top + 28,
                          24,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const JV2Mark(size: 46),
                            const SizedBox(height: 30),
                            Text(
                              'auth.login_title'.tr(),
                              style: JV2.display(context, 34),
                            ),
                            const SizedBox(height: 10),
                            Text('auth.login_sub'.tr(), style: JV2.sub),
                            const SizedBox(height: 30),
                            LoginPhoneForm(
                              isLoading: isLoading || _socialLoading,
                              termsAccepted: _termsAccepted,
                              onTermsChanged: (v) =>
                                  setState(() => _termsAccepted = v),
                              onContinue: (phone) {
                                setState(() => _lastPhone = phone);
                                context.read<AuthBloc>().add(
                                  AuthSendOtpEvent(phone),
                                );
                              },
                            ),
                            SocialLoginSection(
                              isLoading: isLoading || _socialLoading,
                              onGoogleTap: _onGoogleTap,
                              onAppleTap: _onAppleTap,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    MediaQuery.of(context).padding.bottom + 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: JV2.inkMute,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'auth.number_private'.tr(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: JV2.inkMute,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
