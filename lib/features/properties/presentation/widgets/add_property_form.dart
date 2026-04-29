import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  Mutable form data — passed by reference to every step widget
// ─────────────────────────────────────────────────────────────

class AddPropertyForm {
  String purpose = 'For Sale'; // 'For Sale' | 'For Rent'
  String propertyType = 'apartment';
  String city = '';
  String area = '';
  String street = '';
  String price = '';
  String size = '';
  int bedrooms = 1;
  int bathrooms = 1;
  int parkingSpots = 0;
  String? furnishing; // 'Unfurnished' | 'Semi-furnished' | 'Furnished'
  /// Placeholder photo count — replace with List<XFile> once
  /// image_picker is added to pubspec.yaml.
  int photoCount = 0;
  String title = '';
  String description = '';

  // ── Per-step validation ──────────────────────────────────────
  bool get step1Valid => propertyType.isNotEmpty;
  bool get step2Valid => city.trim().isNotEmpty && area.trim().isNotEmpty;
  bool get step3Valid =>
      price.trim().isNotEmpty && double.tryParse(price) != null;
  bool get step4Valid =>
      photoCount > 0 &&
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty;
  bool get step5Valid => true;

  bool isStepValid(int step) => switch (step) {
        1 => step1Valid,
        2 => step2Valid,
        3 => step3Valid,
        4 => step4Valid,
        _ => step5Valid,
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

  const WizardInput({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: AppColors.inkMute,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            Text(
              suffix!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSub,
              ),
            ),
          ],
        ],
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

  const WizardTextArea({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.rows = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        maxLines: rows,
        style: const TextStyle(fontSize: 15, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(fontSize: 15, color: AppColors.inkMute),
          border: InputBorder.none,
          isDense: true,
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
