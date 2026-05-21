import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/presentation/bloc/add_property_bloc.dart';
import '../../../properties/presentation/bloc/properties_bloc.dart';
import '../../../properties/presentation/bloc/properties_event.dart';
import '../../../properties/presentation/bloc/properties_state.dart';
import 'admin_property_edit_page.dart';

class AdminPropertyDetailPage extends StatefulWidget {
  final Property property;

  const AdminPropertyDetailPage({super.key, required this.property});

  @override
  State<AdminPropertyDetailPage> createState() =>
      _AdminPropertyDetailPageState();
}

class _AdminPropertyDetailPageState extends State<AdminPropertyDetailPage> {
  late Property _property;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('admin.approve'.tr()),
        content: Text(
          'admin.approve_property_confirm'.tr(
            namedArgs: {'title': _property.titleAr},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('actions.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<PropertiesBloc>()
                  .add(ApprovePropertyEvent(_property.id));
            },
            child: Text(
              'admin.approve'.tr(),
              style: const TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('admin.reject'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.reject_property_confirm'.tr(
                namedArgs: {'title': _property.titleAr},
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'admin.rejection_reason'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('actions.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              context
                  .read<PropertiesBloc>()
                  .add(RejectPropertyEvent(_property.id, reason));
            },
            child: Text(
              'admin.reject'.tr(),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertiesBloc, PropertiesState>(
      listener: (context, state) {
        if (state is PropertyActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin.action_success'.tr())),
          );
          Navigator.pop(context);
        } else if (state is PropertyActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('admin.property_detail'.tr()),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => sl<AddPropertyBloc>(),
                  child: AdminPropertyEditPage(property: _property),
                ),
              ),
            );
            if (updated == true && mounted) {
              // Pop back to list — list will refresh on return
              Navigator.pop(context, true);
            }
          },
          child: const Icon(Icons.edit_outlined),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image gallery
                    if (_property.images.isNotEmpty) ...[
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _property.images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _property.images[i],
                              width: 280,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 280,
                                height: 200,
                                color: AppColors.tagPrimaryBg,
                                child: const Icon(Icons.image_not_supported,
                                    color: AppColors.inkMute),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Status badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusBadge(
                          label: _property.isApproved
                              ? 'admin.approved'.tr()
                              : 'admin.pending'.tr(),
                          color: _property.isApproved
                              ? AppColors.success
                              : AppColors.gold,
                        ),
                        _StatusBadge(
                          label: _property.isActive
                              ? 'admin.active'.tr()
                              : 'admin.inactive'.tr(),
                          color: _property.isActive
                              ? AppColors.secondary
                              : AppColors.inkMute,
                        ),
                        if (_property.isFeatured)
                          _StatusBadge(
                            label: 'admin.featured'.tr(),
                            color: AppColors.gold,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rejection reason
                    if (_property.rejectionReason != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'admin.rejection_reason'.tr(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _property.rejectionReason!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Core info card
                    _InfoCard(children: [
                      _InfoRow('admin.title_ar'.tr(), _property.titleAr),
                      if (_property.titleEn.isNotEmpty)
                        _InfoRow('admin.title_en'.tr(), _property.titleEn),
                      if (_property.propertyType != null)
                        _InfoRow('property_details.property_type'.tr(),
                            _property.propertyType!),
                      if (_property.propertyStatus != null)
                        _InfoRow('property_details.purpose'.tr(),
                            _property.propertyStatus!),
                      if (_property.price != null)
                        _InfoRow(
                            'search.filters.price_range'.tr(),
                            '${_property.price} ${'currency'.tr()}'),
                      if (_property.size != null)
                        _InfoRow('property_details.area'.tr(),
                            '${_property.size} m²'),
                      if (_property.bedrooms != null)
                        _InfoRow('property_details.bedrooms'.tr(),
                            '${_property.bedrooms}'),
                      if (_property.bathrooms != null)
                        _InfoRow('property_details.bathrooms'.tr(),
                            '${_property.bathrooms}'),
                      if (_property.country != null)
                        _InfoRow(
                            'property_details.country'.tr(), _property.country!),
                      if (_property.state != null)
                        _InfoRow('property_details.city_state'.tr(),
                            _property.state!),
                    ]),
                    const SizedBox(height: 12),

                    // Description
                    if (_property.contentAr != null ||
                        _property.contentEn != null) ...[
                      _SectionHeader('admin.titles_descriptions'.tr()),
                      _InfoCard(children: [
                        if (_property.contentAr != null)
                          _InfoRow('admin.content_ar'.tr(),
                              _property.contentAr!, multiline: true),
                        if (_property.contentEn != null)
                          _InfoRow('admin.content_en'.tr(),
                              _property.contentEn!, multiline: true),
                      ]),
                      const SizedBox(height: 12),
                    ],

                    // Agent info
                    if (_property.agentName != null ||
                        _property.agentMobile != null) ...[
                      _SectionHeader('admin.agent_info'.tr()),
                      _InfoCard(children: [
                        if (_property.agentName != null)
                          _InfoRow('property_details.agent_label'.tr(),
                              _property.agentName!),
                        if (_property.agentMobile != null)
                          _InfoRow('auth.phone'.tr(), _property.agentMobile!),
                        if (_property.agentWhatsapp != null)
                          _InfoRow('home.whatsapp'.tr(),
                              _property.agentWhatsapp!),
                        if (_property.agentEmail != null)
                          _InfoRow(
                              'auth.email'.tr(), _property.agentEmail!),
                      ]),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 80), // space for bottom bar
                  ],
                ),
              ),
            ),

            // Bottom action bar (only for pending)
            if (!_property.isApproved)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: AppColors.hairline, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('admin.reject'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showApproveDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('admin.approve'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSub,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final nonEmpty = children.whereType<Widget>().toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < nonEmpty.length; i++) ...[
            nonEmpty[i],
            if (i < nonEmpty.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow(this.label, this.value, {this.multiline = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: multiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMute)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.ink, height: 1.5)),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMute)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
    );
  }
}
