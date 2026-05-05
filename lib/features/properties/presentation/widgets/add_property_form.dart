import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/enums/property_enums.dart';

// ─────────────────────────────────────────────────────────────
//  Mutable form data — passed by reference to every step widget
// ─────────────────────────────────────────────────────────────

class AddPropertyForm {
  PropertyType? propertyType;
  PropertyStatus? propertyStatus;
  PropertyState? location; // which state/city (avoids name clash with Flutter State)
  int? projectId;
  String projectTitle = '';

  String price = '';
  String size = '';
  int bedrooms = 1;
  int bathrooms = 1;

  String titleAr = '';
  String titleEn = '';
  String contentAr = '';
  String contentEn = '';
  List<XFile> selectedImages = [];

  String? videoUrl;

  String agentName = '';
  String agentMobile = '';
  String agentWhatsapp = '';
  String agentEmail = '';

  // ── Per-step validation ──────────────────────────────────────
  bool get step1Valid => propertyType != null && propertyStatus != null;
  bool get step2Valid => location != null && projectId != null;
  bool get step3Valid =>
      price.trim().isNotEmpty &&
      double.tryParse(price.replaceAll(',', '')) != null &&
      size.trim().isNotEmpty &&
      double.tryParse(size) != null;
  bool get step4Valid =>
      selectedImages.isNotEmpty &&
      titleAr.trim().isNotEmpty &&
      titleEn.trim().isNotEmpty &&
      contentAr.trim().isNotEmpty &&
      contentEn.trim().isNotEmpty;
  bool get step5Valid =>
      agentName.trim().isNotEmpty && agentMobile.trim().isNotEmpty;

  bool isStepValid(int step) => switch (step) {
        1 => step1Valid,
        2 => step2Valid,
        3 => step3Valid,
        4 => step4Valid,
        _ => step5Valid,
      };

  Map<String, dynamic> toBody(List<String> imageUrls) => {
        'title_ar': titleAr.trim(),
        'title_en': titleEn.trim(),
        'content_ar': contentAr.trim(),
        'content_en': contentEn.trim(),
        'property_type': propertyType!.apiKey,
        'property_status': propertyStatus!.apiKey,
        'price': double.parse(price.replaceAll(',', '')),
        'size': double.parse(size),
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'country': 'egypt',
        'state': location!.apiKey,
        'project_id': projectId,
        'images': imageUrls,
        'agent_name': agentName.trim(),
        'agent_mobile': agentMobile.trim(),
        'agent_whatsapp': agentWhatsapp.trim().isNotEmpty
            ? agentWhatsapp.trim()
            : agentMobile.trim(),
        'agent_email': agentEmail.trim(),
        if (videoUrl != null && videoUrl!.trim().isNotEmpty)
          'video_url': videoUrl!.trim(),
      };
}

// ─────────────────────────────────────────────────────────────
//  Shared wizard UI widgets
// ─────────────────────────────────────────────────────────────

/// Field label with optional required asterisk.
class WizardLabel extends StatelessWidget {
  final String text;
  final bool required;
  const WizardLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: 0.1,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
              ]
            : null,
      ),
    ),
  );
}

/// Standard wizard text input field.
class WizardInput extends StatelessWidget {
  final String placeholder;
  final String value;
  final String? suffix;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final TextDirection? textDirection;

  const WizardInput({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(fontSize: 15, color: AppColors.inkMute),
        suffixText: suffix,
        suffixStyle: const TextStyle(fontSize: 14, color: AppColors.inkSub),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Multi-line textarea.
class WizardTextArea extends StatelessWidget {
  final String placeholder;
  final String value;
  final int rows;
  final ValueChanged<String> onChanged;
  final TextDirection? textDirection;

  const WizardTextArea({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.rows = 5,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: rows,
      textDirection: textDirection,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(fontSize: 15, color: AppColors.inkMute),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Pill-shaped selection chip.
class WizardChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const WizardChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.hairline,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}

/// +/- stepper counter.
class WizardCounter extends StatelessWidget {
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  const WizardCounter({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterBtn(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        _CounterBtn(
          icon: Icons.add,
          enabled: true,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CounterBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.10)
            : const Color(0xFFF2F4F7),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled ? AppColors.primary : AppColors.inkMute,
      ),
    ),
  );
}

/// Section heading used across all steps.
class WizardStepTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const WizardStepTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSub),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Row divider for counter fields.
class WizardCounterRow extends StatelessWidget {
  final String label;
  final String? hint;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  const WizardCounterRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.min = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMute),
                  ),
                ],
              ],
            ),
          ),
          WizardCounter(value: value, min: min, onChanged: onChanged),
        ],
      ),
    );
  }
}
