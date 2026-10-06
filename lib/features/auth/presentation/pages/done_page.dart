import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../seller_request/presentation/bloc/seller_request_bloc.dart';
import '../../../seller_request/presentation/bloc/seller_request_event.dart';
import '../../../seller_request/presentation/bloc/seller_request_state.dart';

/// Final step of sign-up: account summary + a seed for the seller flow.
class DonePage extends StatelessWidget {
  final String name;
  final String phone;

  const DonePage({super.key, required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SellerRequestBloc>(),
      child: _DoneView(name: name, phone: phone),
    );
  }
}

class _DoneView extends StatefulWidget {
  final String name;
  final String phone;

  const _DoneView({required this.name, required this.phone});

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  bool _sellerRequested = false;

  @override
  void dispose() {
    _intro.dispose();
    _rings.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
      (_) => false,
    );
  }

  Widget _ring(double phase) {
    return AnimatedBuilder(
      animation: _rings,
      builder: (_, _) {
        final t = (_rings.value + phase) % 1;
        final eased = const Cubic(.2, .7, .3, 1).transform(t);
        return Opacity(
          opacity: 0.55 * (1 - t),
          child: Transform.scale(
            scale: 0.7 + 1.2 * eased,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: JV2.goldEdge),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge() {
    final scale = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.64, curve: Cubic(.2, .8, .25, 1)),
    );
    final draw = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.32, 0.95, curve: Cubic(.4, 0, .2, 1)),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        _ring(0),
        _ring(0.5),
        ScaleTransition(
          scale: Tween(begin: 0.88, end: 1.0).animate(scale),
          child: FadeTransition(
            opacity: scale,
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment(-0.3, -1),
                  end: Alignment(0.3, 1),
                  colors: [JV2.goldHi, JV2.gold],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x52B8893D), // .32
                    blurRadius: 40,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: draw,
                builder: (_, _) =>
                    CustomPaint(painter: _CheckPainter(draw.value)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(String sellerValue, Color sellerColor) {
    final rows = [
      ('done.buyer_account'.tr(), 'done.active'.tr(), JV2.success),
      ('done.mobile_verified'.tr(), widget.phone, JV2.inkSub),
      ('done.seller_access'.tr(), sellerValue, sellerColor),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: JV2.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(fontSize: 13.5, color: JV2.inkSub),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Directionality(
                      textDirection: i == 1
                          ? ui.TextDirection.ltr
                          : Directionality.of(context),
                      child: Text(
                        rows[i].$2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: rows[i].$3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final first = widget.name.trim().split(RegExp(r'\s+')).first;
    final title = first.isEmpty
        ? 'done.title_anon'.tr()
        : 'done.title'.tr(args: [first]);

    return BlocListener<SellerRequestBloc, SellerRequestState>(
      listener: (context, state) {
        if (state is SellerRequestSuccess) {
          setState(() => _sellerRequested = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('done.seller_requested'.tr())));
        } else if (state is SellerRequestError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: JV2.bgDeep,
          body: JV2Ambient(
            intensity: 1.1,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        32,
                        media.padding.top + 16,
                        32,
                        16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _badge(),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _intro,
                              curve: const Interval(0.27, 0.8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: JV2.display(context, 34),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'done.sub'.tr(),
                                  textAlign: TextAlign.center,
                                  style: JV2.sub,
                                ),
                                const SizedBox(height: 28),
                                BlocBuilder<
                                  SellerRequestBloc,
                                  SellerRequestState
                                >(
                                  builder: (_, _) => _summary(
                                    _sellerRequested
                                        ? 'done.seller_pending'.tr()
                                        : 'done.not_requested'.tr(),
                                    JV2.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    media.padding.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      JV2PrimaryButton(
                        onPressed: _start,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('done.start'.tr()),
                            const SizedBox(width: 8),
                            Icon(
                              Directionality.of(context) == ui.TextDirection.rtl
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!_sellerRequested)
                        BlocBuilder<SellerRequestBloc, SellerRequestState>(
                          builder: (context, state) {
                            final loading = state is SellerRequestLoading;
                            return TextButton(
                              onPressed: loading
                                  ? null
                                  : () => context.read<SellerRequestBloc>().add(
                                      const SubmitSellerRequestEvent(),
                                    ),
                              style: TextButton.styleFrom(
                                foregroundColor: JV2.inkSub,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'done.join_seller'.tr(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            );
                          },
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White check mark that draws itself in (viewBox 42×42, path 11,21.5 → 18.5,29 → 31,13).
class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final off = Offset((size.width - 42) / 2, (size.height - 42) / 2);
    final path = Path()
      ..moveTo(off.dx + 11, off.dy + 21.5)
      ..lineTo(off.dx + 18.5, off.dy + 29)
      ..lineTo(off.dx + 31, off.dy + 13);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
