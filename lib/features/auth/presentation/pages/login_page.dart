import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/widgets/html_content_page.dart';
import '../../data/datasources/social_auth_provider.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../factories/auth_navigation_factory.dart';
import '../../../../core/widgets/jv2.dart';
import '../widgets/login_help_sheet.dart';
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
  String? _busyProvider; // 'apple' | 'google' | null

  Future<void> _onSocialTap(String provider) async {
    if (_busyProvider != null) return;
    setState(() => _busyProvider = provider);
    try {
      final result = provider == 'apple'
          ? await SocialAuthProvider.signInWithApple()
          : await SocialAuthProvider.signInWithGoogle();
      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthSocialLoginEvent(
          provider: provider,
          idToken: result.idToken,
          name: result.name,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyProvider = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _openLegal(String titleKey, String? Function(String lang) html) {
    final lang = context.locale.languageCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HtmlContentPage(title: titleKey.tr(), html: html(lang)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoading) {
          setState(() => _busyProvider = null);
        }
        AuthNavigationFactory.handleState(context, state, lastPhone: '');
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      MediaQuery.of(context).padding.top + 28,
                      24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const JV2Mark(size: 42),
                        const SizedBox(height: 24),
                        Text(
                          'auth.login_title'.tr(),
                          style: JV2.display(context, 32),
                        ),
                        const SizedBox(height: 10),
                        Text('auth.login_sub'.tr(), style: JV2.sub),
                        const SizedBox(height: 26),
                        const _LoginPhotoGrid(),
                        const SizedBox(height: 18),
                        const _LoginFeatureList(),
                        const SizedBox(height: 26),
                        SocialLoginSection(
                          busyProvider: _busyProvider,
                          onTap: _onSocialTap,
                        ),
                        const SizedBox(height: 14),
                        _TermsNote(
                          onTerms: () => _openLegal(
                            'more.terms_of_service',
                            (lang) => AppSettingsService.instance.terms(lang),
                          ),
                          onPrivacy: () => _openLegal(
                            'more.privacy_policy',
                            (lang) =>
                                AppSettingsService.instance.privacy(lang),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    MediaQuery.of(context).padding.bottom + 18,
                  ),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => showLoginHelpSheet(context),
                        style: TextButton.styleFrom(
                          foregroundColor: JV2.inkSub,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: JV2.inkSub,
                            ),
                            children: [
                              TextSpan(text: '${'auth.trouble_signing_in'.tr()} '),
                              TextSpan(
                                text: 'auth.contact_us_link'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: JV2.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 13,
                            color: JV2.inkMute,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'auth.login_privacy_note'.tr(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: JV2.inkMute,
                            ),
                          ),
                        ],
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

// ─── Photo grid — reuses the onboarding photos, no overlay plates ─────────────

class _LoginPhotoGrid extends StatelessWidget {
  const _LoginPhotoGrid();

  static const _big = 'assets/onboarding/onb-compounds.png';
  static const _smallTop = 'assets/onboarding/onb-ask.png';
  static const _smallBottom = 'assets/onboarding/onb-sell.png';

  Widget _tile(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: JV2.fillFaint,
          border: Border.all(color: JV2.line),
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        children: [
          Expanded(flex: 5, child: _tile(_big)),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(child: _tile(_smallTop)),
                const SizedBox(height: 8),
                Expanded(child: _tile(_smallBottom)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature bullets ───────────────────────────────────────────────────────────

class _LoginFeatureList extends StatelessWidget {
  const _LoginFeatureList();

  static const _keys = [
    'auth.login_feature_1',
    'auth.login_feature_2',
    'auth.login_feature_3',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _keys.length; i++) ...[
          if (i != 0) const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0x1A137A55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: JV2.success,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _keys[i].tr(),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: JV2.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Terms / privacy footnote ───────────────────────────────────────────────────

class _TermsNote extends StatelessWidget {
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _TermsNote({required this.onTerms, required this.onPrivacy});

  static const _linkStyle = TextStyle(
    fontSize: 12.5,
    height: 1.5,
    color: JV2.gold,
    decoration: TextDecoration.underline,
    decorationColor: JV2.goldEdge,
  );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 12.5, height: 1.5, color: JV2.inkSub),
        children: [
          TextSpan(text: 'auth.terms_prefix'.tr()),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTerms,
              child: Text('auth.terms_of_service'.tr(), style: _linkStyle),
            ),
          ),
          TextSpan(text: 'auth.terms_connector'.tr()),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onPrivacy,
              child: Text('auth.privacy_policy'.tr(), style: _linkStyle),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
