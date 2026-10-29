import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/contact_call.dart';
import '../../../../core/widgets/jv2.dart';

const _supportEmail = 'jeeranestate@gmail.com';

/// "Trouble signing in?" bottom sheet — WhatsApp / call / email a real person,
/// plus one-tap common-problem starters that open WhatsApp pre-filled.
Future<void> showLoginHelpSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => const _LoginHelpSheet(),
  );
}

Future<void> _openWhatsapp({String? text}) async {
  final raw = ContactCall.number;
  if (raw == null) return;
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return;
  final uri = Uri.parse(
    'https://wa.me/$digits${text == null ? '' : '?text=${Uri.encodeComponent(text)}'}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _openEmail() => launchUrl(Uri(scheme: 'mailto', path: _supportEmail));

const _questionKeys = [
  'auth.help_q1',
  'auth.help_q2',
  'auth.help_q3',
  'auth.help_q4',
];

class _LoginHelpSheet extends StatelessWidget {
  const _LoginHelpSheet();

  @override
  Widget build(BuildContext context) {
    final hasPhone = ContactCall.number != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: JV2.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'auth.help_title'.tr(),
                        style: JV2.display(context, 19),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'auth.help_sub'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: JV2.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CloseButton(onTap: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JV2.line),
              ),
              child: Column(
                children: [
                  _HelpRow(
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 19,
                      color: JV2.success,
                    ),
                    iconBg: const Color(0x18137A55),
                    title: 'auth.help_whatsapp_title'.tr(),
                    subtitle: 'auth.help_whatsapp_sub'.tr(),
                    onTap: () => _openWhatsapp(),
                  ),
                  if (hasPhone) ...[
                    const Divider(height: 1, color: JV2.line),
                    _HelpRow(
                      icon: const Icon(
                        Icons.call_outlined,
                        size: 19,
                        color: JV2.navy,
                      ),
                      iconBg: const Color(0x0F0B2A4A),
                      title: 'auth.help_call_title'.tr(),
                      subtitle: ContactCall.number!,
                      onTap: ContactCall.dial,
                    ),
                  ],
                  const Divider(height: 1, color: JV2.line),
                  _HelpRow(
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 19,
                      color: JV2.navy,
                    ),
                    iconBg: const Color(0x0F0B2A4A),
                    title: 'auth.help_email_title'.tr(),
                    subtitle: _supportEmail,
                    onTap: _openEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'auth.help_common_problems'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: JV2.inkSub,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in _questionKeys)
                  _QuestionChip(
                    label: k.tr(),
                    onTap: () => _openWhatsapp(text: k.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              'auth.help_hint'.tr(),
              style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JV2.fillFaint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(color: JV2.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.close_rounded, size: 16, color: JV2.ink),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final Widget icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: JV2.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: JV2.inkMute,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JV2.fillFaint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: JV2.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: JV2.ink,
            ),
          ),
        ),
      ),
    );
  }
}
