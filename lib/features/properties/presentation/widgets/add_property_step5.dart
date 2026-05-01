import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'add_property_form.dart';

class AddPropertyStep5 extends StatefulWidget {
  final AddPropertyForm form;
  final VoidCallback onChanged;

  const AddPropertyStep5({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  State<AddPropertyStep5> createState() => _AddPropertyStep5State();
}

class _AddPropertyStep5State extends State<AddPropertyStep5> {
  @override
  Widget build(BuildContext context) {
    final form = widget.form;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepTitle(
          'Agent contact info',
          subtitle: 'How should buyers reach you?',
        ),

        // ── Agent name ────────────────────────────────────────────
        const WizardLabel('Agent name', required: true),
        WizardInput(
          placeholder: 'Full name',
          value: form.agentName,
          onChanged: (v) {
            form.agentName = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Mobile ────────────────────────────────────────────────
        const WizardLabel('Mobile number', required: true),
        WizardInput(
          placeholder: '+20 1XX XXX XXXX',
          value: form.agentMobile,
          keyboardType: TextInputType.phone,
          onChanged: (v) {
            form.agentMobile = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── WhatsApp ──────────────────────────────────────────────
        const WizardLabel('WhatsApp number'),
        WizardInput(
          placeholder: 'Defaults to mobile if left empty',
          value: form.agentWhatsapp,
          keyboardType: TextInputType.phone,
          onChanged: (v) {
            form.agentWhatsapp = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),

        // ── Email ─────────────────────────────────────────────────
        const WizardLabel('Email address'),
        WizardInput(
          placeholder: 'agent@example.com (optional)',
          value: form.agentEmail,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) {
            form.agentEmail = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 28),

        // ── Summary card ──────────────────────────────────────────
        _SummaryCard(form: form),
      ],
    );
  }
}

// ── Summary card ──────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final AddPropertyForm form;
  const _SummaryCard({required this.form});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          _Row(
            label: 'Type',
            value: form.propertyType != null ? form.propertyType!.label() : '—',
          ),
          _Row(
            label: 'Status',
            value: form.propertyStatus != null ? form.propertyStatus!.label() : '—',
          ),
          _Row(
            label: 'Location',
            value: form.location != null ? form.location!.label() : '—',
          ),
          _Row(
            label: 'Project',
            value: form.projectTitle.isNotEmpty ? form.projectTitle : '—',
          ),
          _Row(
            label: 'Price',
            value: form.price.isNotEmpty ? '${form.price} EGP' : '—',
          ),
          _Row(
            label: 'Size',
            value: form.size.isNotEmpty ? '${form.size} m²' : '—',
          ),
          _Row(
            label: 'Beds / Baths',
            value: '${form.bedrooms} / ${form.bathrooms}',
          ),
          _Row(
            label: 'Photos',
            value: '${form.selectedImages.length} selected',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _Row({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.hairline)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSub),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
