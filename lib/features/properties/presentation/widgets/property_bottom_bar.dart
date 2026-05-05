import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import 'property_widgets.dart';

class PropertyBottomBar extends StatelessWidget {
  final Property property;
  final bool saved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;

  const PropertyBottomBar({
    super.key,
    required this.property,
    required this.saved,
    required this.onToggleSave,
    required this.onShare,
  });

  Future<void> _call() async {
    final number = property.agentMobile;
    if (number == null || number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final number = property.agentWhatsapp;
    if (number == null || number.isEmpty) return;
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      child: Row(
        children: [
          SquareButton(
            onTap: onToggleSave,
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: saved ? AppColors.dangerPink : AppColors.inkSub,
            ),
          ),
          const SizedBox(width: 8),
          SquareButton(
            onTap: onShare,
            child: const Icon(Icons.share_rounded, size: 18, color: AppColors.inkSub),
          ),
          const SizedBox(width: 8),
          if (property.agentWhatsapp?.isNotEmpty == true) ...[
            Expanded(
              child: CTAButton(
                label: 'WhatsApp',
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                color: AppColors.whatsapp,
                onTap: _whatsapp,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: CTAButton(
              label: 'Call',
              icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
              color: AppColors.primary,
              onTap: _call,
            ),
          ),
        ],
      ),
    );
  }
}
