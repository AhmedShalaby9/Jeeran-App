import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/repositories/property_repository.dart';
import '../../domain/repositories/ai_ads_repository.dart';
import 'ai_ad_detail_page.dart';

class AiAdGeneratePage extends StatefulWidget {
  const AiAdGeneratePage({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiAdGeneratePage()),
    );
  }

  @override
  State<AiAdGeneratePage> createState() => _AiAdGeneratePageState();
}

class _AiAdGeneratePageState extends State<AiAdGeneratePage> {
  final _captionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  static const int _maxImages = 5;

  bool _isLoading = false;
  String? _error;
  final List<XFile> _pickedImages = [];

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final remaining = _maxImages - _pickedImages.length;
    if (remaining <= 0) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _pickedImages.add(file));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImages.isEmpty) {
      setState(() => _error = 'Please add at least one source image.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Upload all images in parallel.
    final uploadFutures = _pickedImages
        .map((f) => sl<PropertyRepository>().uploadImage(f.path))
        .toList();
    final uploadResults = await Future.wait(uploadFutures);

    if (!mounted) return;

    final imageUrls = <String>[];
    for (final result in uploadResults) {
      result.fold((_) => null, (url) => imageUrls.add(url));
    }

    if (imageUrls.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to upload images. Please try again.';
      });
      return;
    }

    final result = await sl<AiAdsRepository>().generate(
      caption: _captionCtrl.text.trim(),
      sourceImages: imageUrls,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          final msg = (failure as dynamic).message as String? ?? '';
          _error = msg.isNotEmpty ? msg : 'Generation failed. Please try again.';
        });
      },
      (data) async {
        final adId = data['id'] as int?;
        final paymentUrl = data['payment_url'] as String?;

        setState(() => _isLoading = false);

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        if (!mounted) return;

        if (adId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AiAdDetailPage(adId: adId),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Generate AI Ad')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Our AI will generate a professional ad image based on your property photo and caption.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.onBackground),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Caption
            const Text(
              'Caption / Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _captionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Describe the ad you want — location, highlights, target audience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Caption is required' : null,
            ),

            const SizedBox(height: 24),

            // Source Images
            const Text(
              'Source Images',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload 1–5 property photos. The AI will use them all as reference.',
              style: TextStyle(fontSize: 12, color: AppColors.inkSub),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _pickedImages.length < _maxImages
                  ? _pickedImages.length + 1
                  : _pickedImages.length,
              itemBuilder: (_, i) {
                if (i == _pickedImages.length) {
                  return _AddPhotoTile(onTap: _pickImage);
                }
                return _PhotoTile(
                  filePath: _pickedImages[i].path,
                  onRemove: () => setState(() => _pickedImages.removeAt(i)),
                );
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Generate & Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              'You will be redirected to a secure payment page. After payment the ad will start generating automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.inkSub),
            ),
          ],
        ),
      ),
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
                Icons.add_photo_alternate_rounded,
                size: 28,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 6),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 11,
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
  final VoidCallback onRemove;

  const _PhotoTile({required this.filePath, required this.onRemove});

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
