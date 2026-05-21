import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/enums/property_enums.dart';
import '../../../properties/presentation/bloc/add_property_bloc.dart';
import '../../../properties/presentation/bloc/add_property_event.dart';
import '../../../properties/presentation/bloc/add_property_state.dart';
import '../../../properties/presentation/widgets/add_property_form.dart';

class AdminPropertyEditPage extends StatefulWidget {
  final Property property;

  const AdminPropertyEditPage({super.key, required this.property});

  @override
  State<AdminPropertyEditPage> createState() => _AdminPropertyEditPageState();
}

class _AdminPropertyEditPageState extends State<AdminPropertyEditPage> {
  // ── Form state ──────────────────────────────────────────────────────────────
  late PropertyType? _propertyType;
  late PropertyStatus? _propertyStatus;
  late PropertyState? _propertyState;
  late bool _isActive;
  late bool _isFeatured;

  late final TextEditingController _titleArCtrl;
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _contentArCtrl;
  late final TextEditingController _contentEnCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _sizeCtrl;
  late int _bedrooms;
  late int _bathrooms;

  late List<String> _existingImages; // server URLs to keep
  final List<XFile> _newImages = [];  // newly picked files

  late final TextEditingController _agentNameCtrl;
  late final TextEditingController _agentMobileCtrl;
  late final TextEditingController _agentWhatsappCtrl;
  late final TextEditingController _agentEmailCtrl;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _propertyType = PropertyType.fromKey(p.propertyType);
    _propertyStatus = PropertyStatus.fromKey(p.propertyStatus);
    _propertyState = PropertyState.fromKey(p.state);
    _isActive = p.isActive;
    _isFeatured = p.isFeatured;

    _titleArCtrl = TextEditingController(text: p.titleAr);
    _titleEnCtrl = TextEditingController(text: p.titleEn);
    _contentArCtrl = TextEditingController(text: p.contentAr ?? '');
    _contentEnCtrl = TextEditingController(text: p.contentEn ?? '');
    _priceCtrl = TextEditingController(text: p.price ?? '');
    _sizeCtrl = TextEditingController(text: p.size ?? '');
    _bedrooms = p.bedrooms ?? 1;
    _bathrooms = p.bathrooms ?? 1;

    _existingImages = List<String>.from(p.images);

