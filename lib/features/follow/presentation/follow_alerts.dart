import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../data/follow_service.dart';

/// One place (a compound or a developer) the person may follow. Following puts it in Saved AND turns on every
/// notification for it; the bell mutes or unmutes those notifications without unfollowing.
class FollowController extends ChangeNotifier {
  final FollowService service;
  final FollowType type;
  final int id;
  final String name;
  bool following;
  bool alertsOn;
  bool busy = false;

  /// Which kinds of news it sends; every kind by default.
  late Set<String> events;

  FollowController({
    required this.service,
    required this.type,
    required this.id,
    required this.name,
    required this.following,
    required bool alertsOn,
    Iterable<String>? events,
  }) : alertsOn = following && alertsOn {
    final all = allEvents(type == FollowType.project);
    final picked = events?.where(all.contains).toSet();
    this.events = picked == null || picked.isEmpty ? {...all} : picked;
  }

  /// Every kind a compound (or a developer, which has no phases of its own) can send.
  static List<String> allEvents(bool compound) => [
    if (compound) 'phase',
    'launch',
    'listing',
    'news',
  ];

  bool get isCompound => type == FollowType.project;

  /// Tick or untick one kind. At least one stays on (to hear nothing, mute it). Saved at once when alerts are on;
  /// otherwise kept here until "Notify me".
  Future<bool> toggleEvent(String key) async {
    if (busy) return true;
    final was = {...events};
    final next = was.contains(key) ? ({...was}..remove(key)) : {...was, key};
    if (next.isEmpty) return true;
    events = next;
    notifyListeners();
    if (!alertsOn) return true;
    try {
      await service.setEvents(type, id, next);
      return true;
    } catch (_) {
      events = was;
      notifyListeners();
      return false;
    }
  }

