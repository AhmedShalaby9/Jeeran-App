import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/repositories/ai_ads_repository.dart';
import 'ai_ad_detail_page.dart';

/// Page for creating a new AI ad generation.
///
/// Flow:
///   1. User enters a caption.
///   2. Source image URLs are provided (upload beforehand).
///   3. POST /ai-ads/generate → returns { id, payment_url }.
///   4. App opens payment_url in external browser.
///   5. On return, user is taken to the detail page to poll for results.
class AiAdGeneratePage extends StatefulWidget {
  /// Pre-filled source image URLs (e.g. uploaded from the property form).
  final List<String> sourceImages;

  const AiAdGeneratePage({super.key, this.sourceImages = const []});

  static Future<void> push(
    BuildContext context, {
    List<String> sourceImages = const [],
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAdGeneratePage(sourceImages: sourceImages),
      ),
    );
  }

  @override
  State<AiAdGeneratePage> createState() => _AiAdGeneratePageState();
}

class _AiAdGeneratePageState extends State<AiAdGeneratePage> {
  final _captionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  // Image URLs entered manually (or injected from parent).
  late final List<String> _imageUrls;
  final _imageUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _imageUrls = List.of(widget.sourceImages);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      setState(() => _error = 'Add at least one source image URL.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<AiAdsRepository>().generate(
      caption: _captionCtrl.text.trim(),
      sourceImages: _imageUrls,
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
          // Replace this page with the detail/polling page.
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

  void _addImageUrl() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _imageUrls.add(url);
      _imageUrlCtrl.clear();
    });
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
                      'Our AI will generate a professional ad image based on your property photos and caption.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.onBackground),
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
              'Source Image URLs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Paste the URL of an uploaded property image.',
              style: TextStyle(fontSize: 12, color: AppColors.inkSub),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.grey.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addImageUrl,
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  iconSize: 32,
                ),
              ],
            ),
            if (_imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _imageUrls.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(
                      'Image ${entry.key + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        setState(() => _imageUrls.removeAt(entry.key)),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                    deleteIconColor: AppColors.inkSub,
                  );
                }).toList(),
              ),
            ],

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
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
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