    _agentNameCtrl = TextEditingController(text: p.agentName ?? '');
    _agentMobileCtrl = TextEditingController(text: p.agentMobile ?? '');
    _agentWhatsappCtrl = TextEditingController(text: p.agentWhatsapp ?? '');
    _agentEmailCtrl = TextEditingController(text: p.agentEmail ?? '');
  }

  @override
  void dispose() {
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _contentArCtrl.dispose();
    _contentEnCtrl.dispose();
    _priceCtrl.dispose();
    _sizeCtrl.dispose();
    _agentNameCtrl.dispose();
    _agentMobileCtrl.dispose();
    _agentWhatsappCtrl.dispose();
    _agentEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked));
    }
  }

  void _removeExisting(int index) {
    setState(() => _existingImages.removeAt(index));
  }

  void _removeNew(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _submit() {
    final body = <String, dynamic>{
      'title_ar': _titleArCtrl.text.trim(),
      'title_en': _titleEnCtrl.text.trim(),
      'content_ar': _contentArCtrl.text.trim(),
      'content_en': _contentEnCtrl.text.trim(),
      if (_propertyType != null) 'property_type': _propertyType!.apiKey,
      if (_propertyStatus != null) 'property_status': _propertyStatus!.apiKey,
      if (_propertyState != null) 'state': _propertyState!.apiKey,
      'is_active': _isActive,
      'is_featured': _isFeatured,
      if (_priceCtrl.text.isNotEmpty)
        'price': double.tryParse(_priceCtrl.text.replaceAll(',', '')),
      if (_sizeCtrl.text.isNotEmpty) 'size': double.tryParse(_sizeCtrl.text),
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'agent_name': _agentNameCtrl.text.trim(),
      'agent_mobile': _agentMobileCtrl.text.trim(),
      'agent_whatsapp': _agentWhatsappCtrl.text.trim(),
      'agent_email': _agentEmailCtrl.text.trim(),
    };

    context.read<AddPropertyBloc>().add(
          SubmitUpdateProperty(
            propertyId: widget.property.id,
            existingImageUrls: _existingImages,
            newImages: _newImages,
            body: body,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPropertyBloc, AddPropertyState>(
      listener: (context, state) {
        if (state is AddPropertySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin.action_success'.tr())),
          );
          Navigator.pop(context, true);
        } else if (state is AddPropertyFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('admin.edit_property'.tr())),
        body: BlocBuilder<AddPropertyBloc, AddPropertyState>(
          builder: (context, state) {
            final isLoading = state is AddPropertyUploading ||
                state is AddPropertySubmitting;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section A: Listing Info ────────────────────────────
                      _sectionHeader('admin.listing_info'.tr()),
                      _card(children: [
                        // Property Type
                        WizardLabel('admin.property_type'.tr()),
                        DropdownButtonFormField<PropertyType>(
                          value: _propertyType,
                          decoration: _dropdownDecoration(),
                          items: PropertyType.options
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label()),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _propertyType = v),
                        ),
                        const SizedBox(height: 14),

                        // Property Status
                        WizardLabel('admin.property_status'.tr()),
                        DropdownButtonFormField<PropertyStatus>(
                          value: _propertyStatus,
                          decoration: _dropdownDecoration(),
                          items: PropertyStatus.options
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label()),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _propertyStatus = v),
                        ),
                        const SizedBox(height: 14),

                        // State
                        WizardLabel('property_details.city_state'.tr()),
                        DropdownButtonFormField<PropertyState>(
                          value: _propertyState,
                          decoration: _dropdownDecoration(),
                          items: PropertyState.options
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label()),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _propertyState = v),
                        ),
                        const SizedBox(height: 14),

                        // Toggles
                        _toggleRow(
                          'admin.is_active'.tr(),
                          _isActive,
                          (v) => setState(() => _isActive = v),
                        ),
                        const SizedBox(height: 8),
                        _toggleRow(
                          'admin.is_featured'.tr(),
                          _isFeatured,
                          (v) => setState(() => _isFeatured = v),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Section B: Titles & Descriptions ──────────────────
                      _sectionHeader('admin.titles_descriptions'.tr()),
                      _card(children: [
                        WizardLabel('admin.title_ar'.tr(), required: true),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _titleArCtrl,
                          onChanged: (_) {},
                          rows: 2,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('admin.title_en'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _titleEnCtrl,
                          onChanged: (_) {},
                          rows: 2,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('admin.content_ar'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _contentArCtrl,
                          onChanged: (_) {},
                          rows: 4,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('admin.content_en'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _contentEnCtrl,
                          onChanged: (_) {},
                          rows: 4,
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Section C: Pricing & Specs ─────────────────────────
                      _sectionHeader('admin.pricing_specs'.tr()),
                      _card(children: [
                        WizardLabel('search.filters.price_range'.tr()),
                        WizardTextArea(
                          placeholder: '0',
                          value: '',
                          controller: _priceCtrl,
                          onChanged: (_) {},
                          rows: 1,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('property_details.area'.tr()),
                        WizardTextArea(
                          placeholder: '0',
                          value: '',
                          controller: _sizeCtrl,
                          onChanged: (_) {},
                          rows: 1,
                        ),
                        const SizedBox(height: 14),
                        WizardCounterRow(
                          label: 'property_details.bedrooms'.tr(),
                          value: _bedrooms,
                          min: 1,
                          onChanged: (v) => setState(() => _bedrooms = v),
                        ),
                        const SizedBox(height: 10),
                        WizardCounterRow(
                          label: 'property_details.bathrooms'.tr(),
                          value: _bathrooms,
                          min: 1,
                          onChanged: (v) => setState(() => _bathrooms = v),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Section D: Images ──────────────────────────────────
                      _sectionHeader('admin.images'.tr()),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_existingImages.isNotEmpty) ...[
                              Text('Existing',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMute,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  _existingImages.length,
                                  (i) => _ImageThumb(
                                    imageUrl: _existingImages[i],
                                    onRemove: () => _removeExisting(i),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_newImages.isNotEmpty) ...[
                              Text('New',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMute,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  _newImages.length,
                                  (i) => _XFileThumb(
                                    file: _newImages[i],
                                    onRemove: () => _removeNew(i),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate_outlined),
                              label: Text('admin.add_photos'.tr()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Section E: Agent Info ──────────────────────────────
                      _sectionHeader('admin.agent_info'.tr()),
                      _card(children: [
                        WizardLabel('property_details.agent_label'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _agentNameCtrl,
                          onChanged: (_) {},
                          rows: 1,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('auth.phone'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _agentMobileCtrl,
                          onChanged: (_) {},
                          rows: 1,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('home.whatsapp'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _agentWhatsappCtrl,
                          onChanged: (_) {},
                          rows: 1,
                        ),
                        const SizedBox(height: 14),
                        WizardLabel('auth.email'.tr()),
                        WizardTextArea(
                          placeholder: '',
                          value: '',
                          controller: _agentEmailCtrl,
                          onChanged: (_) {},
                          rows: 1,
                        ),
                      ]),
                      const SizedBox(height: 32),

                      // Upload progress indicator
                      if (state is AddPropertyUploading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: state.current / state.total,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'admin.upload_progress'.tr(namedArgs: {
                                  'current': '${state.current}',
                                  'total': '${state.total}',
                                }),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.inkMute),
                              ),
                            ],
                          ),
                        ),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('admin.save_changes'.tr(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                if (isLoading)
                  const ModalBarrier(dismissible: false, color: Colors.transparent),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMute,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _toggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      );
}

// ── Image thumbnail widgets ───────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const _ImageThumb({required this.imageUrl, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
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
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _XFileThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _XFileThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(file.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: AppColors.tagSuccessBg,
              child:
                  const Icon(Icons.image, color: AppColors.success, size: 32),
            ),
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
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
