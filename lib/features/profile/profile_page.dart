import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/jv2.dart';
import '../explore/presentation/widgets/explore_widgets.dart';
import 'edit_profile_page.dart';
import 'profile_api.dart';

const double kProfilePad = 20;

/// Round avatar: the photo, or the first letter of the name.
class ProfileAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const ProfileAvatar({
    super.key,
    required this.url,
    required this.name,
    this.size = 92,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: JV2.line),
        boxShadow: JV2.shadowMd,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FB), Color(0xFFE4EAF1)],
        ),
      ),
      child: (url ?? '').isNotEmpty
          ? Photo(url: url, width: size, height: size, radius: size / 2)
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: JV2.display(context, size * 0.4).copyWith(color: JV2.navy),
            ),
    );
  }
}

class ProfileEyebrow extends StatelessWidget {
  final String text;
  const ProfileEyebrow(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: JV2.eyebrow),
  );
}

class VerifiedTick extends StatelessWidget {
  const VerifiedTick({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_rounded, size: 12, color: JV2.success),
      const SizedBox(width: 4),
      Text(
        'profile.verified'.tr(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: JV2.success,
        ),
      ),
    ],
  );
}

/// What other people see of you. Buyers see a seller's name, company, photo and live listings; the phone
/// number is never printed here for anyone else. "Edit" opens the fields behind it.
class ProfilePage extends StatefulWidget {
  final ProfileApi? api; // tests inject a fake
  const ProfilePage({super.key, this.api});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileApi _api = widget.api ?? ProfileApi(sl<ApiClient>());
  ProfileData? _p;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final p = await _api.load();
      if (mounted) setState(() => _p = p);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _edit() async {
    final p = _p;
    if (p == null) return;
    final saved = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(profile: p, api: _api),
      ),
    );
    if (saved != null && mounted) setState(() => _p = saved);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              kProfilePad,
              MediaQuery.of(context).padding.top + 10,
              kProfilePad,
              12,
            ),
            child: Row(
              children: [
                const JV2BackButton(),
                Expanded(
                  child: Text(
                    'profile.title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                ),
                if (p != null)
                  GestureDetector(
                    key: const Key('profile-edit'),
                    onTap: _edit,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: JV2.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: JV2.navy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'profile.edit'.tr(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: JV2.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 38),
              ],
            ),
          ),
          Expanded(
            child: _failed
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'explore.load_failed'.tr(),
                          style: JV2.display(context, 22),
                        ),
                        const SizedBox(height: 16),
                        JV2PrimaryButton(
                          width: 160,
                          height: 46,
                          onPressed: _load,
                          child: Text('explore.try_again'.tr()),
                        ),
                      ],
                    ),
                  )
                : p == null
                ? const Center(
                    child: CircularProgressIndicator(color: JV2.navy),
                  )
                : _body(p),
          ),
        ],
      ),
    );
  }

  Widget _body(ProfileData p) {
    final seller = p.isCustomer;
    final since = p.since == null
        ? null
        : DateFormat.yMMMM(context.locale.toString()).format(p.since!);
    final line = [
      if (seller && p.company != null) p.company!,
      if (p.city != null) p.city!,
      if (since != null) 'profile.since'.tr(args: [since]),
    ].join(' · ');
    final rows = <(String, String, bool)>[
      if (p.phone != null) ('profile.phone'.tr(), p.phone!, true),
      if (p.email != null) ('profile.email'.tr(), p.email!, false),
      (
        'profile.language'.tr(),
        context.locale.languageCode == 'ar' ? 'العربية' : 'English',
        false,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(kProfilePad, 10, kProfilePad, 30),
      children: [
        Column(
          children: [
            ProfileAvatar(url: p.picture, name: p.name),
            const SizedBox(height: 12),
            Text(
              p.name,
              textAlign: TextAlign.center,
              style: JV2.display(context, 27),
            ),
            if (line.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                line,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: JV2.inkSub),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: seller ? JV2.goldFilm : JV2.fillFaint,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: seller ? JV2.goldEdge : JV2.line),
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
                    (seller
                            ? (p.sellerVerified
                                  ? 'profile.verified_seller'
                                  : 'you.role_seller')
                            : 'you.role_buyer')
                        .tr()
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: seller ? JV2.gold : JV2.inkSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (seller && p.liveListings != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JV2.line),
            ),
            child: Row(
              children: [
                for (final (i, s) in [
                  ('${p.liveListings}', 'profile.live_listings'.tr()),
                  if (since != null)
                    (
                      DateFormat.y(context.locale.toString()).format(p.since!),
                      'profile.member_since'.tr(),
                    ),
                ].indexed)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : const BorderDirectional(
                                start: BorderSide(color: JV2.line),
                              ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            s.$1,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: JV2.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.$2,
                            style: const TextStyle(
                              fontSize: 11,
                              color: JV2.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (seller && p.bio != null) ...[
          const SizedBox(height: 20),
          ProfileEyebrow('profile.about'.tr()),
          Text(
            p.bio!,
            style: const TextStyle(fontSize: 14, height: 1.55, color: JV2.ink),
          ),
        ],
        const SizedBox(height: 20),
        ProfileEyebrow('profile.contact'.tr()),
        Container(
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JV2.line),
          ),
          child: Column(
            children: [
              for (final (i, r) in rows.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: JV2.line)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          r.$1,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: ui.TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: JV2.ink,
                          ),
                        ),
                      ),
                      if (r.$3) const VerifiedTick(),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (seller ? 'profile.note_seller' : 'profile.note_buyer').tr(),
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.45,
            color: JV2.inkSub,
          ),
        ),
      ],
    );
  }
}
