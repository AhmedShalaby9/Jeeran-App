import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/widgets/jv2.dart';
import '../../data/compound_page_data.dart';

/// A compound shown on a satellite map: its outline in red, its master plan drawn over the ground
/// when it has one, and the neighbouring compounds as name pills.
class MapPin {
  final int id;
  final Bi name;
  final LatLng at;

  /// Set when the compound's plan overlaps the screen: a small copy of the plan, where it sits, and the outline.
  final String? planThumb;
  final List<double>? planBounds;
  final List<List<double>> ring;
  const MapPin(this.id, this.name, this.at, {this.planThumb, this.planBounds, this.ring = const []});

  bool get hasPlan => planThumb != null && planBounds != null;

  static MapPin? fromJson(Map<String, dynamic> j) {
    final lat = double.tryParse('${j['latitude']}'), lng = double.tryParse('${j['longitude']}');
    final id = j['id'];
    if (lat == null || lng == null || id is! int) return null;
    final thumb = j['plan_thumb_url'];
    final rings = ringsOf(j['boundary']);
    return MapPin(
      id,
      Bi('${j['name_ar'] ?? ''}', '${j['name_en'] ?? ''}'),
      LatLng(lat, lng),
      planThumb: thumb is String && thumb.isNotEmpty ? thumb : null,
      planBounds: boundsOf(j['plan_bounds']),
      ring: rings.isEmpty ? const [] : rings.first,
    );
  }
}

typedef LoadPins = Future<List<MapPin>> Function(LatLngBounds box);
typedef LoadCompound = Future<CompoundPageData> Function(int id);

/// Plans of neighbouring compounds are drawn only from this zoom (below it they are specks), at most [kMaxPlans] at once.
const kPlanMinZoom = 13.0;
const kMaxPlans = 8;

const _orange = Color(0xFFF0451E);
const _pill = Color(0xFF0B4F8A);

class CompoundMapPage extends StatefulWidget {
  final CompoundPageData compound;

  /// Test hooks; the real ones call the API.
  final LoadPins? loadPins;
  final LoadCompound? loadCompound;
  final bool showTiles;
  final void Function(String number, String text)? openLink;

  const CompoundMapPage({
    super.key,
    required this.compound,
    this.loadPins,
    this.loadCompound,
    this.showTiles = true,
    this.openLink,
  });

  @override
  State<CompoundMapPage> createState() => _CompoundMapPageState();
}

class _CompoundMapPageState extends State<CompoundMapPage> {
  final _map = MapController();
  late CompoundPageData _c = widget.compound;
  List<MapPin> _pins = const [];
  bool _satellite = true;
  Timer? _debounce;
  int _token = 0; // drops answers for a compound the user has already left
  double _zoom = 15;

  bool get _ar => context.locale.languageCode == 'ar';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── geometry ─────────────────────────────────────────────

  List<LatLng> get _ring => _c.boundary.isEmpty ? const [] : [for (final p in _c.boundary.first) LatLng(p[1], p[0])];

  LatLng get _center {
    if (_c.latitude != null && _c.longitude != null) return LatLng(_c.latitude!, _c.longitude!);
    return _ring.isNotEmpty ? _ring.first : const LatLng(30.0444, 31.2357);
  }

  /// What the first view frames: the plan if there is one, else the outline, else a street-level view of the pin.
  CameraFit? _fit() {
    final b = _c.planBounds;
    final pts = b != null ? [LatLng(b[1], b[0]), LatLng(b[3], b[2])] : _ring;
    if (pts.length < 2) return null;
    return CameraFit.coordinates(
      coordinates: pts,
      padding: const EdgeInsets.fromLTRB(28, 110, 28, 300),
      maxZoom: 17,
    );
  }

  // ── neighbours ───────────────────────────────────────────

  /// Neighbouring compounds whose plan is drawn: only when zoomed in enough, never the selected one.
  List<MapPin> get _neighbourPlans {
    if (_zoom < kPlanMinZoom) return const [];
    return [
      for (final p in _pins)
        if (p.hasPlan && p.id != _c.id) p,
    ].take(kMaxPlans).toList();
  }

