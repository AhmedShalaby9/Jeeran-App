import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/storage/app_storage.dart';
import '../../core/widgets/html_content_page.dart';
import '../../core/widgets/jv2.dart';
import '../admin/presentation/pages/admin_panel_page.dart';
import '../auth/presentation/pages/login_page.dart';
import '../explore/presentation/widgets/explore_widgets.dart';
import '../main/presentation/pages/main_page.dart';
import '../more/presentation/pages/contact_us_page.dart';
import '../notifications/presentation/pages/notification_settings_page.dart';
// PACKAGES DISABLED: import '../packages/presentation/pages/packages_destination.dart';
import '../profile/profile_page.dart';
import '../properties/presentation/pages/add_property_page.dart';
import '../properties/presentation/pages/my_properties_page.dart';
import 'you_api.dart';

const double _pad = 20;

/// The You tab: who you are, your listings (everyone can list: there are no separate sellers), and your settings.
class YouPage extends StatefulWidget {
  final YouApi? api; // tests inject a fake
  const YouPage({super.key, this.api});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  late final YouApi _api = widget.api ?? YouApi(sl<ApiClient>());
  YouSummary? _s;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _api.summary();
      if (mounted) {
        setState(() {
          _s = s;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted && _s == null) setState(() => _failed = true);
    }
  }

