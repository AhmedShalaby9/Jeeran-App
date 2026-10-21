import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/jv2.dart';
import 'ad_flow_widgets.dart';

/// What goes into an exported ad.
class AdArtworkData {
  final String? imageUrl;
  final String head, sub, cta;
  final bool arabic;
  final int width, height; // the pixels of the file
  const AdArtworkData({this.imageUrl, this.head = '', this.sub = '', this.cta = '', this.arabic = false, required this.width, required this.height});
}

const double _base = 390; // the layout is drawn 390 wide and scaled up to the file's real size

/// The ad as a picture for Instagram, WhatsApp, anywhere: the photo, the headline, the subline and the button.
/// (No in-app "Ad ·" label: that belongs to the Explore banner.)
class AdArtwork extends StatelessWidget {
  final AdArtworkData data;
  const AdArtwork({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final h = _base * data.height / data.width;
    final tall = data.height / data.width > 1.2;
    final headSize = tall ? 36.0 : 28.0;
    return Directionality(
      textDirection: data.arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: SizedBox(
        width: _base,
        height: h,
        child: Stack(fit: StackFit.expand, children: [
          if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
            Image.network(data.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: JV2.navyLift))
          else
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [JV2.navyGlow, JV2.goldHi]))),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00081424), Color(0x00081424), Color(0xC7081424)], stops: [0, 0.4, 1]))),
          Positioned(
            left: 28,
            right: 28,
            bottom: tall ? 64 : 30,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(data.head, maxLines: 3, overflow: TextOverflow.ellipsis, style: AdStyles.display(context, headSize).copyWith(color: Colors.white, height: 1.1, letterSpacing: -0.3)),
              if (data.sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(data.sub, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xE6FFFFFF)))),
              if (data.cta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Text(data.cta, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: JV2.navy)),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Renders, saves and shares exported ads. The calls are overridable so tests need no gallery or share sheet.
class AdExporter {
  static Future<Uint8List> Function(BuildContext context, AdArtworkData data)? renderOverride; // tests: no graphics engine
  static Future<void> Function(Uint8List bytes, String name)? saveOverride;
  static Future<void> Function(Uint8List bytes, String name)? shareOverride;

  /// Draws [data] off-screen and returns a PNG of exactly width × height pixels.
  static Future<Uint8List> render(BuildContext context, AdArtworkData data) async {
    if (renderOverride != null) return renderOverride!(context, data);
    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -_base * 3, // painted, but out of sight
        top: 0,
        child: Material(type: MaterialType.transparency, child: RepaintBoundary(key: key, child: AdArtwork(data: data))),
      ),
    );
    overlay.insert(entry);
    try {
      if (data.imageUrl != null && data.imageUrl!.isNotEmpty && context.mounted) {
        try {
          await precacheImage(NetworkImage(data.imageUrl!), context);
        } catch (_) {} // the artwork falls back to a plain colour
      }
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: data.width / _base);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes!.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  static Future<void> save(Uint8List bytes, String name) async {
    if (saveOverride != null) return saveOverride!(bytes, name);
    if (!await Gal.hasAccess()) await Gal.requestAccess();
    await Gal.putImageBytes(bytes, name: name);
  }

  static Future<void> share(Uint8List bytes, String name) async {
    if (shareOverride != null) return shareOverride!(bytes, name);
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: 'image/png', name: '$name.png')], fileNameOverrides: ['$name.png']));
  }
}

/// "Download" and "Share" for the ad on screen, with a language switch when it has both.
class AdDownloadBar extends StatefulWidget {
  /// The artwork for the chosen language (true = Arabic).
  final AdArtworkData Function(bool arabic) data;
  final bool hasEn, hasAr;
  final String fileName;

  /// Every ad of the set, for "Download all": the artwork of each in the chosen language, and its file name.
  final List<(String, AdArtworkData Function(bool arabic))>? all;
  const AdDownloadBar({super.key, required this.data, required this.hasEn, required this.hasAr, required this.fileName, this.all});

  @override
  State<AdDownloadBar> createState() => _AdDownloadBarState();
}

class _AdDownloadBarState extends State<AdDownloadBar> {
  bool? _arabic; // null = follow the app's language
  bool _busy = false;

  bool get _useAr {
    final pick = _arabic ?? (context.locale.languageCode == 'ar');
    if (pick && !widget.hasAr) return false;
    if (!pick && !widget.hasEn) return true;
    return pick;
  }

  Future<void> _run(Future<void> Function(Uint8List, String) action, String doneKey) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final d = widget.data(_useAr);
      final bytes = await AdExporter.render(context, d);
      final name = '${widget.fileName}-${d.width}x${d.height}${_useAr ? '-ar' : ''}';
      await action(bytes, name);
      if (mounted && doneKey.isNotEmpty) AppSnackbar.show(context, message: doneKey.tr(), icon: Icons.check_circle_rounded, iconColor: JV2.success);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: 'adstudio.download_failed'.tr(), icon: Icons.error_outline_rounded, iconColor: JV2.danger);
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Saves every ad of the set, one after the other.
  Future<void> _runAll() async {
    final all = widget.all;
    if (_busy || all == null) return;
    setState(() => _busy = true);
    try {
      for (final (name, build) in all) {
        final d = build(_useAr);
        final bytes = await AdExporter.render(context, d);
        await AdExporter.save(bytes, '$name-${d.width}x${d.height}${_useAr ? '-ar' : ''}');
      }
      if (mounted) AppSnackbar.show(context, message: 'adstudio.downloaded_all'.tr(args: ['${all.length}']), icon: Icons.check_circle_rounded, iconColor: JV2.success);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: 'adstudio.download_failed'.tr(), icon: Icons.error_outline_rounded, iconColor: JV2.danger);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data(_useAr);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.hasEn && widget.hasAr)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text('adstudio.dl_language'.tr(), style: const TextStyle(fontSize: 12, color: JV2.inkSub)),
            const SizedBox(width: 10),
            AdChoice(key: const Key('ad-dl-en'), on: !_useAr, label: 'English', onTap: () => setState(() => _arabic = false)),
            const SizedBox(width: 8),
            AdChoice(key: const Key('ad-dl-ar'), on: _useAr, label: 'العربية', onTap: () => setState(() => _arabic = true)),
          ]),
        ),
      Row(children: [
        Expanded(
          child: _Btn(key: const Key('ad-download'), icon: Icons.download_rounded, label: 'adstudio.download'.tr(), busy: _busy, filled: true, onTap: () => _run(AdExporter.save, 'adstudio.downloaded')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Btn(key: const Key('ad-share'), icon: Icons.ios_share_rounded, label: 'adstudio.share'.tr(), busy: _busy, filled: false, onTap: () => _run(AdExporter.share, '')),
        ),
      ]),
      if (widget.all != null && widget.all!.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _Btn(key: const Key('ad-download-all'), icon: Icons.collections_rounded, label: 'adstudio.download_all'.tr(args: ['${widget.all!.length}']), busy: _busy, filled: false, onTap: _runAll),
        ),
      AdHint('adstudio.download_hint'.tr(args: ['${d.width}', '${d.height}'])),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool busy, filled;
  final VoidCallback onTap;
  const _Btn({super.key, required this.icon, required this.label, required this.busy, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        height: 46,
        decoration: BoxDecoration(color: filled ? JV2.navy : JV2.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: filled ? JV2.navy : const Color(0x330B2A4A))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (busy && filled) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) else Icon(icon, size: 18, color: filled ? Colors.white : JV2.navy),
          const SizedBox(width: 8),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: filled ? Colors.white : JV2.navy))),
        ]),
      ),
    ),
  );
}
