import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection_container.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import '../../core/widgets/jv2.dart';
import '../explore/presentation/widgets/explore_widgets.dart' show Photo, isRtl;
import '../properties/presentation/pages/my_properties_page.dart';
import '../voice/voice_api.dart';
import '../voice/voice_services.dart';
import '../you/you_api.dart';
import 'listing_api.dart';
import 'listing_draft.dart';
import 'listing_widgets.dart';
import 'shortcut_page.dart';

enum ListingView { start, assistant, form, review, done }

/// List a property: tell Jeeran about it, or fill four short steps — both end on the same draft,
/// which the seller reviews before anything goes live.
class ListingFlow extends StatefulWidget {
  final ListingApi? api;
  final YouApi? youApi;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  final VoiceSpeaker? speaker;

  /// Tests and deep links can start mid-way.
  final ListingDraft? initialDraft;
  final ListingView initialView;
  final int initialStep;

  /// Edit this listing instead of creating one.
  final int? editId;
  const ListingFlow({
    this.editId,
    super.key,
    this.api,
    this.youApi,
    this.recorder,
    this.voiceApi,
    this.speaker,
    this.initialDraft,
    this.initialView = ListingView.start,
    this.initialStep = 1,
  });

  /// Open as a full-screen modal. Only sellers and admins may list.
  static Future<void> open(BuildContext context) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const ListingFlow(),
    ),
  );

  /// Edit one of the seller's own listings.
  static Future<bool?> edit(BuildContext context, int id) =>
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              ListingFlow(editId: id, initialView: ListingView.form),
        ),
      );

  @override
  State<ListingFlow> createState() => _ListingFlowState();
}

class _ListingFlowState extends State<ListingFlow> {
  late final ListingApi _api = widget.api ?? ListingApi(sl<ApiClient>());
  late final YouApi _you = widget.youApi ?? YouApi(sl<ApiClient>());
  late ListingDraft _d = widget.initialDraft ?? ListingDraft();
  late ListingView _view = widget.initialView;
  late int _step = widget.initialStep;
  YouSummary? _me;
  ListingDraft? _saved;

  PriceBand? _band;
  bool _bandLoading = false;
  bool _writing = false;
  String? _progress;
  bool _publishing = false;
  bool _loadingEdit = false;
  bool _editFailed = false;
  bool _coverBusy = false;
  bool _wentToReview = false; // an edit that sent the listing back for a check
  final Map<String, String> _uploaded =
      {}; // local path → URL, so nothing uploads twice
  bool get _editing => widget.editId != null;

