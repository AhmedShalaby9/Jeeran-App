import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'add_property_form.dart';

class AddPropertyStep2 extends StatefulWidget {
  final AddPropertyForm form;
  final VoidCallback onChanged;

  const AddPropertyStep2({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  State<AddPropertyStep2> createState() => _AddPropertyStep2State();
}

class _AddPropertyStep2State extends State<AddPropertyStep2> {
  late final TextEditingController _cityCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _streetCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.form.city);
    _areaCtrl = TextEditingController(text: widget.form.area);
    _streetCtrl = TextEditingController(text: widget.form.street);
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.form.city = _cityCtrl.text;
    widget.form.area = _areaCtrl.text;
    widget.form.street = _streetCtrl.text;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where is it?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add the location details for the listing.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSub, height: 1.4),
        ),
        const SizedBox(height: 24),

        // ── Map placeholder ──────────────────────────────────────
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // fake map grid
              CustomPaint(painter: _MapGridPainter()),
              // pin
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              // "Tap to pick" label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white.withValues(alpha: 0.85),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: AppColors.inkSub,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Map integration — wire up when ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── City ─────────────────────────────────────────────────
        const WizardLabel('City', required: true),
        _StyledInput(
          controller: _cityCtrl,
          hint: 'e.g. Cairo',
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 16),

        // ── Neighborhood ─────────────────────────────────────────
        const WizardLabel('Neighborhood / Area', required: true),
        _StyledInput(
          controller: _areaCtrl,
          hint: 'e.g. New Cairo',
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 16),

        // ── Street ───────────────────────────────────────────────
        const WizardLabel('Street address'),
        _StyledInput(
          controller: _streetCtrl,
          hint: 'Building, street name (optional)',
          onChanged: (_) => _sync(),
        ),
      ],
    );
  }
}

// ── Shared input with controller ─────────────────────────────

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _StyledInput({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.hairline),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 15, color: AppColors.inkMute),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ),
  );
}

// ── Fake map grid painter ─────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0DBE8)
      ..strokeWidth = 1;

    // horizontal roads
    for (double y = 40; y < size.height; y += 45) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // vertical roads
    for (double x = 60; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // slightly thicker "main road"
    final main = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.45),
      main,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.40, size.height),
      main,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
