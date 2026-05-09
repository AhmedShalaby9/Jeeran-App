import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
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
  static const int _maxVideoMb = 50;
  final _picker = ImagePicker();
  final _translator = GoogleTranslator();

  late final TextEditingController _arDescCtrl;
  late final TextEditingController _enDescCtrl;

  bool _translatingAr = false;
  bool _translatingEn = false;

  @override
  void initState() {
    super.initState();
    _arDescCtrl = TextEditingController(text: widget.form.contentAr);
    _enDescCtrl = TextEditingController(text: widget.form.contentEn);
  }

  @override
  void dispose() {
    _arDescCtrl.dispose();
    _enDescCtrl.dispose();
    super.dispose();
  }

  // ── Photos ─────────────────────────────────────────────────────

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - widget.form.selectedImages.length;
    if (remaining <= 0) return;
    final picked =
        await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
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

  // ── Translation ────────────────────────────────────────────────

  Future<void> _translateTo(String targetLang) async {
    final src =
        targetLang == 'en' ? widget.form.contentAr : widget.form.contentEn;
    if (src.trim().isEmpty) return;
    setState(() =>
        targetLang == 'en' ? _translatingEn = true : _translatingAr = true);
    try {
      final result = await _translator.translate(src, to: targetLang);
      if (!mounted) return;
      setState(() {
        if (targetLang == 'en') {
          widget.form.contentEn = result.text;
          _enDescCtrl.text = result.text;
        } else {
          widget.form.contentAr = result.text;
          _arDescCtrl.text = result.text;
        }
        widget.onChanged();
      });
    } catch (_) {
      // silent fail — user can retry by tapping the button again
    } finally {
      if (mounted) {
        setState(() => targetLang == 'en'
            ? _translatingEn = false
            : _translatingAr = false);
      }
    }
  }

  // ── Video ───────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await File(file.path).length();
    final mb = bytes / (1024 * 1024);
    if (!mounted) return;
    if (mb > _maxVideoMb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Video is too large (${mb.toStringAsFixed(1)} MB). Max $_maxVideoMb MB.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() {
      widget.form.videoFile = file;
      widget.onChanged();
    });
  }

  void _clearVideo() {
    setState(() {
      widget.form.videoFile = null;
      widget.onChanged();
    });
  }

  // ── Build ───────────────────────────────────────────────────────

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

        // ── Photo grid ─────────────────────────────────────────────
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
            if (i == 0) return _AddPhotoTile(onTap: _addPhotos);
            final file = images[i - 1];
            return _PhotoTile(
              filePath: file.path,
              isCover: i == 1,
              onRemove: () => _removePhoto(i - 1),
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Title (Arabic) ─────────────────────────────────────────
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

        // ── Title (English) ────────────────────────────────────────
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

        // ── Description (Arabic) ───────────────────────────────────
        _DescLabelRow(
          label: 'Description (Arabic)',
          required: true,
          buttonLabel: 'Translate from English',
          enabled: widget.form.contentEn.trim().isNotEmpty,
          translating: _translatingAr,
          onTranslate: () => _translateTo('ar'),
        ),
        WizardTextArea(
          placeholder: 'وصف العقار بالعربية',
          value: widget.form.contentAr,
          textDirection: TextDirection.rtl,
          controller: _arDescCtrl,
          onChanged: (v) {
            widget.form.contentAr = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Description (English) ──────────────────────────────────
        _DescLabelRow(
          label: 'Description (English)',
          required: true,
          buttonLabel: 'Translate from Arabic',
          enabled: widget.form.contentAr.trim().isNotEmpty,
          translating: _translatingEn,
          onTranslate: () => _translateTo('en'),
        ),
        WizardTextArea(
          placeholder: 'Describe the property — views, finishes, nearby landmarks…',
          value: widget.form.contentEn,
          controller: _enDescCtrl,
          onChanged: (v) {
            widget.form.contentEn = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Video ──────────────────────────────────────────────────
        const WizardLabel('Video (optional)'),
        _VideoPickerTile(
          file: widget.form.videoFile,
          onPick: _pickVideo,
          onClear: _clearVideo,
        ),
      ],
    );
  }
}

// ── Description label row with translate button ───────────────────

class _DescLabelRow extends StatelessWidget {
  final String label;
  final bool required;
  final String buttonLabel;
  final bool enabled;
  final bool translating;
  final VoidCallback onTranslate;

  const _DescLabelRow({
    required this.label,
    required this.required,
    required this.buttonLabel,
    required this.enabled,
    required this.translating,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              text: label,
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
          const Spacer(),
          GestureDetector(
            onTap: enabled && !translating ? onTranslate : null,
            child: AnimatedOpacity(
              opacity: enabled && !translating ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (translating)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(Icons.translate_rounded,
                        size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video picker tile ─────────────────────────────────────────────

class _VideoPickerTile extends StatelessWidget {
  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _VideoPickerTile({
    required this.file,
    required this.onPick,
    required this.onClear,
  });

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: file == null ? onPick : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
            ),
            child: file == null
                ? Row(
                    children: [
                      const Icon(Icons.video_file_outlined,
                          size: 20, color: AppColors.inkMute),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Select a video from your gallery',
                          style: TextStyle(
                              fontSize: 15, color: AppColors.inkMute),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: AppColors.inkMute),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              _formatSize(File(file!.path).lengthSync()),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.inkSub),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.inkMute),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Max file size: 50 MB',
          style: TextStyle(fontSize: 12, color: AppColors.inkSub),
        ),
      ],
    );
  }
}

// ── Photo tiles ───────────────────────────────────────────────────

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                child: const Icon(Icons.close_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      );
}
