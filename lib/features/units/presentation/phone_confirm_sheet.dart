import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';

/// The number the team would call the buyer on, and whether an SMS code ever confirmed it.
class CallerPhone {
  final String? number;
  final bool verified;
  const CallerPhone(this.number, this.verified);

  bool get needsConfirming => !verified || (number ?? '').isEmpty;
}

/// How the buyer answered the sheet.
enum PhoneChoice { keep, saved }

/// Shown before a call request when the number on the account was never verified: "this number is not
/// verified — continue with it, or change it?". Changing and continuing replaces the number and counts it as
/// confirmed ([onSave]); continuing as is sends the request with the number left unverified.
/// With no number at all there is nothing to continue with, so it asks for one straight away.
Future<PhoneChoice?> showPhoneConfirmSheet(
  BuildContext context, {
  required CallerPhone phone,
  required Future<void> Function(String number) onSave,
}) {
  return showModalBottomSheet<PhoneChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: JV2.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _PhoneConfirmSheet(phone: phone, onSave: onSave),
  );
}

class _PhoneConfirmSheet extends StatefulWidget {
  final CallerPhone phone;
  final Future<void> Function(String number) onSave;
  const _PhoneConfirmSheet({required this.phone, required this.onSave});

  @override
  State<_PhoneConfirmSheet> createState() => _PhoneConfirmSheetState();
}

class _PhoneConfirmSheetState extends State<_PhoneConfirmSheet> {
  final _input = TextEditingController();
  late bool _editing = (widget.phone.number ?? '').isEmpty;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _input.text.trim();
    if (_busy) return;
    if (value.replaceAll(RegExp(r'\D'), '').length < 7) {
      setState(() => _error = 'unit.phone_invalid'.tr());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(value);
      if (mounted) Navigator.pop(context, PhoneChoice.saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'unit.phone_invalid'.tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.phone.number ?? '';
    final missing = number.isEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: JV2.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Text((missing ? 'unit.phone_missing_title' : 'unit.phone_unverified_title').tr(), style: JV2.display(context, 22)),
              const SizedBox(height: 8),
              Text(
                (missing ? 'unit.phone_missing_body' : 'unit.phone_unverified_body').tr(),
                style: const TextStyle(fontSize: 13.5, height: 1.5, color: JV2.inkSub),
              ),
              if (!missing && !_editing) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('phone-current'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: JV2.bgDeep, borderRadius: BorderRadius.circular(14), border: Border.all(color: JV2.line)),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 18, color: JV2.navy),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Directionality(
                          textDirection: ui.TextDirection.ltr, // a number reads left to right in Arabic too
                          child: Text(number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: JV2.ink, letterSpacing: 0.3)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(999)),
                        child: Text('unit.phone_not_verified'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                      ),
                    ],
                  ),
                ),
              ],
              if (_editing) ...[
                const SizedBox(height: 14),
                JV2Field(
                  key: const Key('phone-input'),
                  controller: _input,
                  placeholder: 'unit.phone_hint'.tr(),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, key: const Key('phone-error'), style: const TextStyle(fontSize: 12.5, color: JV2.danger, fontWeight: FontWeight.w600)),
                  ),
              ],
              const SizedBox(height: 18),
              if (_editing)
                JV2PrimaryButton(
                  key: const Key('phone-save'),
                  height: 50,
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('unit.phone_save'.tr()),
                )
              else ...[
                JV2PrimaryButton(
                  key: const Key('phone-continue'),
                  height: 50,
                  onPressed: () => Navigator.pop(context, PhoneChoice.keep),
                  child: Text('unit.phone_continue'.tr()),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  key: const Key('phone-change'),
                  onTap: () => setState(() => _editing = true),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: JV2.line)),
                    child: Text('unit.phone_change'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: JV2.ink)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