  void _onMove() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _loadPins);
  }

  Future<void> _loadPins() async {
    if (!mounted) return;
    final cam = _map.camera;
    if (cam.zoom != _zoom) setState(() => _zoom = cam.zoom);
    if (cam.zoom < 11) {
      if (_pins.isNotEmpty) setState(() => _pins = const []);
      return;
    }
    try {
      final pins = await (widget.loadPins ?? _fetchPins)(cam.visibleBounds);
      if (mounted) setState(() => _pins = pins);
    } catch (_) {} // the pills are a nicety; the map stays usable without them
  }

  Future<List<MapPin>> _fetchPins(LatLngBounds b) async {
    final res = await sl<ApiClient>().get(
      '/compounds/map',
      queryParams: {'bbox': '${b.west},${b.south},${b.east},${b.north}', 'limit': 60, 'plans': kMaxPlans},
    );
    final raw = res.data['data'];
    return [
      if (raw is List)
        for (final j in raw.whereType<Map<String, dynamic>>()) ?MapPin.fromJson(j),
    ];
  }

  Future<CompoundPageData> _fetchCompound(int id) async {
    final res = await sl<ApiClient>().get('/compounds/$id', headers: ApiClient.apiV2);
    return CompoundPageData.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> _select(MapPin pin) async {
    final mine = ++_token;
    try {
      final next = await (widget.loadCompound ?? _fetchCompound)(pin.id);
      if (!mounted || mine != _token) return;
      setState(() => _c = next);
      final fit = _fit();
      if (fit != null) {
        _map.fitCamera(fit);
      } else {
        _map.move(_center, 16);
      }
    } catch (_) {}
  }

  // ── contact ──────────────────────────────────────────────

  Future<void> _call() async {
    final n = AppSettingsService.instance.contactPhone;
    if (n == null) return;
    if (widget.openLink != null) return widget.openLink!('tel:$n', '');
    await launchUrl(Uri(scheme: 'tel', path: n));
  }

  Future<void> _whatsapp() async {
    final n = AppSettingsService.instance.contactPhone;
    if (n == null) return;
    final text = 'map.wa_text'.tr(args: [_c.name.pick(_ar)]);
    if (widget.openLink != null) return widget.openLink!(n, text);
    final digits = n.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    await launchUrl(Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication);
  }

  // ── build ────────────────────────────────────────────────

  String get _style => _satellite ? 'satellite-streets-v12' : 'streets-v12';

  @override
  Widget build(BuildContext context) {
    final fit = _fit();
    final pb = _c.planBounds;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              initialCameraFit: fit,
              minZoom: 5,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onMapReady: _loadPins,
              onMapEvent: (e) {
                if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd || e is MapEventDoubleTapZoomEnd || e is MapEventScrollWheelZoom) _onMove();
              },
            ),
            children: [
              if (widget.showTiles)
                TileLayer(
                  key: ValueKey(_style),
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/$_style/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxToken}',
                  userAgentPackageName: 'com.jeeran.realestate',
                  maxNativeZoom: 19,
                ),
              if (_neighbourPlans.isNotEmpty) ...[
                OverlayImageLayer(
                  key: const Key('neighbour-plans'),
                  overlayImages: [
                    for (final p in _neighbourPlans)
                      OverlayImage(
                        bounds: LatLngBounds(LatLng(p.planBounds![1], p.planBounds![0]), LatLng(p.planBounds![3], p.planBounds![2])),
                        imageProvider: CachedNetworkImageProvider(p.planThumb!),
                      ),
                  ],
                ),
                PolygonLayer(
                  polygons: [
                    for (final p in _neighbourPlans)
                      if (p.ring.length >= 3)
                        Polygon(
                          points: [for (final q in p.ring) LatLng(q[1], q[0])],
                          color: const Color(0x00000000),
                          borderColor: const Color(0xB3E0401C),
                          borderStrokeWidth: 1.2,
                        ),
                  ],
                ),
              ],
              if (_c.planUrl != null && pb != null)
                OverlayImageLayer(
                  key: const Key('plan-overlay'),
                  overlayImages: [
                    OverlayImage(
                      bounds: LatLngBounds(LatLng(pb[1], pb[0]), LatLng(pb[3], pb[2])),
                      imageProvider: CachedNetworkImageProvider(_c.planUrl!),
                    ),
                  ],
                ),
              if (_ring.isNotEmpty)
                PolygonLayer(
                  key: const Key('outline'),
                  polygons: [
                    Polygon(
                      points: _ring,
                      color: const Color(0x14F0451E),
                      borderColor: const Color(0xFFE0401C),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final p in _pins)
                    if (p.id != _c.id)
                      Marker(
                        point: p.at,
                        width: 170,
                        height: 38,
                        alignment: Alignment.topCenter,
                        child: _NamePill(key: Key('pin-${p.id}'), text: p.name.pick(_ar), color: _pill, onTap: () => _select(p)),
                      ),
                  Marker(
                    point: _center,
                    width: 190,
                    height: 38,
                    alignment: Alignment.topCenter,
                    child: _NamePill(key: const Key('pin-selected'), text: _c.name.pick(_ar), color: _orange),
                  ),
                ],
              ),
            ],
          ),
          // top buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _RoundBtn(key: const Key('map-close'), icon: Icons.close_rounded, onTap: () => Navigator.maybePop(context)),
                  const Spacer(),
                  _RoundBtn(
                    key: const Key('map-layers'),
                    icon: _satellite ? Icons.map_outlined : Icons.satellite_alt_rounded,
                    onTap: () => setState(() => _satellite = !_satellite),
                  ),
                ],
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomCard()),
        ],
      ),
    );
  }

  Widget _bottomCard() {
    final area = _c.area.pick(_ar);
    final hasPhone = AppSettingsService.instance.contactPhone != null;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: const Key('map-sheet'),
          color: const Color(0xE6FFFFFF),
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).padding.bottom + 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _Logo(url: _c.developer?.logo),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (area.isNotEmpty) Text(area, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: JV2.inkSub)),
                        Text(
                          _c.name.pick(_ar),
                          key: const Key('map-name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: JV2.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasPhone) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CtaBtn(key: const Key('map-call'), icon: Icons.call_rounded, label: 'map.call_us'.tr(), bg: const Color(0xFFEFF3F8), fg: JV2.navy, onTap: _call),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CtaBtn(key: const Key('map-whatsapp'), icon: Icons.chat_rounded, label: 'map.whatsapp'.tr(), bg: const Color(0xFF3DD360), fg: Colors.white, onTap: _whatsapp),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NamePill extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;
  const _NamePill({super.key, required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          CustomPaint(size: const Size(12, 6), painter: _Tail(color)),
        ],
      ),
    );
  }
}

class _Tail extends CustomPainter {
  final Color color;
  _Tail(this.color);
  @override
  void paint(Canvas c, Size s) => c.drawPath(
    Path()..moveTo(0, 0)..lineTo(s.width, 0)..lineTo(s.width / 2, s.height)..close(),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_Tail o) => o.color != color;
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xB3000000),
    shape: const CircleBorder(),
    child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 48, height: 48, child: Icon(icon, color: Colors.white, size: 24))),
  );
}

class _Logo extends StatelessWidget {
  final String? url;
  const _Logo({this.url});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: JV2.surface),
    child: (url == null || url!.isEmpty)
        ? const Icon(Icons.apartment_rounded, color: JV2.inkMute)
        : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.apartment_rounded, color: JV2.inkMute)),
  );
}

class _CtaBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _CtaBtn({super.key, required this.icon, required this.label, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: bg,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: fg, size: 24), const SizedBox(width: 8), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w700)))],
        ),
      ),
    ),
  );
}
