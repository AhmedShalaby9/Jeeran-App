import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/jv2.dart';

// ─── Country data ──────────────────────────────────────────────────────────────

class _CountryInfo {
  final String name;
  final String flag;
  final String dialCode;
  final IsoCode isoCode;

  const _CountryInfo(this.name, this.flag, this.dialCode, this.isoCode);
}

const _egypt = _CountryInfo('Egypt', '\u{1F1EA}\u{1F1EC}', '+20', IsoCode.EG);

// ─── Widget ───────────────────────────────────────────────────────────────────

class LoginPhoneForm extends StatefulWidget {
  final bool isLoading;
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<String> onContinue;

  const LoginPhoneForm({
    super.key,
    required this.isLoading,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.onContinue,
  });

  @override
  State<LoginPhoneForm> createState() => _LoginPhoneFormState();
}

class _LoginPhoneFormState extends State<LoginPhoneForm> {
  final _phoneCtrl = TextEditingController();
  bool _valid = false;
  final _CountryInfo _selectedCountry = _egypt;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_validatePhone);
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (_valid) setState(() => _valid = false);
      return;
    }
    bool isValid = false;
    try {
      final parsed = PhoneNumber.parse(
        digits,
        callerCountry: _selectedCountry.isoCode,
      );
      isValid = parsed.isValid();
    } catch (_) {
      isValid = false;
    }
    if (isValid != _valid) setState(() => _valid = isValid);
  }

  void _onContinue() {
    if (!_valid || !widget.termsAccepted || widget.isLoading) return;
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    try {
      final parsed = PhoneNumber.parse(
        digits,
        callerCountry: _selectedCountry.isoCode,
      );
      widget.onContinue(parsed.international);
    } catch (_) {
      // Fallback — shouldn't happen when _valid is true
      widget.onContinue('${_selectedCountry.dialCode}$digits');
    }
  }

  void _showTermsDialog(BuildContext context) {
    final lang = context.locale.languageCode;
    final html = AppSettingsService.instance.terms(lang);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'auth.terms_of_service'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.inkSub,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: html != null && html.isNotEmpty
                    ? Html(
                        data: html,
                        style: {
                          'body': Style(
                            fontSize: FontSize(14),
                            color: AppColors.inkSub,
                            lineHeight: LineHeight(1.65),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          'h1, h2, h3': Style(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          'a': Style(color: AppColors.secondary),
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Content coming soon',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _valid && widget.termsAccepted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JV2Field(
          label: 'auth.mobile_number'.tr(),
          controller: _phoneCtrl,
          placeholder: 'auth.phone_hint'.tr(),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
          ],
          prefix: Container(
            padding: const EdgeInsetsDirectional.only(end: 11),
            decoration: const BoxDecoration(
              border: BorderDirectional(end: BorderSide(color: JV2.line)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCountry.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 7),
                Text(
                  _selectedCountry.dialCode,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: JV2.inkSub,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTermsChanged(!widget.termsAccepted),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: widget.termsAccepted
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [JV2.goldHi, Color(0xFFA67428)],
                        )
                      : null,
                  border: Border.all(
                    color: widget.termsAccepted
                        ? Colors.transparent
                        : const Color(0x330B2A4A),
                  ),
                ),
                child: widget.termsAccepted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: JV2.inkSub,
                    ),
                    children: [
                      TextSpan(text: 'auth.agree_terms_prefix'.tr()),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => _showTermsDialog(context),
                          child: Text(
                            'auth.terms_of_service'.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: JV2.gold,
                              decoration: TextDecoration.underline,
                              decorationColor: JV2.goldEdge,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        JV2PrimaryButton(
          onPressed: ready && !widget.isLoading ? _onContinue : null,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('auth.send_code'.tr()),
                    const SizedBox(width: 8),
                    Icon(
                      Directionality.of(context) == ui.TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
