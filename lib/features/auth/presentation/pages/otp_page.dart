import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/jv2.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'complete_profile_page.dart';

class OtpPage extends StatelessWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return _OtpView(phone: phone);
  }
}

class _OtpView extends StatefulWidget {
  final String phone;
  const _OtpView({required this.phone});

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  static const _codeLength = 6;
  static const _resendCooldown = 60;

  final _otpCtrl = TextEditingController();
  final _focusNode = FocusNode();

  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resend(BuildContext context) {
    _otpCtrl.clear();
    _startCountdown();
    context.read<AuthBloc>().add(AuthSendOtpEvent(widget.phone));
  }

  void _verify(BuildContext context) {
    final otp = _otpCtrl.text.trim();
    if (otp.length != _codeLength) return;
    context.read<AuthBloc>().add(
      AuthVerifyOtpEvent(phone: widget.phone, otp: otp),
    );
  }

  void _handleState(BuildContext context, AuthState state) {
    if (state is AuthOtpSent) {
      // Resend succeeded — timer already restarted in _resend()
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('auth.code_resent'.tr())));
    } else if (state is AuthPhoneChecked) {
      if (!state.isProfileComplete) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfilePage(
              phone: widget.phone,
              initialUser: state.user,
            ),
          ),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (_) => false,
        );
      }
    } else if (state is AuthError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  Widget _box(int i) {
    final digits = _otpCtrl.text;
    final filled = digits.length;
    final active = _focusNode.hasFocus && i == filled.clamp(0, _codeLength - 1);
    final hasDigit = i < filled;
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? JV2.goldEdge : JV2.line),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x1AC9A063), spreadRadius: 3)]
            : null,
      ),
      alignment: Alignment.center,
      child: hasDigit
          ? Text(digits[i], style: JV2.display(context, 27))
          : active
          ? const _Caret()
          : Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: JV2.track,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleState,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: JV2.bgDeep,
          body: JV2Ambient(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                final ready = _otpCtrl.text.length == _codeLength;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        media.padding.top + 12,
                        24,
                        0,
                      ),
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: JV2BackButton(),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'auth.step_of'.tr(args: ['1', '3']).toUpperCase(),
                              style: JV2.eyebrow,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'auth.otp_title'.tr(),
                              style: JV2.display(context, 34),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                style: JV2.sub,
                                children: [
                                  TextSpan(text: '${'auth.otp_sent_to'.tr()} '),
                                  TextSpan(
                                    text: widget.phone,
                                    style: const TextStyle(
                                      color: JV2.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: '  '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: JV2.gold,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'auth.change'.tr(),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              color: JV2.gold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Six boxes drawn over one real (invisible) field,
                            // so paste, SMS autofill and the keyboard all work.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _focusNode.requestFocus(),
                              child: Stack(
                                children: [
                                  Directionality(
                                    textDirection: ui.TextDirection.ltr,
                                    child: Row(
                                      children: [
                                        for (
                                          var i = 0;
                                          i < _codeLength;
                                          i++
                                        ) ...[
                                          if (i > 0) const SizedBox(width: 9),
                                          Expanded(child: _box(i)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: 0,
                                      child: TextField(
                                        controller: _otpCtrl,
                                        focusNode: _focusNode,
                                        autofocus: true,
                                        keyboardType: TextInputType.number,
                                        maxLength: _codeLength,
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ],
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        showCursor: false,
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                        onSubmitted: (_) => _verify(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),
                            Row(
                              children: [
                                if (_secondsLeft > 0) ...[
                                  const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: JV2.goldHi,
                                      backgroundColor: JV2.track,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: JV2.inkSub,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${'auth.resend_in'.tr()} ',
                                        ),
                                        TextSpan(
                                          text:
                                              '0:${_secondsLeft.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: JV2.ink,
                                            fontWeight: FontWeight.w600,
                                            fontFeatures: [
                                              ui.FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else
                                  GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () => _resend(context),
                                    child: Text(
                                      'auth.resend_code'.tr(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: JV2.gold,
                                      ),
                                    ),
                                  ),
                              ],
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
                        media.padding.bottom + 20,
                      ),
                      child: JV2PrimaryButton(
                        onPressed: isLoading || !ready
                            ? null
                            : () => _verify(context),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text('auth.verify'.tr()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Blinking tan caret shown in the active code box.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0,
        child: Container(width: 2, height: 24, color: JV2.goldHi),
      ),
    );
  }
}
