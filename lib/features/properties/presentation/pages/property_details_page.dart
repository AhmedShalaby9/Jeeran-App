import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../ai_chat/scoped/ask_context.dart';
import '../../../ai_chat/scoped/ask_scope_api.dart';
import '../../../compounds/data/compound_page_data.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../developers/presentation/pages/developer_page.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../search/presentation/widgets/search_widgets.dart'
    show paymentLabel;
import '../../data/models/property_model.dart';
import '../../data/property_page_data.dart';
import '../../domain/entities/property.dart';
import '../widgets/property_v2_widgets.dart';
import 'property_image_viewer_page.dart';

/// The decision screen: one scrolling page that answers what it is, what it costs, who is behind
/// it and who to call. Opened from a list item; the full record is fetched on arrival.
class PropertyDetailsPage extends StatefulWidget {
  final Property property;
  final AskScopeApi? askApi; // tests inject a fake
  const PropertyDetailsPage({super.key, required this.property, this.askApi});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  PropertyPageData? _data;
  bool _failed = false;
  List<Map<String, dynamic>> _similar = const [];
  late bool _saved;
  int _media = 0;
  final _pager = PageController();

  @override
  void initState() {
    super.initState();
    _saved =
        sl<FavoritesBloc>().isFavorited(widget.property.id) ||
        widget.property.isFavorited;
    _load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final api = sl<ApiClient>();
    try {
      final res = await api.get(
        ApiEndpoints.propertyPageById(widget.property.id),
        headers: ApiClient.apiV2,
      );
      final raw = res.data['data'];
      if (raw is! Map<String, dynamic>) throw const FormatException();
      if (mounted) {
        setState(() {
          _data = PropertyPageData.fromJson(raw);
          _saved = _saved || _data!.isFavorited;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    // similar units are a nicety: if they fail the page is still whole
    try {
      final res = await api.get(
        ApiEndpoints.similarProperties(widget.property.id),
        queryParams: {'limit': 8},
      );
      final list = res.data['data'];
      if (mounted && list is List)
        setState(
          () => _similar = list.whereType<Map<String, dynamic>>().toList(),
        );
    } catch (_) {}
  }

  /// While the full record loads, show what the list already knew.
  PropertyPageData get _provisional {
    final p = widget.property;
    return PropertyPageData(
      id: p.id,
      title: Bi(p.titleAr, p.titleEn),
      content: const Bi('', ''),
      price: double.tryParse(p.price ?? ''),
      pricePerM2: null,
      size: double.tryParse(p.size ?? ''),
      garden: null,
      beds: p.bedrooms,
      baths: p.bathrooms,
      propertyType: p.propertyType ?? '',
      status: p.propertyStatus ?? 'for_sale',
      listingType: 'primary',
      images: p.images,
      videoUrl: null,
      floorPlan: null,
      isFeatured: p.isFeatured,
      level: const Bi('', ''),
      maintenance: const Bi('', ''),
      referenceCode: null,
      publishedAt: null,
      phase: const Bi('', ''),
      compound: null,
      developer: null,
      deliveryDate: null,
      isReady: null,
      finishing: null,
      paymentOptions: const [],
      downPaymentPercent: null,
      installmentYears: null,
      amenities: const [],
      agentName: null,
      agentMobile: p.agentMobile,
      agentWhatsapp: p.agentWhatsapp,
      agentPicture: null,
      sellerVerified: false,
      isFavorited: p.isFavorited,
    );
  }

  bool get _ar => isArabic(context);

  void _toggleSave() {
    setState(() => _saved = !_saved);
    final id = widget.property.id;
    final offset = 72 + MediaQuery.of(context).padding.bottom + 12.0;
    if (_saved) {
      sl<FavoritesBloc>().add(AddFavoriteEvent(id));
      AppSnackbar.favoriteAdded(context, bottomMargin: offset);
    } else {
      sl<FavoritesBloc>().add(RemoveFavoriteEvent(id));
      AppSnackbar.favoriteRemoved(context, bottomMargin: offset);
    }
  }

  List<PropMedia> _mediaOf(PropertyPageData d) => [
    for (final u in d.images) PropMedia('image', u),
    if (d.videoUrl != null)
      PropMedia('video', d.images.isEmpty ? null : d.images.first),
    if (d.floorPlan != null) PropMedia('plan', d.floorPlan),
  ];

  void _openMedia(PropertyPageData d, List<PropMedia> media, int i) {
    final m = media[i];
    if (m.kind == 'video') {
      launchUrl(Uri.parse(d.videoUrl!), mode: LaunchMode.externalApplication);
      return;
    }
    final urls = [
      for (final x in media)
        if (x.kind != 'video' && x.url != null) x.url!,
    ];
    final at = urls.indexOf(m.url ?? '');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyImageViewerPage(
          images: urls,
          initialIndex: at < 0 ? 0 : at,
        ),
      ),
    );
  }

  Future<void> _call(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isNotEmpty) await launchUrl(Uri(scheme: 'tel', path: cleaned));
  }

  Future<void> _whatsapp(String number) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty)
      await launchUrl(
        Uri.parse('https://wa.me/$digits'),
        mode: LaunchMode.externalApplication,
      );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data ?? _provisional;
    final media = _mediaOf(d);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  PropGallery(
                    media: media,
                    index: _media,
                    controller: _pager,
                    featured: d.isFeatured,
                    saved: _saved,
                    onPage: (i) => setState(() => _media = i),
                    onTapMedia: (i) => _openMedia(d, media, i),
                    onSave: _toggleSave,
                  ),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
                      child: Column(
                        children: [
                          Text(
                            'prop.load_failed'.tr(),
                            style: JV2.display(context, 21),
                          ),
                          const SizedBox(height: 14),
                          JV2PrimaryButton(
                            width: 160,
                            height: 46,
                            onPressed: _load,
                            child: Text('prop.retry'.tr()),
                          ),
                        ],
                      ),
                    )
                  else
                    _body(d),
                ],
              ),
            ),
            if (_data != null)
              ContactBar(
                onMessage: (d.agentWhatsapp ?? '').isEmpty
                    ? null
                    : () => _whatsapp(d.agentWhatsapp!),
                onCall: (d.agentMobile ?? '').isEmpty
                    ? null
                    : () => _call(d.agentMobile!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(PropertyPageData d) {
    final loaded = _data != null;
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    final location = [
      d.compound?.name.pick(_ar),
      d.phase.pick(_ar),
      d.compound?.area.pick(_ar),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final about = d.content.pick(_ar);
    final features = d.amenities;
    final facts = _facts(d);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // price + title + location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPropPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        money(context, d.price),
                        style: JV2.display(context, 32).copyWith(height: 1),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'explore.egp'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: JV2.gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (d.pricePerM2 != null)
                      'prop.per_m2'.tr(
                        args: [nf.format(d.pricePerM2!.round())],
                      ),
                    'find.st_${d.status}'.tr(),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: JV2.inkMute),
                ),
                const SizedBox(height: 13),
                Text(d.title.pick(_ar), style: JV2.display(context, 23)),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: JV2.inkMute,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          StatusChips([
            if (d.isReady == true)
              ('find.ready'.tr(), true)
            else if (d.deliveryDate != null)
              (
                'find.c_delivery_year'.tr(args: ['${d.deliveryDate!.year}']),
                false,
              ),
            if (d.finishing != null)
              ('compound.fin_${d.finishing}'.tr(), false),
            if (d.propertyType.isNotEmpty)
              ('type.${d.propertyType}'.tr(), false),
            ('prop.sale_${d.listingType}'.tr(), false),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPropPad),
            child: KeyFacts([
              if (d.beds != null)
                (Icons.bed_outlined, '${d.beds}', 'prop.beds'.tr()),
              if (d.baths != null)
                (Icons.bathtub_outlined, '${d.baths}', 'prop.baths'.tr()),
              if (d.size != null)
                (
                  Icons.square_foot_rounded,
                  nf.format(d.size!.round()),
                  'prop.m2_built'.tr(),
                ),
              if (d.garden != null)
                (
                  Icons.yard_outlined,
                  nf.format(d.garden!.round()),
                  'prop.m2_garden'.tr(),
                ),
            ]),
          ),
          if (!loaded)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator(color: JV2.navy)),
            )
          else ...[
            if (about.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPropPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PropLabel('prop.about'.tr()),
                    PropCard(
                      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                      child: Text(
                        about,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.58,
                          color: JV2.inkSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPropPad),
              child: AskContextCard(
                scope: AskScope(AskScopeType.property, d.id, d.title.pick(_ar)),
                api: widget.askApi,
              ),
            ),
            if (d.compound != null || d.developer != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPropPad),
                child: _chain(d),
              ),
            ],
            if (features.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPropPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PropLabel('prop.features'.tr()),
                    FeatureGrid(features),
                  ],
                ),
              ),
            ],
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPropPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [PropLabel('prop.facts'.tr()), FactsTable(facts)],
                ),
              ),
            ],
            if (d.agentName != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPropPad),
                child: _seller(d),
              ),
            ],
            if (_similar.isNotEmpty) ...[
              const SizedBox(height: 20),
              _similarRail(),
            ],
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPropPad),
              child: Text(
                _footer(d),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: JV2.inkMute,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _footer(PropertyPageData d) {
    final parts = <String>[
      if (d.referenceCode != null)
        'prop.reference'.tr(args: [d.referenceCode!]),
      if (d.publishedAt != null)
        () {
          final days = DateTime.now().difference(d.publishedAt!).inDays;
          return days <= 0
              ? 'prop.listed_today'.tr()
              : 'prop.listed_days'.plural(days);
        }(),
    ];
    return parts.join(' · ');
  }

  List<(String, String)> _facts(PropertyPageData d) {
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    String m2(double v) => 'prop.sqm_unit'.tr(args: [nf.format(v.round())]);
    final payment = <String>[
      if (d.paymentOptions.isNotEmpty)
        d.paymentOptions.map(paymentLabel).join(' · '),
      if (d.downPaymentPercent != null && d.installmentYears != null)
        'prop.down_years'.tr(
          args: [_trim(d.downPaymentPercent!), '${d.installmentYears}'],
        )
      else if (d.downPaymentPercent != null)
        'prop.down_only'.tr(args: [_trim(d.downPaymentPercent!)])
      else if (d.installmentYears != null)
        'prop.years_only'.tr(args: ['${d.installmentYears}']),
    ];
    final delivery = d.isReady == true
        ? 'find.ready'.tr()
        : (d.deliveryDate == null ? null : '${d.deliveryDate!.year}');
    return [
      if (d.propertyType.isNotEmpty)
        ('prop.f_type'.tr(), 'type.${d.propertyType}'.tr()),
      ('prop.f_purpose'.tr(), 'find.st_${d.status}'.tr()),
      ('prop.f_sale_type'.tr(), 'prop.sale_${d.listingType}'.tr()),
      if (d.size != null) ('prop.f_built'.tr(), m2(d.size!)),
      if (d.garden != null) ('prop.f_garden'.tr(), m2(d.garden!)),
      if (d.beds != null) ('prop.f_beds'.tr(), '${d.beds}'),
      if (d.baths != null) ('prop.f_baths'.tr(), '${d.baths}'),
      if (d.level.pick(_ar).isNotEmpty)
        ('prop.f_level'.tr(), d.level.pick(_ar)),
      if (d.finishing != null)
        ('prop.f_finishing'.tr(), 'compound.fin_${d.finishing}'.tr()),
      if (delivery != null) ('prop.f_delivery'.tr(), delivery),
      if (d.phase.pick(_ar).isNotEmpty)
        ('prop.f_phase'.tr(), d.phase.pick(_ar)),
      if (payment.isNotEmpty) ('prop.f_payment'.tr(), payment.join('\n')),
      if (d.maintenance.pick(_ar).isNotEmpty)
        ('prop.f_maintenance'.tr(), d.maintenance.pick(_ar)),
      if (d.referenceCode != null) ('prop.f_reference'.tr(), d.referenceCode!),
    ];
  }

  String _trim(double v) => v % 1 == 0 ? '${v.toInt()}' : '$v';

  Widget _chain(PropertyPageData d) {
    final c = d.compound;
    final dev = d.developer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropLabel('prop.part_of'.tr()),
        if (c != null)
          ChainRow(
            eyebrow: 'prop.compound'.tr(),
            leading: Photo(url: c.image, width: 40, height: 40, radius: 12),
            title: c.name.pick(_ar),
            sub: [
              if (c.unitsCount > 0) 'find.n_units'.plural(c.unitsCount),
              if (c.phasesCount > 0) 'prop.n_phases'.plural(c.phasesCount),
            ].join(' · '),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CompoundPage(compoundId: c.id, name: c.name.pick(_ar)),
              ),
            ),
          ),
        if (c != null && dev != null) const SizedBox(height: 9),
        if (dev != null)
          ChainRow(
            eyebrow: 'prop.developer'.tr(),
            leading: Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JV2.line),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF4F7FB), Color(0xFFE1E8F0)],
                ),
              ),
              child: (dev.logo ?? '').isNotEmpty
                  ? Photo(url: dev.logo, width: 40, height: 40, radius: 12)
                  : Text(
                      _initials(dev.name.pick(_ar)),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JV2.navy,
                      ),
                    ),
            ),
            title: dev.name.pick(_ar),
            verified: dev.isVerified,
            sub: [
              if (dev.compoundsCount > 0)
                'find.n_compounds'.plural(dev.compoundsCount),
              if (dev.unitsCount > 0) 'find.n_units'.plural(dev.unitsCount),
            ].join(' · '),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeveloperPage(
                  developerId: dev.id,
                  name: dev.name.pick(_ar),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  Widget _seller(PropertyPageData d) {
    final name = d.agentName!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropLabel('prop.listed_by'.tr()),
        PropCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [JV2.navyLift, JV2.navy],
                        ),
                      ),
                      child: (d.agentPicture ?? '').isNotEmpty
                          ? Photo(
                              url: d.agentPicture,
                              width: 46,
                              height: 46,
                              radius: 15,
                            )
                          : Text(
                              _initials(name),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    if (d.sellerVerified)
                      Positioned(
                        bottom: -3,
                        right: -3,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: JV2.line),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            size: 11,
                            color: JV2.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: JV2.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'prop.sale_${d.listingType}'.tr(),
                      style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                    ),
                    if (d.sellerVerified) ...[
                      const SizedBox(height: 3),
                      Text(
                        'prop.verified_seller'.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: JV2.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _similarRail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPropPad),
          child: PropLabel('prop.similar'.tr()),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: kPropPad),
            itemCount: _similar.length,
            separatorBuilder: (_, _) => const SizedBox(width: 11),
            itemBuilder: (_, i) {
              final raw = _similar[i];
              final images = raw['images'];
              final image =
                  images is List && images.isNotEmpty && images.first is String
                  ? images.first as String
                  : null;
              final ar = _ar;
              final title =
                  (ar ? raw['title_ar'] : raw['title_en']) as String? ??
                  (raw['title_en'] ?? raw['title_ar'] ?? '') as String;
              final project = raw['compound'] ?? raw['project'];
              final cName = project is Map
                  ? ((ar ? project['name_ar'] : project['name_en']) ??
                            project['name_en'] ??
                            project['name_ar'] ??
                            '')
                        as String
                  : '';
              final size = double.tryParse('${raw['size'] ?? ''}');
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsPage(
                      property: PropertyModel.fromJson(raw),
                    ),
                  ),
                ),
                child: Container(
                  width: 172,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: JV2.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Photo(
                        url: image,
                        height: 106,
                        width: double.infinity,
                        radius: 0,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    money(
                                      context,
                                      double.tryParse('${raw['price'] ?? ''}'),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: JV2.display(context, 17),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'explore.egp'.tr(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: JV2.gold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: JV2.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                cName,
                                if (size != null)
                                  'prop.sqm_unit'.tr(args: ['${size.round()}']),
                              ].where((s) => s.isNotEmpty).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: JV2.inkMute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
