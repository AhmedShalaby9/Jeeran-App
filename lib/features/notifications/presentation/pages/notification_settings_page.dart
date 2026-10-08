import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../developers/presentation/pages/developer_page.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../v2/notif_api.dart';

const double _pad = 20;

/// You → Notifications: what you have signed up for, and each followed place, switchable where it sits.
class NotificationSettingsPage extends StatefulWidget {
  final NotifApi? api; // tests inject a fake
  const NotificationSettingsPage({super.key, this.api});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final NotifApi _api = widget.api ?? NotifApi(sl<ApiClient>());
  NotifSettings? _s;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final s = await _api.settings(context.locale.languageCode);
      if (mounted) setState(() => _s = s);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _toast() => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('notif.save_failed'.tr())));

  /// Flip the switch now; put it back (with a message) if the server says no.
  Future<void> _optimistic(
    NotifSettings next,
    Future<void> Function() save,
  ) async {
    final before = _s!;
    setState(() => _s = next);
    try {
      await save();
    } catch (_) {
      if (mounted) {
        setState(() => _s = before);
        _toast();
      }
    }
  }

  void _toggleCategory(NotifCategory c) => _optimistic(
    _s!.copyWith(
      categories: [
        for (final x in _s!.categories)
          x.id == c.id ? x.withEnabled(!c.enabled) : x,
      ],
    ),
    () => _api.setCategory(c.id, !c.enabled),
  );

  void _togglePlace(FollowedPlace p) {
    final next = p.withAlerts(!p.alertsOn);
    List<FollowedPlace> swap(List<FollowedPlace> l) => [
      for (final x in l) x.id == p.id ? next : x,
    ];
    _optimistic(
      p.kind == 'compound'
          ? _s!.copyWith(compounds: swap(_s!.compounds))
          : _s!.copyWith(developers: swap(_s!.developers)),
      () => _api.setPlaceAlerts(p.kind, p.id, next.alertsOn),
    );
  }

  void _setAll(bool on) => _optimistic(
    _s!.copyWith(
      compounds: [for (final p in _s!.compounds) p.withAlerts(on)],
      developers: [for (final p in _s!.developers) p.withAlerts(on)],
    ),
    () => _api.setAllPlaceAlerts(on),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _failed
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'notif.load_failed'.tr(),
                          style: JV2.display(context, 20),
                        ),
                        const SizedBox(height: 14),
                        JV2PrimaryButton(
                          width: 150,
                          height: 44,
                          onPressed: _load,
                          child: Text('notif.retry'.tr()),
                        ),
                      ],
                    ),
                  )
                : _s == null
                ? const Center(
                    child: CircularProgressIndicator(color: JV2.navy),
                  )
                : _content(_s!),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final s = _s;
    final summary = s == null
        ? ''
        : [
            'notif.received'.plural(s.received30d),
            if (s.placesFollowed > 0) 'notif.places'.plural(s.placesFollowed),
          ].join(' · ');
    return Container(
      padding: EdgeInsets.fromLTRB(
        _pad,
        MediaQuery.of(context).padding.top + 8,
        _pad,
        15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xE6FAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: JV2.line),
                  ),
                  child: Icon(
                    isRtl(context)
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 22,
                    color: JV2.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'notif.title'.tr(),
                  style: JV2.display(context, 22),
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: JV2.goldFilm,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 14,
                    color: JV2.gold,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: JV2.inkSub,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _content(NotifSettings s) {
    final ar = isArabic(context);
    return ListView(
      padding: const EdgeInsets.only(top: 18, bottom: 30),
      children: [
        _Section(
          title: 'notif.s_from'.tr(),
          children: [
            for (var i = 0; i < s.categories.length; i++)
              _CategoryRow(
                first: i == 0,
                label: 'notif.cat_${s.categories[i].id}'.tr(),
                note: 'notif.n_${s.categories[i].id}'.tr(),
                on: s.categories[i].enabled,
                locked: s.categories[i].locked,
                onTap: () => _toggleCategory(s.categories[i]),
              ),
          ],
        ),
        if (s.compounds.isNotEmpty) ...[
          const SizedBox(height: 22),
          _Section(
            title: 'notif.s_compounds'.tr(),
            count: s.compounds.length,
            children: [
              for (var i = 0; i < s.compounds.length; i++)
                _PlaceRow(
                  first: i == 0,
                  place: s.compounds[i],
                  ar: ar,
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompoundPage(
                        compoundId: s.compounds[i].id,
                        name: s.compounds[i].name(ar),
                      ),
                    ),
                  ),
                  onToggle: () => _togglePlace(s.compounds[i]),
                ),
            ],
          ),
        ],
        if (s.developers.isNotEmpty) ...[
          const SizedBox(height: 22),
          _Section(
            title: 'notif.s_developers'.tr(),
            count: s.developers.length,
            children: [
              for (var i = 0; i < s.developers.length; i++)
                _PlaceRow(
                  first: i == 0,
                  place: s.developers[i],
                  ar: ar,
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeveloperPage(
                        developerId: s.developers[i].id,
                        name: s.developers[i].name(ar),
                      ),
                    ),
                  ),
                  onToggle: () => _togglePlace(s.developers[i]),
                ),
            ],
          ),
        ],
        if (s.placesFollowed == 0) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _pad),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JV2.goldEdge),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: JV2.goldFilm,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                      color: JV2.gold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'notif.no_places_title'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'notif.no_places_sub'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: JV2.inkSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _pad),
            child: GestureDetector(
              onTap: () => _setAll(s.placesOn == 0),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: JV2.line),
                ),
                child: Text(
                  (s.placesOn == 0 ? 'notif.on_all' : 'notif.off_all').tr(),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: s.placesOn == 0 ? JV2.navy : JV2.danger,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pad + 4),
          child: Text(
            'notif.footer'.tr(),
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: JV2.inkSub,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final int? count;
  final List<Widget> children;
  const _Section({required this.title, required this.children, this.count});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(_pad + 4, 0, _pad + 4, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: JV2.inkSub,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: JV2.gold,
                ),
              ),
            ],
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: _pad),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JV2.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0B2A4A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    ],
  );
}

