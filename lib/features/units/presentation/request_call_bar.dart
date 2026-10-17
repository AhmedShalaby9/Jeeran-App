import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/jv2.dart';
import '../data/unit_format.dart';
import 'phone_confirm_sheet.dart';

/// The bottom bar of developer inventory: the price, the instalment, and "Request a call" —
/// there is no individual seller to call, so Jeeran calls the buyer back. The request reaches
/// the team in the dashboard's Call Requests (`POST /call-requests`). Used for primary units only;
/// a resale unit shows [ContactSellerBar] instead.
class RequestCallBar extends StatefulWidget {
  final int propertyId;
  final double? price;
  final String? fromPer; // "From 347K / quarter"
  final Future<void> Function(int propertyId)? send; // tests inject a fake
  final Future<CallerPhone> Function()? loadPhone; // tests inject a fake
  final Future<void> Function(String number)? savePhone; // tests inject a fake

  const RequestCallBar({
    super.key,
    required this.propertyId,
    this.price,
    this.fromPer,
    this.send,
    this.loadPhone,
    this.savePhone,
  });

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
        await widget.send!(widget.propertyId);
      } else {
        await sl<ApiClient>().post(ApiEndpoints.callRequests, data: {'property_id': widget.propertyId});
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.price != null) Text('${'unit.egp'.tr()} ${fmtShort(widget.price!)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: JV2.ink)),
                if (widget.fromPer != null) Text(widget.fromPer!, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          JV2PrimaryButton(
            key: const Key('request-call'),
            height: 48,
            onPressed: _sent ? null : _request,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_sent ? 'unit.call_sent_short'.tr() : 'unit.request_call'.tr(), style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