  bool get _ar => context.locale.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadMe();
    if (_editing) {
      _loadEdit();
    } else {
      _loadSaved();
    }
  }

  Future<void> _loadEdit() async {
    setState(() {
      _loadingEdit = true;
      _editFailed = false;
    });
    try {
      final j = await _api.property(widget.editId!);
      if (!mounted) return;
      setState(() {
        _d = ListingDraft.fromProperty(j, ar: _ar);
        _view = ListingView.form;
        _step = 1;
        _loadingEdit = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingEdit = false;
          _editFailed = true;
        });
      }
    }
  }

  Future<void> _loadMe() async {
    try {
      final s = await _you.summary();
      if (mounted) setState(() => _me = s);
    } catch (_) {}
  }

  Future<void> _loadSaved() async {
    try {
      final raw = AppStorage.listingDraft;
      if (raw == null) return;
      final d = ListingDraft.fromStore(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (!d.isBlank && mounted) setState(() => _saved = d);
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      await AppStorage.setListingDraft(jsonEncode(_d.toStore()));
      _toast('listing.draft_saved'.tr());
    } catch (_) {}
  }

  Future<void> _clearSaved() async {
    try {
      await AppStorage.setListingDraft(null);
    } catch (_) {}
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        // above the primary button, never over it
        margin: const EdgeInsets.fromLTRB(kListPad, 0, kListPad, 110),
      ),
    );

  /// A field the seller edits is theirs now: its Jeeran mark goes.
  void _touch(String key, VoidCallback change) => setState(() {
    change();
    _d.ai.remove(key);
  });

  // ── navigation ─────────────────────────────────────────────

  void _back() {
    switch (_view) {
      case ListingView.start:
      case ListingView.done:
        Navigator.maybePop(context);
      case ListingView.assistant:
        setState(() => _view = ListingView.start);
      case ListingView.form:
        if (_step == 1) {
          _editing
              ? Navigator.maybePop(context)
              : setState(() => _view = ListingView.start);
        } else {
          setState(() => _step--);
        }
      case ListingView.review:
        setState(() {
          _view = ListingView.form;
          _step = 4;
        });
    }
  }

  bool _stepValid() => switch (_step) {
    1 => _d.basicsValid,
    2 => _d.detailsValid,
    3 => _d.priceValid,
    _ => _d.mediaValid,
  };

  String _stepError() => switch (_step) {
    1 => 'listing.err_basics'.tr(),
    2 => 'listing.err_details'.tr(),
    3 => 'listing.err_price'.tr(),
    _ => 'listing.err_media'.tr(),
  };

  void _next() {
    if (!_stepValid()) {
      _toast(_stepError());
      return;
    }
    if (_step == 4) {
      setState(() => _view = ListingView.review);
    } else {
      setState(() => _step++);
      if (_step == 3) _loadBand();
    }
  }

  Future<void> _loadBand() async {
    if (_d.compound == null) return;
    setState(() => _bandLoading = true);
    try {
      final b = await _api.priceBand(_d);
      if (mounted) setState(() => _band = b);
    } catch (_) {
      if (mounted) setState(() => _band = null);
    } finally {
      if (mounted) setState(() => _bandLoading = false);
    }
  }

  void _goStep(int s) => setState(() {
    _view = ListingView.form;
    _step = s;
    if (s == 3) _loadBand();
  });

  // ── actions ────────────────────────────────────────────────

  Future<void> _pickCompound() async {
    final picked = await showModalBottomSheet<CompoundRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JV2.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CompoundPicker(api: _api, ar: _ar),
    );
    if (picked != null) _touch('compound', () => _d.compound = picked);
  }

  Future<void> _addPhotos() async {
    try {
      final room = 20 - _d.photos.length;
      if (room <= 0) return;
      final files = await ImagePicker().pickMultiImage(limit: room);
      if (files.isNotEmpty) setState(() => _d.photos.addAll(files.take(room)));
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (f != null) setState(() => _d.video = f);
    } catch (_) {}
  }

  Future<void> _pickPlan() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (f != null) setState(() => _d.floorPlan = f);
    } catch (_) {}
  }

  Future<void> _writeForMe() async {
    if (_writing) return;
    setState(() => _writing = true);
    try {
      final r = await _api.describe(_d, _ar ? 'ar' : 'en');
      if (!mounted) return;
      setState(() {
        if (r.title.isNotEmpty) _d.title = r.title;
        if (r.description.isNotEmpty) _d.description = r.description;
        _d.ai.addAll(['title', 'desc']);
      });
    } catch (_) {
      if (mounted) _toast('listing.write_failed'.tr());
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  /// Uploads a local file once; later calls (cover, publish) reuse the URL.
  Future<String> _upload(String path) async =>
      _uploaded[path] ??= await _api.upload(path);

  /// Makes a free cover from up to five of the seller's photos (uploading new ones first).
  Future<void> _makeCover() async {
    if (_coverBusy || _d.photoCount == 0) return;
    setState(() => _coverBusy = true);
    try {
      final sources = <String>[..._d.existingImages];
      for (final p in _d.photos) {
        if (sources.length >= 5) break;
        sources.add(await _upload(p.path));
      }
      final url = await _api.cover(sources.take(5).toList());
      if (mounted) setState(() => _d.coverUrl = url);
    } on ServerException catch (e) {
      if (mounted) _toast(e.message ?? 'listing.cover_failed'.tr());
    } catch (_) {
      if (mounted) _toast('listing.cover_failed'.tr());
    } finally {
      if (mounted) setState(() => _coverBusy = false);
    }
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      final urls = <String>[..._d.existingImages];
      for (var i = 0; i < _d.photos.length; i++) {
        setState(
          () => _progress = 'listing.uploading'.tr(
            args: ['${i + 1}', '${_d.photos.length}'],
          ),
        );
        urls.add(await _upload(_d.photos[i].path));
      }
      String? video, plan;
      if (_d.video != null) {
        setState(() => _progress = 'listing.uploading_video'.tr());
        video = await _api.upload(_d.video!.path);
      }
      if (_d.floorPlan != null) plan = await _api.upload(_d.floorPlan!.path);
      setState(
        () => _progress = _editing
            ? 'listing.saving'.tr()
            : 'listing.publishing'.tr(),
      );
      final body = _d.toBody(
        images: urls,
        ar: _ar,
        admin: AppStorage.isAdmin,
        videoUrl: video,
        floorPlanUrl: plan,
        agentName: _me?.name,
        agentPhone: _me?.phone,
        agentEmail: _me?.email,
      );
      if (_editing) {
        _wentToReview = await _api.update(widget.editId!, body);
      } else {
        await _api.create(body);
        await _clearSaved();
        await _loadMe(); // the plan now shows one more used
      }
      if (mounted) setState(() => _view = ListingView.done);
    } on ServerException catch (e) {
      if (mounted) _toast(e.message ?? 'listing.publish_failed'.tr());
    } catch (_) {
      if (mounted) _toast('listing.publish_failed'.tr());
    } finally {
      if (mounted)
        setState(() {
          _publishing = false;
          _progress = null;
        });
    }
  }

  void _goMine() {
    if (_editing) {
      Navigator.pop(context, true); // back to the list, which refreshes
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyPropertiesPage()),
    );
  }

  // ── build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case ListingView.assistant:
        return ShortcutPage(
          draft: _d,
          api: _api,
          recorder: widget.recorder,
          voiceApi: widget.voiceApi,
          onClose: () => setState(() => _view = ListingView.start),
          onReview: () => setState(() => _view = ListingView.review),
          onOpenForm: () => setState(() {
            _view = ListingView.form;
            _step = 1;
          }),
        );
      case ListingView.done:
        return _done();
      default:
        return Scaffold(
          backgroundColor: JV2.bgDeep,
          body: Column(
            children: [
              _header(),
              Expanded(child: _body()),
              if (_view != ListingView.start && !_loadingEdit && !_editFailed)
                _footer(),
            ],
          ),
        );
    }
  }

  // header: back, title, "Save draft", step bar, and the AI count
  Widget _header() {
    final top = MediaQuery.paddingOf(context).top;
    final form = _view == ListingView.form;
    final review = _view == ListingView.review;
    final aiHere = form ? _aiOnStep(_step) : 0;
    return Container(
      padding: EdgeInsets.fromLTRB(kListPad, top + 8, kListPad, 14),
      decoration: const BoxDecoration(
        color: Color(0xF0FAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              JV2BackButton(onPressed: _back),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review
                          ? 'listing.review_title'.tr()
                          : (_editing
                                ? 'listing.edit_title'.tr()
                                : 'listing.title'.tr()),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: JV2.ink,
                      ),
                    ),
                    if (form)
                      Text(
                        'listing.step_of'.tr(
                          args: ['$_step', 'listing.s$_step'.tr()],
                        ),
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
              if (_view != ListingView.start && !_editing)
                GestureDetector(
                  key: const Key('save-draft'),
                  onTap: _saveDraft,
                  child: Text(
                    'listing.save_draft'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JV2.inkSub,
                    ),
                  ),
                ),
            ],
          ),
          if (form) ...[
            const SizedBox(height: 14),
            JV2StepBar(step: _step, total: 4),
          ],
          if (aiHere > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: JV2.goldFilm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JV2.goldEdge),
              ),
              child: Row(
                children: [
                  const SparkIcon(size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'listing.ai_banner'.plural(aiHere),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _stepKeys = <int, List<String>>{
    1: ['type', 'status', 'compound'],
    2: [
      'bedrooms',
      'bathrooms',
      'size',
      'level',
      'finishing',
      'delivery',
      'view',
    ],
    3: ['price', 'payment', 'down', 'years'],
    4: ['title', 'desc'],
  };

  int _aiOnStep(int s) => _stepKeys[s]!.where(_d.ai.contains).length;

  Widget _footer() {
    final review = _view == ListingView.review;
    final left = _me?.plan?.left;
    final label = review
        ? (_editing ? 'listing.save_changes'.tr() : 'listing.publish'.tr())
        : _step == 4
        ? 'listing.review'.tr()
        : 'listing.continue'.tr();
    return Container(
      padding: const EdgeInsets.fromLTRB(kListPad, 12, kListPad, 18),
      decoration: const BoxDecoration(
        color: Color(0xF5FAFBFD),
        border: Border(top: BorderSide(color: JV2.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (review && !_editing && (left != null || _d.ai.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  [
                    if (_d.ai.isNotEmpty) 'listing.marked_note'.tr(),
                    if (left != null) 'listing.uses_one'.tr(args: ['$left']),
                  ].join(' '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                ),
              ),
            JV2PrimaryButton(
              key: const Key('listing-primary'),
              onPressed: _publishing ? null : (review ? _publish : _next),
              child: Text(_progress ?? label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loadingEdit || _editFailed) {
      return Center(
        child: _editFailed
            ? TextButton(
                onPressed: _loadEdit,
                child: Text('listing.load_failed'.tr()),
              )
            : const CircularProgressIndicator(
                strokeWidth: 2,
                color: JV2.goldHi,
              ),
      );
    }
    return switch (_view) {
      ListingView.start => _start(),
      ListingView.review => _scroll(_review()),
      _ => _scroll(switch (_step) {
        1 => _stepBasics(),
        2 => _stepDetails(),
        3 => _stepPrice(),
        _ => _stepMedia(),
      }),
    };
  }

  Widget _scroll(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(kListPad, 20, kListPad, 24),
    child: child,
  );

  // ── start ──────────────────────────────────────────────────

  Widget _start() {
    final plan = _me?.plan;
    return ListView(
      padding: const EdgeInsets.fromLTRB(kListPad, 24, kListPad, 24),
      children: [
        Text('listing.start_title'.tr(), style: JV2.display(context, 28)),
        const SizedBox(height: 12),
        Text('listing.start_sub'.tr(), style: JV2.sub),
        const SizedBox(height: 20),
        if (_saved != null) ...[
          GestureDetector(
            key: const Key('resume-draft'),
            onTap: () => setState(() {
              _d = _saved!;
              _saved = null;
              _view = ListingView.form;
              _step = 1;
            }),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: JV2.goldFilm,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JV2.goldEdge),
              ),
              child: Row(
                children: [
                  const SparkIcon(size: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'listing.resume'.tr(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  Icon(
                    isRtl(context)
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: JV2.inkSub,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        GestureDetector(
          key: const Key('path-ai'),
          onTap: () => setState(() => _view = ListingView.assistant),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [JV2.navyLift, JV2.navy],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D0B2A4A),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SparkIcon(size: 14, color: Color(0xFFE5C48F)),
                    const SizedBox(width: 8),
                    Text(
                      'listing.about_minute'.tr().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: Color(0xFFE5C48F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'listing.ai_title'.tr(),
                  style: JV2.display(context, 23).copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'listing.ai_sub'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xC7FFFFFF),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final k in const ['speak', 'type'])
                      Container(
                        margin: const EdgeInsetsDirectional.only(end: 8),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x24FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Text(
                          'listing.$k'.tr(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          key: const Key('path-form'),
          onTap: () => setState(() {
            _view = ListingView.form;
            _step = 1;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: JV2.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'listing.form_title'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'listing.form_sub'.tr(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isRtl(context)
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: JV2.inkSub,
                ),
              ],
            ),
          ),
        ),
        if (plan != null) ...[
          const SizedBox(height: 18),
          Center(
            child: Text(
              'listing.plan_line'.tr(
                args: [plan.name(_ar), '${plan.used}', '${plan.total}'],
              ),
              style: const TextStyle(fontSize: 12, color: JV2.inkSub),
            ),
          ),
        ],
      ],
    );
  }

  // ── steps ──────────────────────────────────────────────────

  Widget _gap(List<Widget> kids) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < kids.length; i++) ...[
        if (i > 0) const SizedBox(height: 20),
        kids[i],
      ],
    ],
  );

  Widget _stepBasics() {
    final c = _d.compound;
    return _gap([
      ChipPicker(
        label: 'listing.f_type'.tr(),
        cols: 3,
        ai: _d.ai.contains('type'),
        value: _d.type,
        options: [for (final t in ListingDraft.types) (t, 'listing.t_$t'.tr())],
        onChanged: (v) => _touch('type', () => _d.type = v),
      ),
      ChipPicker(
        label: 'listing.f_purpose'.tr(),
        cols: 2,
        ai: _d.ai.contains('status'),
        value: _d.status,
        options: [
          ('for_sale', 'listing.sale'.tr()),
          ('for_rent', 'listing.rent'.tr()),
        ],
        onChanged: (v) => _touch('status', () => _d.status = v ?? 'for_sale'),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel('listing.f_compound'.tr(), ai: _d.ai.contains('compound')),
          GestureDetector(
            key: const Key('pick-compound'),
            onTap: _pickCompound,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _d.ai.contains('compound')
                    ? const Color(0x0FB8893D)
                    : JV2.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _d.ai.contains('compound') ? JV2.goldEdge : JV2.line,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        colors: [Color(0x471A4A80), Color(0x38B8893D)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: c == null
                        ? Text(
                            'listing.choose_compound'.tr(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: JV2.inkMute,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name(_ar),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: JV2.ink,
                                ),
                              ),
                              if (c.sub(_ar).isNotEmpty)
                                Text(
                                  c.sub(_ar),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: JV2.inkSub,
                                  ),
                                ),
                            ],
                          ),
                  ),
                  Text(
                    (c == null ? 'listing.choose' : 'listing.change').tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JV2.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              'listing.compound_note'.tr(),
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: JV2.inkSub,
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _stepDetails() {
    return _gap([
      if (!_d.noRooms)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CounterField(
                label: 'listing.f_beds'.tr(),
                value: _d.bedrooms,
                ai: _d.ai.contains('bedrooms'),
                onChanged: (v) => _touch('bedrooms', () {
                  _d.bedrooms = v;
                  _d.bedroomsSet = true;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CounterField(
                label: 'listing.f_baths'.tr(),
                value: _d.bathrooms,
                ai: _d.ai.contains('bathrooms'),
                onChanged: (v) => _touch('bathrooms', () {
                  _d.bathrooms = v;
                  _d.bathroomsSet = true;
                }),
              ),
            ),
          ],
        ),
      ListingInput(
        fieldKey: const Key('f-size'),
        label: 'listing.f_size'.tr(),
        value: _d.size,
        suffix: 'm²',
        numeric: true,
        ai: _d.ai.contains('size'),
        onChanged: (v) => _touch('size', () => _d.size = v),
      ),
      ListingInput(
        label: 'listing.f_floor'.tr(),
        value: _d.level,
        optional: true,
        ai: _d.ai.contains('level'),
        onChanged: (v) => _touch('level', () => _d.level = v),
      ),
      ChipPicker(
        label: 'listing.f_finishing'.tr(),
        cols: 2,
        clearable: true,
        ai: _d.ai.contains('finishing'),
        value: _d.finishing,
        options: [
          for (final f in ListingDraft.finishings) (f, 'listing.fin_$f'.tr()),
        ],
        onChanged: (v) => _touch('finishing', () => _d.finishing = v),
      ),
      ChipPicker(
        label: 'listing.f_delivery'.tr(),
        cols: 2,
        clearable: true,
        ai: _d.ai.contains('delivery'),
        value: _d.delivery,
        options: [
          for (final x in ListingDraft.deliveries)
            (
              x,
              x == 'ready'
                  ? 'listing.d_ready'.tr()
                  : (x == '2029' ? '2029+' : x),
            ),
        ],
        onChanged: (v) => _touch('delivery', () => _d.delivery = v),
      ),
      ChipPicker(
        label: 'listing.f_view'.tr(),
        clearable: true,
        ai: _d.ai.contains('view'),
        value: _d.view,
        options: [for (final v in ListingDraft.views) (v, 'listing.v_$v'.tr())],
        onChanged: (v) => _touch('view', () => _d.view = v),
      ),
    ]);
  }

  Widget _stepPrice() {
    final plan = _d.plan;
    return _gap([
      ListingInput(
        fieldKey: const Key('f-price'),
        label: 'listing.f_price'.tr(),
        value: _d.price,
        prefix: 'EGP',
        numeric: true,
        ai: _d.ai.contains('price'),
        onChanged: (v) => setState(() {
          _d.price = v;
          _d.ai.remove('price');
        }),
      ),
      _bandCard(),
      ChipPicker(
        label: 'listing.f_payment'.tr(),
        cols: 2,
        ai: _d.ai.contains('payment'),
        value: _d.payment,
        options: [
          ('cash', 'listing.cash'.tr()),
          ('installments', 'listing.installments'.tr()),
        ],
        onChanged: (v) => _touch('payment', () => _d.payment = v ?? 'cash'),
      ),
      if (_d.payment == 'installments') ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListingInput(
                label: 'listing.f_down'.tr(),
                value: _d.down,
                suffix: '%',
                numeric: true,
                ai: _d.ai.contains('down'),
                onChanged: (v) => _touch('down', () => _d.down = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ListingInput(
                label: 'listing.f_over'.tr(),
                value: _d.years,
                suffix: 'listing.years'.tr(),
                numeric: true,
                ai: _d.ai.contains('years'),
                onChanged: (v) => _touch('years', () => _d.years = v),
              ),
            ),
          ],
        ),
        if (plan != null)
          Container(
            decoration: BoxDecoration(
              color: JV2.fillFaint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: JV2.line),
            ),
            child: Row(
              children: [
                for (final (i, e) in [
                  ('listing.down'.tr(), money(plan.down)),
                  ('listing.monthly'.tr(), money(plan.monthly)),
                  ('listing.total'.tr(), money(plan.total)),
                ].indexed)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : const BorderDirectional(
                                start: BorderSide(color: JV2.line),
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: JV2.inkSub,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            e.$2,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: JV2.ink,
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
    ]);
  }

  /// Where this price sits among similar live units — real numbers or an honest "nothing to compare".
  Widget _bandCard() {
    final b = _band;
    final mine = _d.priceValue;
    final title = 'listing.band_title'.tr(
      args: [_d.compound?.name(_ar) ?? '', '${b?.count ?? 0}'],
    );
    return Container(
      key: const Key('band-card'),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JV2.line),
      ),
      child: _bandLoading
          ? const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: JV2.goldHi,
                  ),
                ),
              ),
            )
          : (b == null || b.count == 0)
          ? Text(
              'listing.band_none'.tr(),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: JV2.inkSub,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: JV2.inkSub,
                  ),
                ),
                const SizedBox(height: 12),
                _BandBar(band: b, mine: mine),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      money(b.min!),
                      style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                    ),
                    Flexible(
                      child: Text(
                        mine != null
                            ? 'listing.band_yours'.tr(
                                args: [money(mine), money(b.median!)],
                              )
                            : 'listing.band_median'.tr(
                                args: [money(b.median!)],
                              ),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                    Text(
                      money(b.max!),
                      style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// Existing (server) photos first, then the ones just picked.
  Widget _photoTile(int i) {
    final existing = i < _d.existingImages.length;
    final Widget img = existing
        ? Image.network(
            _d.existingImages[i],
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: JV2.fillHi),
          )
        : Image.file(
            File(_d.photos[i - _d.existingImages.length].path),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: JV2.fillHi),
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
        if (i == 0 && !_d.coverIsAi)
          PositionedDirectional(
            start: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: JV2.navy,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'listing.cover'.tr(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        PositionedDirectional(
          end: 4,
          top: 4,
          child: GestureDetector(
            key: Key('remove-photo-$i'),
            onTap: () => setState(() {
              if (existing) {
                _d.existingImages.removeAt(i);
              } else {
                _d.photos.removeAt(i - _d.existingImages.length);
              }
            }),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0x99000000),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The cover buyers see first: a Jeeran-made one from the seller's photos, or simply the first photo.
  Widget _coverCard() {
    final has = _d.coverIsAi;
    Widget btn(String key, String label, VoidCallback? onTap) => Expanded(
      child: GestureDetector(
        key: Key(key),
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JV2.fillFaint,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: JV2.line),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: onTap == null ? JV2.inkMute : JV2.ink,
            ),
          ),
        ),
      ),
    );
    return Column(
      key: const Key('cover-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel('listing.cover_title'.tr(), ai: has),
        Container(
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: has ? JV2.goldEdge : JV2.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (has || _coverBusy)
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (has)
                        Image.network(
                          _d.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: JV2.fillHi),
                        )
                      else
                        const ColoredBox(color: JV2.fillHi),
                      if (_coverBusy)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: JV2.gold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'listing.cover_building'.tr(
                                  args: ['${_d.photoCount.clamp(1, 5)}'],
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: JV2.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (has
                              ? 'listing.cover_ai_note'
                              : 'listing.cover_free_note')
                          .tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: JV2.inkSub,
                      ),
                    ),
                    if (!_coverBusy) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: has
                            ? [
                                btn(
                                  'cover-regen',
                                  'listing.cover_regen'.tr(),
                                  _makeCover,
                                ),
                                const SizedBox(width: 8),
                                btn(
                                  'cover-own',
                                  'listing.cover_own'.tr(),
                                  () => setState(() => _d.coverUrl = null),
                                ),
                              ]
                            : [
                                btn(
                                  'cover-make',
                                  'listing.cover_make'.tr(),
                                  _d.photoCount == 0 ? null : _makeCover,
                                ),
                              ],
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

  Widget _stepMedia() {
    return _gap([
      _coverCard(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel('listing.photos_n'.tr(args: ['${_d.photoCount}', '20'])),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < _d.photoCount; i++) _photoTile(i),
              if (_d.photoCount < 20)
                GestureDetector(
                  key: const Key('add-photos'),
                  onTap: _addPhotos,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: JV2.goldEdge, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          size: 20,
                          color: JV2.navy,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'listing.add'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: JV2.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'listing.cover_note'.tr(),
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: JV2.inkSub,
              ),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: _AddChip(
              label: 'listing.floor_plan'.tr(),
              done: _d.floorPlan != null,
              onTap: _pickPlan,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AddChip(
              label: 'listing.video'.tr(),
              done: _d.video != null,
              onTap: _pickVideo,
            ),
          ),
        ],
      ),
      ListingInput(
        fieldKey: const Key('f-title'),
        label: 'listing.f_title'.tr(),
        value: _d.title,
        ai: _d.ai.contains('title'),
        onChanged: (v) => _touch('title', () => _d.title = v),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'listing.f_desc'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JV2.ink,
                  ),
                ),
              ),
              if (_d.ai.contains('desc'))
                const AiTag()
              else
                GestureDetector(
                  key: const Key('write-for-me'),
                  onTap: _writeForMe,
                  child: Row(
                    children: [
                      const SparkIcon(size: 11),
                      const SizedBox(width: 5),
                      Text(
                        _writing
                            ? 'listing.writing'.tr()
                            : 'listing.write_for_me'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: JV2.gold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ListingInput(
            fieldKey: const Key('f-desc'),
            label: '',
            value: _d.description,
            multiline: true,
            ai: _d.ai.contains('desc'),
            onChanged: (v) => _touch('desc', () => _d.description = v),
          ),
        ],
      ),
    ]);
  }

  // ── review & done ──────────────────────────────────────────

  Widget _block(String title, int step, List<(String, String, String)> rows) {
    return Container(
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JV2.line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  key: Key('edit-$step'),
                  onTap: () => _goStep(step),
                  child: Text(
                    'listing.edit'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JV2.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: JV2.line)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      r.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  if (_d.ai.contains(r.$3)) const SparkIcon(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _review() {
    final c = _d.compound;
    final price = _d.priceValue;
    return _gap([
      Container(
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
          boxShadow: JV2.shadowMd,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_d.coverIsAi)
                    Image.network(
                      _d.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: JV2.fillHi),
                    )
                  else if (_d.existingImages.isNotEmpty)
                    Image.network(
                      _d.existingImages.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: JV2.fillHi),
                    )
                  else if (_d.photos.isNotEmpty)
                    Image.file(
                      File(_d.photos.first.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: JV2.fillHi),
                    )
                  else
                    const Photo(radius: 0),
                  if (_d.coverIsAi)
                    PositionedDirectional(
                      end: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xA0000000),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SparkIcon(size: 9, color: Color(0xFFE5C48F)),
                            const SizedBox(width: 4),
                            Text(
                              'listing.ai_cover'.tr(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    start: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEBFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'listing.how_buyers'.tr(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price == null ? '—' : 'EGP ${money(price)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _d.title,
                    style: const TextStyle(fontSize: 13.5, color: JV2.ink),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (!_d.noRooms)
                        'listing.beds_baths'.tr(
                          args: ['${_d.bedrooms}', '${_d.bathrooms}'],
                        ),
                      '${_d.size} m²',
                      if (c != null) c.name(_ar),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _block('listing.s1'.tr(), 1, [
        (
          'listing.f_type'.tr(),
          '${_d.type == null ? '' : 'listing.t_${_d.type}'.tr()} · ${_d.status == 'for_rent' ? 'listing.rent'.tr() : 'listing.sale'.tr()}',
          'type',
        ),
        (
          'listing.f_compound'.tr(),
          c == null
              ? '—'
              : [
                  c.name(_ar),
                  c.sub(_ar),
                ].where((s) => s.isNotEmpty).join(' · '),
          'compound',
        ),
      ]),
      _block('listing.s2'.tr(), 2, [
        if (!_d.noRooms)
          (
            'listing.rooms'.tr(),
            'listing.beds_baths'.tr(
              args: ['${_d.bedrooms}', '${_d.bathrooms}'],
            ),
            'bedrooms',
          ),
        ('listing.f_size'.tr(), '${_d.size} m²', 'size'),
        if (_d.level.trim().isNotEmpty)
          ('listing.f_floor'.tr(), _d.level, 'level'),
        if (_d.finishing != null)
          (
            'listing.f_finishing'.tr(),
            'listing.fin_${_d.finishing}'.tr(),
            'finishing',
          ),
        if (_d.delivery != null)
          (
            'listing.f_delivery'.tr(),
            _d.delivery == 'ready' ? 'listing.d_ready'.tr() : _d.delivery!,
            'delivery',
          ),
        if (_d.view != null)
          ('listing.f_view'.tr(), 'listing.v_${_d.view}'.tr(), 'view'),
      ]),
      _block('listing.s3'.tr(), 3, [
        (
          'listing.asking'.tr(),
          price == null ? '—' : 'EGP ${grouped(price)}',
          'price',
        ),
        (
          'listing.plan'.tr(),
          _d.payment == 'cash'
              ? 'listing.cash'.tr()
              : 'listing.plan_text'.tr(args: [_d.down, _d.years]),
          'down',
        ),
      ]),
    ]);
  }

  Widget _done() {
    final plan = _me?.plan;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kListPad + 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: JV2.success,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4713794F),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (_editing
                              ? (_wentToReview
                                    ? 'listing.edit_review_title'
                                    : 'listing.edit_saved_title')
                              : 'listing.sent_title')
                          .tr(),
                      textAlign: TextAlign.center,
                      style: JV2.display(context, 28),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _editing
                          ? (_wentToReview
                                    ? 'listing.edit_review_sub'
                                    : 'listing.edit_saved_sub')
                                .tr()
                          : 'listing.sent_sub'.tr(
                              args: [
                                _d.type == null
                                    ? ''
                                    : 'listing.t_${_d.type}'.tr(),
                                _d.compound?.name(_ar) ?? '',
                              ],
                            ),
                      textAlign: TextAlign.center,
                      style: JV2.sub,
                    ),
                    if (plan != null && !_editing) ...[
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: JV2.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JV2.line),
                        ),
                        child: Row(
                          children: [
                            for (final (i, e) in [
                              (
                                'listing.plan'.tr(),
                                'listing.used_of'.tr(
                                  args: ['${plan.used}', '${plan.total}'],
                                ),
                              ),
                              ('listing.status'.tr(), 'listing.in_review'.tr()),
                            ].indexed)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: i == 0
                                        ? null
                                        : const BorderDirectional(
                                            start: BorderSide(color: JV2.line),
                                          ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.$1,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: JV2.inkSub,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        e.$2,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: JV2.ink,
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kListPad, 12, kListPad, 18),
              child: JV2PrimaryButton(
                onPressed: _goMine,
                child: Text('listing.go_mine'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;
  const _AddChip({
    required this.label,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? JV2.success : JV2.line),
      ),
      child: Text(
        done ? '✓ $label' : '+ $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: done ? JV2.success : JV2.ink,
        ),
      ),
    ),
  );
}

/// The ask range of similar units, the middle half shaded, with the seller's price as a dot.
class _BandBar extends StatelessWidget {
  final PriceBand band;
  final double? mine;
  const _BandBar({required this.band, required this.mine});

  @override
  Widget build(BuildContext context) {
    final lo = band.min!, hi = band.max!;
    final span = (hi - lo) <= 0 ? 1.0 : hi - lo;
    double at(double v) => ((v - lo) / span).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 14,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 4,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: JV2.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (band.count >= 3)
                Positioned(
                  left: w * at(band.p25!),
                  width: (w * (at(band.p75!) - at(band.p25!))).clamp(2.0, w),
                  top: 4,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0x4D1A4A80),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              if (mine != null)
                Positioned(
                  left: w * at(mine!) - 7,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: JV2.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: JV2.shadowMd,
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

class _CompoundPicker extends StatefulWidget {
  final ListingApi api;
  final bool ar;
  const _CompoundPicker({required this.api, required this.ar});

  @override
  State<_CompoundPicker> createState() => _CompoundPickerState();
}

class _CompoundPickerState extends State<_CompoundPicker> {
  List<CompoundRef>? _all;
  bool _failed = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    widget.api
        .compounds()
        .then((l) {
          if (mounted) setState(() => _all = l);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = (_all ?? [])
        .where(
          (c) =>
              q.isEmpty ||
              '${c.nameAr} ${c.nameEn} ${c.developerEn ?? ''} ${c.developerAr ?? ''}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kListPad, 18, kListPad, 10),
                child: TextField(
                  key: const Key('compound-search'),
                  autofocus: false,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'listing.search_compound'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: JV2.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: JV2.line),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _all == null
                    ? Center(
                        child: _failed
                            ? Text('listing.load_failed'.tr())
                            : const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: JV2.goldHi,
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kListPad,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => ListTile(
                          key: Key('compound-${list[i].id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            list[i].name(widget.ar),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: list[i].sub(widget.ar).isEmpty
                              ? null
                              : Text(
                                  list[i].sub(widget.ar),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => Navigator.pop(context, list[i]),
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