/// The switch from the design: navy for the app-wide rows, gold for places.
class _Switch extends StatelessWidget {
  final bool on;
  final bool locked;
  final bool navy;
  final VoidCallback? onTap;
  const _Switch({
    required this.on,
    this.locked = false,
    this.navy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = navy
        ? const [JV2.navyLift, JV2.navy]
        : const [JV2.goldHi, JV2.gold];
    return GestureDetector(
      onTap: locked ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: locked ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          alignment: on
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: on
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: fill,
                  )
                : null,
            color: on ? null : JV2.fillHi,
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x330B2A4A),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final bool first;
  final String label;
  final String note;
  final bool on;
  final bool locked;
  final VoidCallback onTap;
  const _CategoryRow({
    required this.first,
    required this.label,
    required this.note,
    required this.on,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: first ? null : const Border(top: BorderSide(color: JV2.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: JV2.fillFaint,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: JV2.line),
                      ),
                      child: Text(
                        'notif.always'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: JV2.inkSub,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: JV2.inkSub,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        _Switch(on: on, locked: locked, navy: true, onTap: onTap),
      ],
    ),
  );
}

class _PlaceRow extends StatelessWidget {
  final bool first;
  final FollowedPlace place;
  final bool ar;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  const _PlaceRow({
    required this.first,
    required this.place,
    required this.ar,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final sub = !place.alertsOn
        ? 'notif.muted'.tr()
        : (place.lastUpdate ?? 'notif.no_news'.tr());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  place.kind == 'compound'
                      ? Photo(
                          url: place.image,
                          width: 44,
                          height: 44,
                          radius: 12,
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: JV2.line),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF4F7FB), Color(0xFFE4EAF1)],
                            ),
                          ),
                          child: (place.image ?? '').isNotEmpty
                              ? Photo(
                                  url: place.image,
                                  width: 44,
                                  height: 44,
                                  radius: 13,
                                )
                              : Text(
                                  _initials(place.name(ar)),
                                  style: JV2
                                      .display(context, 15)
                                      .copyWith(color: JV2.navy),
                                ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name(ar),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: JV2.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
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
          const SizedBox(width: 12),
          _Switch(on: place.alertsOn, onTap: onToggle),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final w = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();
    return w.isEmpty ? '?' : w.take(3).map((x) => x[0]).join().toUpperCase();
  }
}