  /// Open a page and refresh the numbers when coming back (a listing may have been added, a plan bought…).
  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  bool get _inReview => AppSettingsService.instance.inReview;

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          _header(s),
          Expanded(
            child: s == null
                ? (_failed
                      ? _failure()
                      : const Center(
                          child: CircularProgressIndicator(color: JV2.navy),
                        ))
                : RefreshIndicator(
                    color: JV2.navy,
                    onRefresh: _load,
                    child: _content(s),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _failure() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('you.load_failed'.tr(), style: JV2.display(context, 20)),
        const SizedBox(height: 14),
        JV2PrimaryButton(
          width: 150,
          height: 44,
          onPressed: _load,
          child: Text('you.retry'.tr()),
        ),
      ],
    ),
  );

  // ── header ──

  /// Tapping the person opens their profile, the same as the pencil.
  Widget _header(YouSummary? s) => GestureDetector(
    key: const Key('you-header'),
    behavior: HitTestBehavior.opaque,
    onTap: s == null ? null : () => _go(const ProfilePage()),
    child: _headerBody(s),
  );

  Widget _headerBody(YouSummary? s) {
    final name = (s?.name.isNotEmpty ?? false)
        ? s!.name
        : (AppStorage.userName ?? '');
    final sub = s?.email ?? s?.phone ?? '';
    final role = s == null
        ? null
        : (s.isAdmin ? 'you.role_admin' : 'you.role_customer');
    const seller = true; // (the role pill is gold for everyone now)
    return Container(
      padding: EdgeInsets.fromLTRB(
        _pad,
        MediaQuery.of(context).padding.top + 14,
        _pad,
        20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xE6FAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: JV2.line),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4F7FB), Color(0xFFE4EAF1)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0B2A4A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: (s?.picture ?? '').isNotEmpty
                ? Photo(url: s!.picture, width: 62, height: 62, radius: 31)
                : Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: JV2.display(context, 25).copyWith(color: JV2.navy),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                  ),
                ],
                if (role != null) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: seller ? JV2.goldFilm : JV2.fillFaint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: seller ? JV2.goldEdge : JV2.line,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (seller) ...[
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 11,
                            color: JV2.gold,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          role.tr().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: seller ? JV2.gold : JV2.inkSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'you.edit'.tr(),
            child: GestureDetector(
              onTap: () => _go(const ProfilePage()),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: JV2.line),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: JV2.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── body ──

  Widget _content(YouSummary s) {
    // PACKAGES DISABLED:     final ar = isArabic(context);
    final canList = !_inReview || s.isAdmin; // everyone can list
    final lang = context.locale.languageCode;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 18, bottom: 30),
      children: [
        // PACKAGES DISABLED: if (seller && !_inReview) ...[_planCard(s), const SizedBox(height: 22)],
        if (canList) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _pad),
            child: GestureDetector(
              onTap: () async {
                await AddPropertyPage.push(context);
                if (mounted) _load();
              },
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [JV2.navyLift, JV2.navy],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x380B2A4A),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'you.list_property'.tr(),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (!s.isAdmin && !_inReview) ...[
          _Group(
            title: 'you.g_selling'.tr(),
            children: [
              _Row(
                icon: Icons.home_outlined,
                label: 'more.my_properties'.tr(),
                meta: 'you.my_properties_meta'.tr(
                  args: ['${s.live}', '${s.inReview}'],
                ),
                badge: s.inReview > 0 ? '${s.inReview}' : null,
                onTap: () => _go(const MyPropertiesPage()),
              ),
              /* PACKAGES DISABLED
              _Row(
                icon: Icons.credit_card_rounded,
                label: 'bottom_nav.packages'.tr(),
                meta: s.plan == null
                    ? 'you.no_plan'.tr()
                    : '${s.plan!.name(ar)}${s.plan!.endsAt == null ? '' : ' · ${(s.plan!.isFree ? 'you.plan_ends' : 'you.plan_renews').tr(args: [DateFormat.MMMd(context.locale.toString()).format(s.plan!.endsAt!)])}'}',
                onTap: () => _go(const PackagesDestination()),
              ),
              */
            ],
          ),
          const SizedBox(height: 22),
        ],
        if (s.isAdmin) ...[
          _Group(
            title: 'you.g_admin'.tr(),
            children: [
              _Row(
                icon: Icons.admin_panel_settings_outlined,
                label: 'admin.title'.tr(),
                onTap: () => _go(const AdminPanelPage()),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        _Group(
          title: 'you.g_activity'.tr(),
          children: [
            _Row(
              icon: Icons.notifications_none_rounded,
              label: 'more.notifications'.tr(),
              meta: 'you.notif_meta'.tr(
                args: [
                  'notif.places'.plural(s.placesFollowed),
                  'notif.received'.plural(s.received30d),
                ],
              ),
              badge: s.unread > 0 ? '${s.unread}' : null,
              onTap: () => _go(const NotificationSettingsPage()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _Group(
          title: 'you.g_account'.tr(),
          children: [
            _Row(
              icon: Icons.lock_outline_rounded,
              label: 'you.privacy'.tr(),
              onTap: () => _go(
                HtmlContentPage(
                  title: 'more.privacy_policy'.tr(),
                  html: AppSettingsService.instance.privacy(lang),
                ),
              ),
            ),
            _Row(
              icon: Icons.language_rounded,
              label: 'more.language'.tr(),
              meta: lang == 'ar'
                  ? 'language.arabic'.tr()
                  : 'language.english'.tr(),
              onTap: _languageSheet,
            ),
            _Row(
              icon: Icons.info_outline_rounded,
              label: 'more.about'.tr(),
              onTap: () => _go(
                HtmlContentPage(
                  title: 'more.about'.tr(),
                  html: AppSettingsService.instance.about(lang),
                ),
              ),
            ),
            _Row(
              icon: Icons.description_outlined,
              label: 'more.terms_of_service'.tr(),
              onTap: () => _go(
                HtmlContentPage(
                  title: 'more.terms_of_service'.tr(),
                  html: AppSettingsService.instance.terms(lang),
                ),
              ),
            ),
            _Row(
              icon: Icons.help_outline_rounded,
              label: 'more.contact_us'.tr(),
              onTap: () => _go(const ContactUsPage()),
            ),
          ],
        ),
        if (AppStorage.isLoggedIn) ...[
          const SizedBox(height: 22),
          _Group(
            children: [
              _Row(
                icon: Icons.logout_rounded,
                label: 'more.logout'.tr(),
                danger: true,
                onTap: _confirmSignOut,
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (_, snap) {
            final v = snap.data?.version ?? '';
            return Column(
              children: [
                const JV2Mark(size: 22, opacity: 0.4),
                const SizedBox(height: 9),
                if (v.isNotEmpty)
                  Text(
                    'you.footer'.tr(args: [v]),
                    style: const TextStyle(fontSize: 11, color: JV2.inkSub),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── pieces ──

  /* PACKAGES DISABLED
  Widget _planCard(YouSummary s) {
    final ar = isArabic(context);
    final p = s.plan;
    if (p == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pad),
        child: GestureDetector(
          onTap: () => _go(const PackagesDestination()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JV2.goldFilm,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: JV2.goldEdge),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'you.no_plan'.tr(),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                ),
                Icon(chevronIcon(context), size: 16, color: JV2.gold),
              ],
            ),
          ),
        ),
      );
    }
    final pct = p.total == 0 ? 0.0 : (p.used / p.total).clamp(0.0, 1.0);
    final low = p.low;
    final when = p.endsAt == null
        ? ''
        : (p.isFree ? 'you.plan_ends' : 'you.plan_renews').tr(
            args: [
              DateFormat.MMMd(context.locale.toString()).format(p.endsAt!),
            ],
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
          boxShadow: JV2.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'you.plan_current'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: JV2.gold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              p.name(ar),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: JV2.display(context, 24),
                            ),
                          ),
                          if (when.isNotEmpty) ...[
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                when,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: JV2.inkSub,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _go(const PackagesDestination()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: low ? JV2.navy : JV2.fillFaint,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: low ? JV2.navy : JV2.line),
                      boxShadow: low
                          ? const [
                              BoxShadow(
                                color: Color(0x330B2A4A),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      (low ? 'you.plan_upgrade' : 'you.plan_manage').tr(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: low ? Colors.white : JV2.navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'you.plan_used'.tr(),
                    style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                  ),
                ),
                Text(
                  '${p.used} / ${p.total}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: low ? JV2.warnText : JV2.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 7,
                color: JV2.track,
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: low
                            ? const [JV2.goldHi, Color(0xFFC8892B)]
                            : const [JV2.navyLift, JV2.navy],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (low) ...[
              const SizedBox(height: 9),
              Text(
                'you.plan_left'.plural(p.left),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: JV2.warnText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  */

  void _languageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JV2.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JV2.track,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('language.select'.tr(), style: JV2.display(sheetCtx, 22)),
              const SizedBox(height: 8),
              for (final code in const ['en', 'ar'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    (code == 'en' ? 'language.english' : 'language.arabic')
                        .tr(),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: context.locale.languageCode == code
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: JV2.ink,
                    ),
                  ),
                  trailing: context.locale.languageCode == code
                      ? const Icon(Icons.check_rounded, color: JV2.gold)
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    if (context.locale.languageCode == code) return;
                    await context.setLocale(Locale(code));
                    await AppStorage.setLanguage(code);
                    if (mounted) _restartApp();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A language change rebuilds the whole app so every screen picks it up.
  void _restartApp() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            AppStorage.isLoggedIn ? const MainPage() : const LoginPage(),
        transitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('more.logout_title'.tr()),
        content: Text('more.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('actions.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              unregisterFcmTokenOnLogout().ignore();
              AppStorage.clearAuth();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: Text(
              'actions.logout'.tr(),
              style: const TextStyle(color: JV2.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ── building blocks ──

class _Group extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _Group({this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(_pad + 4, 0, _pad + 4, 9),
          child: Text(
            title!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: JV2.inkSub,
            ),
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
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: JV2.line),
              children[i],
            ],
          ],
        ),
      ),
    ],
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? meta;
  final String? badge;
  final bool danger;
  final VoidCallback onTap;
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.meta,
    this.badge,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: danger ? const Color(0x14C23B3B) : JV2.fillFaint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: danger ? JV2.danger : JV2.navy),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: danger ? JV2.danger : JV2.ink,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JV2.goldFilm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: JV2.gold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(chevronIcon(context), size: 15, color: JV2.inkSub),
        ],
      ),
    ),
  );
}
