import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
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

  bool get _isEditing => widget.news != null;

  @override
  void initState() {
    super.initState();
    _titleArCtrl = TextEditingController(text: widget.news?.title ?? '');
    _titleEnCtrl = TextEditingController();
    _contentArCtrl = TextEditingController(text: widget.news?.content ?? '');
    _contentEnCtrl = TextEditingController();
    _isActive = widget.news?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _contentArCtrl.dispose();
    _contentEnCtrl.dispose();
    super.dispose();
  }

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
      ));
    } else {
      bloc.add(CreateNewsEvent(
        titleAr: _titleArCtrl.text.trim(),
        titleEn: _titleEnCtrl.text.trim().isEmpty ? null : _titleEnCtrl.text.trim(),
        contentAr: _contentArCtrl.text.trim(),
        contentEn: _contentEnCtrl.text.trim().isEmpty ? null : _contentEnCtrl.text.trim(),
        isActive: _isActive,
      ));
    }
  }

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
            final isLoading = state is NewsLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _titleArCtrl,
                      label: 'admin.title_ar'.tr(),
                      required: true,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _titleEnCtrl,
                      label: 'admin.title_en'.tr(),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _contentArCtrl,
                      label: 'admin.content_ar'.tr(),
                      required: true,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _contentEnCtrl,
                      label: 'admin.content_en'.tr(),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text('admin.active'.tr()),
                        value: _isActive,
                        activeColor: AppColors.success,
                        onChanged: isLoading
                            ? null
                            : (v) => setState(() => _isActive = v),
                      ),
                    ),
                    const SizedBox(height: 24),
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
    required String label,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
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
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }
}
