import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_primary_button.dart';

class LoginPhoneForm extends StatefulWidget {
  final bool isLoading;
  final ValueChanged<String> onContinue;

  const LoginPhoneForm({
    super.key,
    required this.isLoading,
    required this.onContinue,
  });

  @override
  State<LoginPhoneForm> createState() => _LoginPhoneFormState();
}

class _LoginPhoneFormState extends State<LoginPhoneForm> {
  final _phoneCtrl = TextEditingController();
  bool _valid = false;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      setState(() {
        _valid = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 10;
      });
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_valid || !_termsAccepted || widget.isLoading) return;
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    widget.onContinue('+20$digits');
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
                    icon: const Icon(Icons.close_rounded, color: AppColors.inkSub),
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
                            style: TextStyle(fontSize: 14, color: AppColors.grey),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth.phone_number'.tr(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '+20',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                    ],
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.ink,
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'auth.phone_hint'.tr(),
                      hintStyle: const TextStyle(
                        color: AppColors.inkMute,
                        fontSize: 17,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'auth.phone_helper'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: 'auth.continue'.tr(),
            enabled: _valid && _termsAccepted && !widget.isLoading,
            onTap: _onContinue,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'auth.agree_terms_prefix'.tr(),
                style: const TextStyle(fontSize: 13, color: AppColors.inkSub),
              ),
              GestureDetector(
                onTap: () => _showTermsDialog(context),
                child: Text(
                  'auth.terms_of_service'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
