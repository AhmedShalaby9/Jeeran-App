import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The back gesture on the main screen never closes the app at once:
///   · on any tab but the first it goes back to the first tab;
///   · on the first tab it asks to press back again, and only a second press within [window] leaves the app.
class DoubleBackExit extends StatefulWidget {
  final Widget child;
  final bool atHome; // the first tab is showing
  final VoidCallback goHome; // switch to the first tab
  final Duration window;
  final VoidCallback? onExit; // tests replace the real exit
  final DateTime Function() clock; // tests move time

  const DoubleBackExit({
    super.key,
    required this.child,
    required this.atHome,
    required this.goHome,
    this.window = const Duration(seconds: 2),
    this.onExit,
    this.clock = DateTime.now,
  });

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _askedAt;

  void _onBack() {
    if (!widget.atHome) {
      widget.goHome();
      return;
    }
    final now = widget.clock();
    if (_askedAt != null && now.difference(_askedAt!) <= widget.window) {
      (widget.onExit ?? SystemNavigator.pop)();
      return;
    }
    _askedAt = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('back-again'),
          content: Text('explore.back_again'.tr()),
          duration: widget.window,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
