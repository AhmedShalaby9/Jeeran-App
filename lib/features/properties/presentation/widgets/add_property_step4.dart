import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'add_property_form.dart';

class AddPropertyStep4 extends StatefulWidget {
  final AddPropertyForm form;
  final VoidCallback onChanged;

  const AddPropertyStep4({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  State<AddPropertyStep4> createState() => _AddPropertyStep4State();
}

class _AddPropertyStep4State extends State<AddPropertyStep4> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  static const int _maxPhotos = 20;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.form.title);
    _descCtrl = TextEditingController(text: widget.form.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addPhoto() {
    // TODO: integrate image_picker
    //   1. Add `image_picker: ^1.1.2` to pubspec.yaml
    //   2. Replace photoCount with List<XFile> photos
    //   3. final picker = ImagePicker();
    //      final picked = await picker.pickMultiImage(imageQuality: 80);
    //      setState(() { widget.form.photos.addAll(picked); });
    if (widget.form.photoCount >= _maxPhotos) return;
    setState(() {
      widget.form.photoCount++;
      widget.onChanged();
    });
  }

  void _removePhoto(int index) {
    setState(() {
      if (widget.form.photoCount > 0) widget.form.photoCount--;
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.form.photoCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos & description',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Great photos get 3× more views.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSub, height: 1.4),
        ),
        const SizedBox(height: 24),

        // ── Photo grid ───────────────────────────────────────────
        WizardLabel('Photos ($count/$_maxPhotos)', required: true),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: count + 1, // +1 for the Add button
          itemBuilder: (_, i) {
            if (i == 0) return _AddPhotoTile(onTap: _addPhoto);
            return _PhotoTile(
              index: i - 1,
              isCover: i == 1,
              onRemove: () => _removePhoto(i - 1),
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Title ────────────────────────────────────────────────
        const WizardLabel('Listing title', required: true),
        _BorderedInput(
          controller: _titleCtrl,
          hint: 'e.g. Spacious 3BR apartment with balcony',
          onChanged: (v) {
            widget.form.title = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 16),

        // ── Description ─────────────────────────────────────────
        const WizardLabel('Description', required: true),
        _BorderedTextArea(
          controller: _descCtrl,
          hint: 'Highlight the view, finishes, nearby landmarks…',
          onChanged: (v) {
            widget.form.description = v;
            widget.onChanged();
          },
        ),
      ],
    );
  }
}

// ── Photo tiles ───────────────────────────────────────────────

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_rounded,
            size: 24,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 6),
          Text(
            'Add',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  final int index;
  final bool isCover;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.index,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // Placeholder image (checkerboard pattern)
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(painter: _CheckerPainter()),
      ),
      // Cover badge
      if (isCover)
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'COVER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      // Remove button
      Positioned(
        top: 4,
        right: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xCC000000),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 14.0;
    final light = Paint()..color = const Color(0xFFD7DDE5);
    final dark = Paint()..color = const Color(0xFFCDD4DD);
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isDark = ((x / tileSize).floor() + (y / tileSize).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          isDark ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Shared input widgets for this step ────────────────────────

class _BorderedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _BorderedInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
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

class _BorderedTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _BorderedTextArea({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.hairline),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 6,
      style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.5),
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
