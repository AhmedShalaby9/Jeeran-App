import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  static const int _maxPhotos = 20;
  final _picker = ImagePicker();

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - widget.form.selectedImages.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
    if (picked.isEmpty) return;
    setState(() {
      widget.form.selectedImages.addAll(picked);
      widget.onChanged();
    });
  }

  void _removePhoto(int index) {
    setState(() {
      widget.form.selectedImages.removeAt(index);
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.form.selectedImages;
    final count = images.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepTitle(
          'Photos & description',
          subtitle: 'Great photos get 3× more enquiries.',
        ),

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
          itemCount: count + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return _AddPhotoTile(onTap: _addPhotos);
            }
            final file = images[i - 1];
            return _PhotoTile(
              filePath: file.path,
              isCover: i == 1,
              onRemove: () => _removePhoto(i - 1),
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Title (Arabic) ────────────────────────────────────────
        const WizardLabel('Title (Arabic)', required: true),
        WizardInput(
          placeholder: 'عنوان العقار بالعربية',
          value: widget.form.titleAr,
          textDirection: TextDirection.rtl,
          onChanged: (v) {
            widget.form.titleAr = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Title (English) ───────────────────────────────────────
        const WizardLabel('Title (English)', required: true),
        WizardInput(
          placeholder: 'Property title in English',
          value: widget.form.titleEn,
          onChanged: (v) {
            widget.form.titleEn = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Description (Arabic) ──────────────────────────────────
        const WizardLabel('Description (Arabic)', required: true),
        WizardTextArea(
          placeholder: 'وصف العقار بالعربية',
          value: widget.form.contentAr,
          textDirection: TextDirection.rtl,
          onChanged: (v) {
            widget.form.contentAr = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Description (English) ─────────────────────────────────
        const WizardLabel('Description (English)', required: true),
        WizardTextArea(
          placeholder: 'Describe the property — views, finishes, nearby landmarks…',
          value: widget.form.contentEn,
          onChanged: (v) {
            widget.form.contentEn = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Video URL (optional) ──────────────────────────────────
        const WizardLabel('Video URL'),
        WizardInput(
          placeholder: 'https://youtube.com/... (optional)',
          value: widget.form.videoUrl ?? '',
          keyboardType: TextInputType.url,
          onChanged: (v) {
            widget.form.videoUrl = v.trim().isEmpty ? null : v.trim();
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
  final String filePath;
  final bool isCover;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.filePath,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
        ),
      ),
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
            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}