  /// Follow ⇄ Unfollow. Returns false (state restored) when the server said no.
  Future<bool> toggleFollow() async {
    if (busy) return true;
    final was = (following, alertsOn);
    following = !was.$1;
    alertsOn = following; // a new follow starts with every notification on
    events = {...allEvents(isCompound)};
    busy = true;
    notifyListeners();
    try {
      was.$1
          ? await service.unfollow(type, id)
          : await service.follow(type, id);
      return true;
    } catch (_) {
      following = was.$1;
      alertsOn = was.$2;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// "Notify me" / "Turn off": switching alerts on also follows; switching off keeps the follow.
  Future<bool> setAlerts(bool on) async {
    if (busy) return true;
    final was = (following, alertsOn);
    busy = true;
    notifyListeners();
    try {
      if (on && !following) {
        await service.follow(type, id);
        following = true;
      }
      alertsOn = on;
      notifyListeners();
      await service.setAlerts(type, id, on, events: on ? events : null);
      return true;
    } catch (_) {
      following = was.$1;
      alertsOn = was.$2;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

const _softShadow = [
  BoxShadow(color: Color(0x140B2A4A), blurRadius: 6, offset: Offset(0, 2)),
];

void _failed(BuildContext context) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text('follow.failed'.tr())));

/// What following a place sends you, for the disclosure sheet and the strip.
List<(String key, String label, String note)> followEvents(bool compound) =>
    compound
    ? [
        ('phase', 'follow.ev_phase'.tr(), 'follow.ev_phase_n'.tr()),
        ('launch', 'follow.ev_launch'.tr(), 'follow.ev_launch_n'.tr()),
        ('listing', 'follow.ev_listing'.tr(), 'follow.ev_listing_n_c'.tr()),
        ('news', 'follow.ev_news'.tr(), 'follow.ev_news_n'.tr()),
      ]
    : [
        ('launch', 'follow.ev_launch'.tr(), 'follow.ev_launch_n'.tr()),
        ('listing', 'follow.ev_listing'.tr(), 'follow.ev_listing_n_d'.tr()),
        ('news', 'follow.ev_news'.tr(), 'follow.ev_news_n'.tr()),
      ];

/// The Follow / Following button on its own; fills the width it is given.
class FollowCta extends StatelessWidget {
  final FollowController c;
  final double height;
  const FollowCta({super.key, required this.c, this.height = 46});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => GestureDetector(
        key: const Key('follow-button'),
        onTap: () async {
          if (!await c.toggleFollow() && context.mounted) _failed(context);
        },
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: c.following ? JV2.surface : null,
            gradient: c.following
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [JV2.navyLift, JV2.navy],
                  ),
            border: c.following ? Border.all(color: JV2.line) : null,
            boxShadow: c.following
                ? _softShadow
                : const [
                    BoxShadow(
                      color: Color(0x380B2A4A),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.following) ...[
                const Icon(Icons.check_rounded, size: 15, color: JV2.navy),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  c.following
                      ? 'follow.following'.tr()
                      : (c.isCompound
                                ? 'follow.follow_compound'
                                : 'follow.follow_developer')
                            .tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.following ? JV2.navy : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Follow button + the alerts bell, side by side.
class FollowBar extends StatelessWidget {
  final FollowController c;
  const FollowBar({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: FollowCta(c: c)),
        const SizedBox(width: 10),
        AlertBell(c: c),
      ],
    );
  }
}

/// Follow / Following on a cover photo: the white container, like the bell beside it (design D3 and the developer cover).
class HeroFollow extends StatelessWidget {
  final FollowController c;
  const HeroFollow({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => GestureDetector(
        key: const Key('follow-button'),
        onTap: () async {
          if (!await c.toggleFollow() && context.mounted) _failed(context);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: const Color(0xEBFFFFFF),
            boxShadow: _softShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                c.following
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 17,
                color: c.following ? JV2.danger : JV2.ink,
              ),
              const SizedBox(width: 7),
              Text(
                (c.following ? 'follow.following' : 'follow.follow_short').tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: JV2.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small glass bell that sits on a cover photo; gold when alerts are on. Opens the alerts sheet.
class HeroBell extends StatelessWidget {
  final FollowController c;
  const HeroBell({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final on = c.alertsOn;
        return GestureDetector(
          key: const Key('alert-bell'),
          onTap: () => showAlertsSheet(context, c),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: on ? null : const Color(0xEBFFFFFF),
              gradient: on
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [JV2.goldHi, JV2.gold],
                    )
                  : null,
              boxShadow: on
                  ? const [
                      BoxShadow(
                        color: Color(0x6BB8893D),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : _softShadow,
            ),
            child: Icon(
              on
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 18,
              color: on ? Colors.white : JV2.ink,
            ),
          ),
        );
      },
    );
  }
}

/// Gold when alerts are on. Tapping explains what they are (and, when off, turns them on).
class AlertBell extends StatelessWidget {
  final FollowController c;
  const AlertBell({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final on = c.alertsOn;
    return GestureDetector(
      key: const Key('alert-bell'),
      onTap: () => showAlertsSheet(context, c),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: on ? null : JV2.surface,
          gradient: on
              ? const LinearGradient(colors: [JV2.goldHi, JV2.gold])
              : null,
          border: on ? null : Border.all(color: JV2.line),
          boxShadow: on
              ? const [
                  BoxShadow(
                    color: Color(0x6BB8893D),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(
          on
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          size: 20,
          color: on ? Colors.white : JV2.ink,
        ),
      ),
    );
  }
}

/// In-page strip: off = an invitation, on = a receipt with a way to turn it off.
class AlertsStrip extends StatelessWidget {
  final FollowController c;
  const AlertsStrip({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (!c.alertsOn) {
          return GestureDetector(
            key: const Key('alerts-invite'),
            onTap: () => showAlertsSheet(context, c),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JV2.goldEdge),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: JV2.goldFilm,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 18,
                      color: JV2.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (c.following
                                  ? 'follow.invite_muted'
                                  : 'follow.invite')
                              .tr(args: [c.name]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: JV2.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (c.isCompound
                                  ? 'follow.invite_sub_c'
                                  : 'follow.invite_sub_d')
                              .tr(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: JV2.inkSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: JV2.gold,
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          key: const Key('alerts-on'),
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JV2.goldEdge),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [JV2.goldHi, JV2.gold],
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'follow.alerts_on'.tr().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: JV2.gold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'follow.push'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: JV2.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      key: const Key('alerts-off'),
                      onTap: () async {
                        if (!await c.setAlerts(false) && context.mounted)
                          _failed(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: JV2.fillFaint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: JV2.line),
                        ),
                        child: Text(
                          'follow.turn_off'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: JV2.navy,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in followEvents(
                        c.isCompound,
                      ).where((e) => c.events.contains(e.$1)))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: JV2.goldFilm,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: JV2.goldEdge),
                          ),
                          child: Text(
                            e.$2,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: JV2.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A disclosure, not a form: what will arrive before you agree to it.
Future<void> showAlertsSheet(BuildContext context, FollowController c) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: JV2.bgDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JV2.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'follow.sheet_eyebrow'.tr().toUpperCase(),
                          style: JV2.eyebrow,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'follow.sheet_title'.tr(args: [c.name]),
                          style: JV2.display(context, 23),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: JV2.fillFaint,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: JV2.line),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'follow.sheet_sub'.tr(),
                style: JV2.sub.copyWith(fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JV2.line),
                ),
                child: Column(
                  children: [
                    for (final (i, e) in followEvents(c.isCompound).indexed)
                      GestureDetector(
                        key: Key('event-${e.$1}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          if (!await c.toggleEvent(e.$1) && context.mounted)
                            _failed(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: i == 0
                                ? null
                                : const Border(
                                    top: BorderSide(color: JV2.line),
                                  ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: c.events.contains(e.$1)
                                      ? JV2.goldFilm
                                      : JV2.surface,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: c.events.contains(e.$1)
                                        ? JV2.goldEdge
                                        : JV2.line,
                                  ),
                                ),
                                child: c.events.contains(e.$1)
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: JV2.gold,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.$2,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.events.contains(e.$1)
                                            ? JV2.ink
                                            : JV2.inkSub,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      e.$3,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        height: 1.4,
                                        color: JV2.inkSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: JV2.inkSub,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'follow.sheet_foot'.tr(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: JV2.inkSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: c.alertsOn
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            'follow.sheet_on'.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: JV2.success,
                            ),
                          ),
                        ),
                        GestureDetector(
                          key: const Key('sheet-turn-off'),
                          onTap: () async {
                            final ok = await c.setAlerts(false);
                            if (sheetContext.mounted)
                              Navigator.pop(sheetContext);
                            if (!ok && context.mounted) _failed(context);
                          },
                          child: Text(
                            'follow.turn_off'.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: JV2.navy,
                            ),
                          ),
                        ),
                      ],
                    )
                  : JV2PrimaryButton(
                      key: const Key('notify-me'),
                      onPressed: c.busy
                          ? null
                          : () async {
                              final ok = await c.setAlerts(true);
                              if (sheetContext.mounted)
                                Navigator.pop(sheetContext);
                              if (!ok && context.mounted) _failed(context);
                            },
                      child: Text('follow.notify_me'.tr()),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
