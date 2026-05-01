import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/add_property_bloc.dart';
import '../bloc/add_property_event.dart';
import '../bloc/add_property_state.dart';
import '../widgets/add_property_form.dart';
import '../widgets/add_property_step1.dart';
import '../widgets/add_property_step2.dart';
import '../widgets/add_property_step3.dart';
import '../widgets/add_property_step4.dart';
import '../widgets/add_property_step5.dart';

class AddPropertyPage extends StatelessWidget {
  const AddPropertyPage({super.key});

  /// Push the wizard as a full-screen modal.
  /// Silently no-ops if the current user is not a seller.
  static Future<void> push(BuildContext context) async {
    if (!AppStorage.isSeller) {
      AppSnackbar.show(
        context,
        message: 'Only sellers can add listings',
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.inkSub,
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider(
          create: (_) => sl<AddPropertyBloc>(),
          child: const AddPropertyPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPropertyBloc, AddPropertyState>(
      listener: (context, state) {
        if (state is AddPropertySuccess) {
          AppSnackbar.show(
            context,
            message: 'Listing published successfully!',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
          );
          Navigator.pop(context);
        } else if (state is AddPropertyFailure) {
          AppSnackbar.show(
            context,
            message: state.message,
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
          );
        }
      },
      child: const _AddPropertyView(),
    );
  }
}

class _AddPropertyView extends StatefulWidget {
  const _AddPropertyView();

  @override
  State<_AddPropertyView> createState() => _AddPropertyViewState();
}

class _AddPropertyViewState extends State<_AddPropertyView> {
  static const int _totalSteps = 5;

  int _step = 1;
  final _form = AddPropertyForm();

  // ── Navigation ─────────────────────────────────────────────

  void _next() {
    if (!_form.isStepValid(_step)) {
      HapticFeedback.lightImpact();
      AppSnackbar.show(
        context,
        message: _validationErrorMessage(_step),
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.danger,
      );
      return;
    }
    setState(() {
      if (_step < _totalSteps) _step++;
    });
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.maybePop(context);
    }
  }

  String _validationErrorMessage(int step) => switch (step) {
        1 => 'Please select a property type and listing status',
        2 => 'Please select a location and project',
        3 => 'Please enter a valid price and area',
        4 => 'Add at least 1 photo and fill in all titles and descriptions',
        _ => 'Please enter agent name and mobile number',
      };

  void _publish() {
    final state = context.read<AddPropertyBloc>().state;
    if (state is AddPropertyUploading || state is AddPropertySubmitting) return;
    if (!_form.isStepValid(_step)) {
      HapticFeedback.lightImpact();
      AppSnackbar.show(
        context,
        message: _validationErrorMessage(_step),
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.danger,
      );
      return;
    }
    context.read<AddPropertyBloc>().add(SubmitAddProperty(form: _form));
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _WizardHeader(
              step: _step,
              total: _totalSteps,
              onBack: _back,
              onClose: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
            BlocBuilder<AddPropertyBloc, AddPropertyState>(
              builder: (context, state) {
                final busy =
                    state is AddPropertyUploading || state is AddPropertySubmitting;
                String? progressLabel;
                if (state is AddPropertyUploading) {
                  progressLabel = 'Uploading ${state.current}/${state.total}…';
                } else if (state is AddPropertySubmitting) {
                  progressLabel = 'Publishing…';
                }
                return _WizardBottomBar(
                  step: _step,
                  total: _totalSteps,
                  busy: busy,
                  progressLabel: progressLabel,
                  onBack: _back,
                  onContinue: _next,
                  onPublish: _publish,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    1 => AddPropertyStep1(form: _form, onChanged: () => setState(() {})),
    2 => AddPropertyStep2(form: _form, onChanged: () => setState(() {})),
    3 => AddPropertyStep3(form: _form, onChanged: () => setState(() {})),
    4 => AddPropertyStep4(form: _form, onChanged: () => setState(() {})),
    _ => AddPropertyStep5(form: _form, onChanged: () => setState(() {})),
  };
}

// ─────────────────────────────────────────────────────────────
//  Header with progress bar
// ─────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _WizardHeader({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final progress = step / total;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: topPad),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                _HeaderBtn(
                  icon: step > 1
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.close_rounded,
                  onTap: step > 1 ? onBack : onClose,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Step $step of $total',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSub,
                      ),
                    ),
                  ),
                ),
                step > 1
                    ? _HeaderBtn(icon: Icons.close_rounded, onTap: onClose)
                    : const SizedBox(width: 36),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: const Color(0xFFEEF0F4),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.ink),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Bottom action bar
// ─────────────────────────────────────────────────────────────

class _WizardBottomBar extends StatelessWidget {
  final int step;
  final int total;
  final bool busy;
  final String? progressLabel;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onPublish;

  const _WizardBottomBar({
    required this.step,
    required this.total,
    required this.busy,
    required this.onBack,
    required this.onContinue,
    required this.onPublish,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isLast = step == total;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          if (step > 1) ...[
            GestureDetector(
              onTap: busy ? null : onBack,
              child: Container(
                width: 96,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: busy ? null : (isLast ? onPublish : onContinue),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: busy
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            if (progressLabel != null) ...[
                              const SizedBox(width: 10),
                              Text(
                                progressLabel!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          isLast ? 'Publish listing' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
