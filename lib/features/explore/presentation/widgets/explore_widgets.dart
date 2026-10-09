import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/models/explore_data.dart';

bool isArabic(BuildContext context) => context.locale.languageCode == 'ar';

bool isRtl(BuildContext context) =>
    Directionality.of(context) == ui.TextDirection.rtl;

IconData chevronIcon(BuildContext context) =>
    isRtl(context) ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;

/// Network image with the design's soft placeholder gradient behind it.
class Photo extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final double radius;
  final Color tint;
  final Widget? child;

  const Photo({
    super.key,
    this.url,
    this.height,
    this.width,
    this.radius = 16,
    this.tint = const Color(0x331A4A80),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE9EEF4),
                    const Color(0xFFD9E1EA),
                    tint.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            if (url != null && url!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
                placeholder: (_, _) => const SizedBox.shrink(),
              ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// ── top bar ───────────────────────────────────────────────

class ExploreTopBar extends StatelessWidget {
  /// "Do it": the AI shortcut. Null hides it (buyers, store-review build).
  final VoidCallback? onShortcut;
  const ExploreTopBar({super.key, this.onShortcut});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 8,
            20,
            12,
          ),
          decoration: const BoxDecoration(
            color: Color(0xE6FAFBFD), // .9
            border: Border(bottom: BorderSide(color: JV2.line)),
          ),
          child: Row(
            children: [
              const JV2Mark(size: 28),
              const Spacer(),
              if (onShortcut != null) ...[
                _DoIt(onTap: onShortcut!),
                const SizedBox(width: 10),
              ],
              const _Bell(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoIt extends StatelessWidget {
  final VoidCallback onTap;
  const _DoIt({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('do-it'),
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(colors: [JV2.navyLift, JV2.navy]),
        boxShadow: const [
          BoxShadow(color: Color(0x330B2A4A), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFFE5C48F)),
          const SizedBox(width: 6),
          Text(
            'explore.do_it'.tr(),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreadCountCubit, int>(
      bloc: sl<UnreadCountCubit>(),
      builder: (context, count) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        ).then((_) => sl<UnreadCountCubit>().fetch()),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: JV2.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0B2A4A),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: JV2.ink,
              ),
            ),
            if (count > 0)
              PositionedDirectional(
                top: -5,
                end: -5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: JV2.goldHi,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: JV2.bgDeep, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── greeting + search entry ───────────────────────────────

class ExploreGreeting extends StatelessWidget {
  const ExploreGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final key = h < 12
        ? 'explore.greeting_morning'
        : h < 18
        ? 'explore.greeting_afternoon'
        : 'explore.greeting_evening';
    final name = (AppStorage.userName ?? '').trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? key.tr() : '${key.tr()}, $name',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: JV2.inkSub,
            ),
          ),
          const SizedBox(height: 5),
          Text('explore.title'.tr(), style: JV2.display(context, 27)),
        ],
      ),
    );
  }
}

class ExploreSearchEntry extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback? onAsk; // null hides the Ask button (store review build)
  final VoidCallback? onVoice; // null hides the mic

  const ExploreSearchEntry({
    super.key,
    required this.onSearch,
    this.onAsk,
    this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: JV2.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0B2A4A),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: JV2.inkMute,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'explore.search_hint'.tr(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: JV2.inkMute,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onAsk != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: 'explore.ask_tooltip'.tr(),
              child: GestureDetector(
                onTap: onAsk,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      begin: Alignment(-0.5, -1),
                      end: Alignment(0.5, 1),
                      colors: [JV2.navyLift, JV2.navy],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3D0B2A4A),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      JV2GoldSweep(width: 22),
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (onVoice != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: 'explore.voice_tooltip'.tr(),
              child: GestureDetector(
                key: const Key('explore-mic'),
                onTap: onVoice,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: JV2.line),
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    size: 22,
                    color: JV2.ink,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── section heading ───────────────────────────────────────

class SectionHead extends StatelessWidget {
  final String eyebrow;
  final String title;
  final VoidCallback? onAction;

  const SectionHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: JV2.gold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(title, style: JV2.display(context, 21)),
              ],
            ),
          ),
          if (onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'explore.see_all'.tr(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: JV2.inkSub,
                      ),
                    ),
                    Icon(chevronIcon(context), size: 16, color: JV2.inkMute),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── quick grid ────────────────────────────────────────────

class QuickTile {
  final String labelKey;
  final int count;
  final Color tint;
  final VoidCallback onTap;

  const QuickTile({
    required this.labelKey,
    required this.count,
    required this.tint,
    required this.onTap,
  });
}

class QuickGrid extends StatelessWidget {
  final List<QuickTile> tiles;

  const QuickGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.decimalPattern(context.locale.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: (MediaQuery.of(context).size.width - 50) / 2 / 74,
        children: [
          for (final t in tiles)
            GestureDetector(
              onTap: t.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: JV2.line),
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        top: -26,
                        end: -26,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [t.tint, t.tint.withValues(alpha: 0)],
                              stops: const [0, 0.7],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.labelKey.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: JV2.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'explore.listings_count'.tr(
                              args: [f.format(t.count)],
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: JV2.inkMute,
                              fontFeatures: [ui.FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── seller request status ─────────────────────────────────

class SellerStatusRow extends StatelessWidget {
  final SellerRequestStatus request;
  final VoidCallback onRejectedTap;

  const SellerStatusRow({
    super.key,
    required this.request,
    required this.onRejectedTap,
  });

  String _submitted() {
    final d = request.createdAt;
    if (d == null) return '';
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'explore.today'.tr();
    if (days == 1) return 'explore.yesterday'.tr();
    return 'explore.days_ago'.tr(args: ['$days']);
  }

  @override
  Widget build(BuildContext context) {
    final rejected = request.isRejected;
    final c = rejected ? JV2.danger : JV2.warnText;
    final bg = rejected ? const Color(0x14C23B3B) : const Color(0x1AB8893D);
    final title = rejected
        ? 'explore.seller_rejected_title'
        : 'explore.seller_pending_title';
    final sub = rejected
        ? 'explore.seller_rejected_sub'.tr()
        : 'explore.seller_pending_sub'.tr(args: [_submitted()]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: rejected ? onRejectedTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.13),
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JV2.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                    ),
                  ],
                ),
              ),
              if (rejected) Icon(chevronIcon(context), size: 16, color: c),
            ],
          ),
        ),
      ),
    );
  }
}
