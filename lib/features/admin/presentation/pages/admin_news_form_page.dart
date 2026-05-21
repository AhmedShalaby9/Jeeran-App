import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../news/domain/entities/news.dart';
import '../../../news/presentation/bloc/news_bloc.dart';
import '../../../news/presentation/bloc/news_event.dart';
import '../../../news/presentation/bloc/news_state.dart';

class AdminNewsFormPage extends StatefulWidget {
  final News? news; // null = create mode

  const AdminNewsFormPage({super.key, this.news});

  @override
  State<AdminNewsFormPage> createState() => _AdminNewsFormPageState();
}

class _AdminNewsFormPageState extends State<AdminNewsFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleArCtrl;
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _contentArCtrl;
  late final TextEditingController _contentEnCtrl;
  late bool _isActive;

  // Translation
  final _translator = GoogleTranslator();
  bool _translatingTitleAr = false;
  bool _translatingTitleEn = false;
  bool _translatingContentAr = false;
  bool _translatingContentEn = false;

  // Media management
  late List<String> _existingMediaUrls;
  final List<XFile> _newMediaFiles = [];
  final _picker = ImagePicker();

  bool get _isEditing => widget.news != null;

  @override
  void initState() {
    super.initState();
    _titleArCtrl = TextEditingController(text: widget.news?.title ?? '');
    _titleEnCtrl = TextEditingController();
    _contentArCtrl = TextEditingController(text: widget.news?.content ?? '');
    _contentEnCtrl = TextEditingController();
    _isActive = widget.news?.isActive ?? true;
    _existingMediaUrls = List<String>.from(widget.news?.media ?? []);
  }

  @override
  void dispose() {
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _contentArCtrl.dispose();
    _contentEnCtrl.dispose();
    super.dispose();
  }

  // ── Translation ───────────────────────────────────────────────────────────

  Future<void> _translate({
    required TextEditingController source,
    required TextEditingController target,
    required String targetLang,
    required void Function(bool) setLoading,
  }) async {
    if (source.text.trim().isEmpty) return;
    setState(() => setLoading(true));
    try {
      final result = await _translator.translate(source.text.trim(), to: targetLang);
      if (!mounted) return;
      setState(() => target.text = result.text);
    } catch (_) {
      // silent fail — user can tap again
    } finally {
      if (mounted) setState(() => setLoading(false));
    }
  }

  // ── Media picking ─────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) setState(() => _newMediaFiles.addAll(picked));
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _newMediaFiles.add(picked));
  }

  void _showMediaSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('admin.pick_images'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.videocam_outlined, color: AppColors.primary),
              title: Text('admin.pick_video'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<NewsBloc>();
    if (_isEditing) {
      bloc.add(UpdateNewsEvent(
        id: widget.news!.id,
        titleAr: _titleArCtrl.text.trim(),
        titleEn: _titleEnCtrl.text.trim().isEmpty ? null : _titleEnCtrl.text.trim(),
        contentAr: _contentArCtrl.text.trim(),
        contentEn: _contentEnCtrl.text.trim().isEmpty ? null : _contentEnCtrl.text.trim(),
        isActive: _isActive,
        existingMediaUrls: _existingMediaUrls,
        newMedia: _newMediaFiles,
      ));
    } else {
      bloc.add(CreateNewsEvent(
        titleAr: _titleArCtrl.text.trim(),
        titleEn: _titleEnCtrl.text.trim().isEmpty ? null : _titleEnCtrl.text.trim(),
        contentAr: _contentArCtrl.text.trim(),
        contentEn: _contentEnCtrl.text.trim().isEmpty ? null : _contentEnCtrl.text.trim(),
        isActive: _isActive,
        newMedia: _newMediaFiles,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewsBloc, NewsState>(
      listener: (context, state) {
        if (state is NewsActionSuccess) {
          Navigator.pop(context, true);
        } else if (state is NewsActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _isEditing ? 'admin.edit_news'.tr() : 'admin.add_news'.tr(),
          ),
        ),
        body: BlocBuilder<NewsBloc, NewsState>(
          builder: (context, state) {
            final isUploading = state is NewsUploading;
            final isLoading = state is NewsLoading || isUploading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title Arabic ──────────────────────────────────
                    _TranslateLabel(
                      label: 'admin.title_ar'.tr(),
                      required: true,
                      buttonLabel: 'Translate from English',
                      enabled: _titleEnCtrl.text.trim().isNotEmpty,
                      translating: _translatingTitleAr,
                      onTranslate: () => _translate(
                        source: _titleEnCtrl,
                        target: _titleArCtrl,
                        targetLang: 'ar',
                        setLoading: (v) => _translatingTitleAr = v,
                      ),
                    ),
                    _buildField(
                      controller: _titleArCtrl,
                      required: true,
                      maxLines: 1,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // ── Title English ─────────────────────────────────
                    _TranslateLabel(
                      label: 'admin.title_en'.tr(),
                      buttonLabel: 'Translate from Arabic',
                      enabled: _titleArCtrl.text.trim().isNotEmpty,
                      translating: _translatingTitleEn,
                      onTranslate: () => _translate(
                        source: _titleArCtrl,
                        target: _titleEnCtrl,
                        targetLang: 'en',
                        setLoading: (v) => _translatingTitleEn = v,
                      ),
                    ),
                    _buildField(
                      controller: _titleEnCtrl,
                      maxLines: 1,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // ── Content Arabic ────────────────────────────────
                    _TranslateLabel(
                      label: 'admin.content_ar'.tr(),
                      required: true,
                      buttonLabel: 'Translate from English',
                      enabled: _contentEnCtrl.text.trim().isNotEmpty,
                      translating: _translatingContentAr,
                      onTranslate: () => _translate(
                        source: _contentEnCtrl,
                        target: _contentArCtrl,
                        targetLang: 'ar',
                        setLoading: (v) => _translatingContentAr = v,
                      ),
                    ),
                    _buildField(
                      controller: _contentArCtrl,
                      required: true,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // ── Content English ───────────────────────────────
                    _TranslateLabel(
                      label: 'admin.content_en'.tr(),
                      buttonLabel: 'Translate from Arabic',
                      enabled: _contentArCtrl.text.trim().isNotEmpty,
                      translating: _translatingContentEn,
                      onTranslate: () => _translate(
                        source: _contentArCtrl,
                        target: _contentEnCtrl,
                        targetLang: 'en',
                        setLoading: (v) => _translatingContentEn = v,
                      ),
                    ),
                    _buildField(
                      controller: _contentEnCtrl,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // ── Media section ─────────────────────────────────
                    _MediaSection(
                      existingUrls: _existingMediaUrls,
                      newFiles: _newMediaFiles,
                      onRemoveExisting: (i) =>
                          setState(() => _existingMediaUrls.removeAt(i)),
                      onRemoveNew: (i) =>
                          setState(() => _newMediaFiles.removeAt(i)),
                      onAddMedia: _showMediaSourceSheet,
                    ),
                    const SizedBox(height: 16),

                    // ── Active toggle ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text('admin.active'.tr()),
                        value: _isActive,
                        activeColor: AppColors.success,
                        onChanged:
                            isLoading ? null : (v) => setState(() => _isActive = v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Upload progress ───────────────────────────────
                    if (isUploading) ...[
                      LinearProgressIndicator(
                        value: (state as NewsUploading).current / state.total,
                        color: AppColors.primary,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'admin.upload_progress'.tr(namedArgs: {
                          'current': '${state.current}',
                          'total': '${state.total}',
                        }),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkMute),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Submit button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing
                                    ? 'admin.save_changes'.tr()
                                    : 'admin.add_news'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null
          : null,
    );
  }
}

// ── Translate label row ───────────────────────────────────────────────────────

class _TranslateLabel extends StatelessWidget {
  final String label;
  final bool required;
  final String buttonLabel;
  final bool enabled;
  final bool translating;
  final VoidCallback onTranslate;

  const _TranslateLabel({
    required this.label,
    this.required = false,
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
                        color: AppColors.secondary,
                      ),
                    )
                  else
                    const Icon(Icons.translate_rounded,
                        size: 13, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
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

// ── Media section ─────────────────────────────────────────────────────────────

class _MediaSection extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newFiles;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;
  final VoidCallback onAddMedia;

  const _MediaSection({
    required this.existingUrls,
    required this.newFiles,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAddMedia,
  });

  static bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = existingUrls.isNotEmpty || newFiles.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.perm_media_outlined,
                  size: 18, color: AppColors.inkMute),
              const SizedBox(width: 8),
              Text(
                'admin.media'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${existingUrls.length + newFiles.length} ${'admin.files'.tr()}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.inkMute),
              ),
            ],
          ),
          if (hasMedia) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < existingUrls.length; i++)
                  _MediaThumbNetwork(
                    url: existingUrls[i],
                    isVideo: _isVideo(existingUrls[i]),
                    onRemove: () => onRemoveExisting(i),
                  ),
                for (int i = 0; i < newFiles.length; i++)
                  _MediaThumbFile(
                    file: newFiles[i],
                    isVideo: _isVideo(newFiles[i].path),
                    onRemove: () => onRemoveNew(i),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddMedia,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text('admin.add_media'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumbNetwork extends StatelessWidget {
  final String url;
  final bool isVideo;
  final VoidCallback onRemove;

  const _MediaThumbNetwork(
      {required this.url, required this.isVideo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  width: 80,
                  height: 80,
                  color: AppColors.ink,
                  child: const Icon(Icons.videocam, color: Colors.white, size: 32),
                )
              : Image.network(
                  url,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.tagPrimaryBg,
                    child: const Icon(Icons.broken_image, color: AppColors.inkMute),
                  ),
                ),
        ),
        if (isVideo)
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaThumbFile extends StatelessWidget {
  final XFile file;
  final bool isVideo;
  final VoidCallback onRemove;

  const _MediaThumbFile(
      {required this.file, required this.isVideo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  width: 80,
                  height: 80,
                  color: AppColors.ink,
                  child: const Icon(Icons.videocam, color: Colors.white, size: 32),
                )
              : Image.file(
                  File(file.path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.tagPrimaryBg,
                    child: const Icon(Icons.broken_image, color: AppColors.inkMute),
                  ),
                ),
        ),
        if (isVideo)
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
