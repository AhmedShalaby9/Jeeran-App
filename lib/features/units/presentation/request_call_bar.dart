import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/jv2.dart';
import '../data/unit_format.dart';
import 'phone_confirm_sheet.dart';

/// The bottom bar of developer inventory: the price, the instalment, and "Request a call" —
/// there is no individual seller to call, so Jeeran calls the buyer back. The request reaches
/// the team in the dashboard's Call Requests (`POST /call-requests`). Used for primary units only;
/// a resale unit shows [ContactSellerBar] instead. Also used on a compound's page (no unit picked
/// yet): exactly one of [propertyId]/[compoundId] is set, and that is what the request is about.
class RequestCallBar extends StatefulWidget {
  final int? propertyId;
  final int? compoundId;
  final double? price;
  final String? fromPer; // "From 347K / quarter"
  final Future<void> Function(int id)? send; // tests inject a fake
  final Future<CallerPhone> Function()? loadPhone; // tests inject a fake
  final Future<void> Function(String number)? savePhone; // tests inject a fake

  /// Who to message on WhatsApp: the unit's own contact when it has one, else Jeeran's number from settings.
  /// Null hides the button.
  final String? whatsapp;
  final String? whatsappText; // the first message, naming the unit/compound
  final Future<void> Function(String number, String text)? openWhatsapp; // tests inject a fake

  const RequestCallBar({
    super.key,
    this.propertyId,
    this.compoundId,
    this.price,
    this.fromPer,
    this.send,
    this.loadPhone,
    this.savePhone,
    this.whatsapp,
    this.whatsappText,
    this.openWhatsapp,
  }) : assert((propertyId == null) != (compoundId == null), 'exactly one of propertyId/compoundId');

  @override
  State<RequestCallBar> createState() => _RequestCallBarState();
}

class _RequestCallBarState extends State<RequestCallBar> {
  bool _busy = false;
  bool _sent = false;

  Future<void> _request() async {
    if (_busy || _sent) return;
    if (widget.send == null && !AppStorage.isLoggedIn) {
      AppSnackbar.show(context, message: 'unit.call_sign_in'.tr(), icon: Icons.info_outline_rounded, iconColor: JV2.gold);
      return;
    }
    setState(() => _busy = true);
    try {
      // the team calls this number: if it was never verified, the buyer confirms or changes it first
      final phone = await (widget.loadPhone ?? _loadPhone)();
      if (!mounted) return;
      if (phone.needsConfirming) {
        final choice = await showPhoneConfirmSheet(context, phone: phone, onSave: widget.savePhone ?? _savePhone);
        if (!mounted) return;
        if (choice == null) {
          setState(() => _busy = false); // closed the sheet: nothing is sent
          return;
        }
      }
      if (widget.send != null) {
        await widget.send!(widget.propertyId ?? widget.compoundId!);
      } else {
        await sl<ApiClient>().post(
          ApiEndpoints.callRequests,
          data: widget.propertyId != null ? {'property_id': widget.propertyId} : {'compound_id': widget.compoundId},
        );
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _sent = true;
      });
      AppSnackbar.show(context, message: 'unit.call_sent'.tr(), icon: Icons.check_circle_rounded, iconColor: JV2.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnackbar.show(context, message: 'unit.call_failed'.tr(), icon: Icons.error_outline_rounded, iconColor: JV2.danger);
    }
  }

  Future<void> _whatsapp() async {
    final number = widget.whatsapp;
    if (number == null) return;
    final text = widget.whatsappText ?? '';
    if (widget.openWhatsapp != null) return widget.openWhatsapp!(number, text);
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    await launchUrl(
      Uri.parse('https://wa.me/$digits${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<CallerPhone> _loadPhone() async {
    final res = await sl<ApiClient>().get(ApiEndpoints.meProfile);
    final d = (res.data['data'] ?? const {}) as Map<String, dynamic>;
    final number = d['contact_phone'];
    return CallerPhone(number is String && number.trim().isNotEmpty ? number.trim() : null, d['phone_verified'] == true);
  }

  Future<void> _savePhone(String number) async {
    await sl<ApiClient>().put(ApiEndpoints.meContactPhone, data: {'phone': number});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: Color(0xF5FAFBFD), border: Border(top: BorderSide(color: JV2.line))),
      child: Row(
        children: [
          if (widget.price != null || widget.fromPer != null) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.price != null)
                    Text(
                      '${'unit.egp'.tr()} ${fmtShort(widget.price!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: JV2.ink),
                    ),
                  if (widget.fromPer != null)
                    Text(widget.fromPer!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          // message the seller on WhatsApp instead of waiting for the call back — sized to its
          // own text (never Expanded/capped), so "WhatsApp" is never clipped; the price column
          // is what gives way on a narrow screen.
          if (widget.whatsapp != null) ...[
            GestureDetector(
              key: const Key('request-whatsapp'),
              onTap: _whatsapp,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.whatsapp, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 24),
                    const SizedBox(width: 6),
                    Text('unit.whatsapp'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // flexible, unlike the WhatsApp button above: this one may ellipsize before WhatsApp ever does
          Expanded(
            child: JV2PrimaryButton(
              key: const Key('request-call'),
              height: 48,
              onPressed: _sent ? null : _request,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _sent ? 'unit.call_sent_short'.tr() : 'unit.request_call'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
