import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../developers/presentation/pages/developer_page.dart';
import '../../../news/v2/news_list_page.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../properties/presentation/pages/property_details_page.dart';
import '../../data/models/saved_models.dart';
import '../bloc/saved_cubit.dart';
import '../widgets/saved_widgets.dart';

enum _SavedTab { listings, compounds, developers }

/// Saved — listings, followed compounds and followed developers.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  /// Bump to make the Saved tab refresh (the shell does this when you switch to it).
  static final ValueNotifier<int> reload = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SavedCubit>()..load(),
      child: const _SavedView(),
    );
  }
}

class _SavedView extends StatefulWidget {
  const _SavedView();

  @override
  State<_SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<_SavedView> {
  _SavedTab _tab = _SavedTab.listings;

  @override
  void initState() {
    super.initState();
    SavedPage.reload.addListener(_onReload);
  }

  @override
  void dispose() {
    SavedPage.reload.removeListener(_onReload);
    super.dispose();
  }

  void _onReload() {
    if (mounted) context.read<SavedCubit>().load();
  }

  void _undoable(
    Future<Future<void> Function()?> pending,
    String messageKey,
  ) async {
    final undo = await pending;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (undo == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('saved.action_failed'.tr())),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(messageKey.tr()),
        action: SnackBarAction(
          label: 'saved.undo'.tr(),
          onPressed: () => undo(),
        ),
      ),
    );
  }

  void _openNews() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NewsListPage()),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: BlocBuilder<SavedCubit, SavedState>(
          builder: (context, state) {
            return Column(
              children: [
                _Header(
                  tab: _tab,
                  counts: state.counts,
                  onTab: (t) => setState(() => _tab = t),
                ),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SavedState state) {
    final cubit = context.read<SavedCubit>();

    if (state.status == SavedLoad.loading) return const _Skeleton();
    if (state.status == SavedLoad.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 46),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: JV2.inkMute),
              const SizedBox(height: 14),
              Text(
                'explore.load_failed'.tr(),
                textAlign: TextAlign.center,
                style: JV2.display(context, 22),
              ),
              const SizedBox(height: 18),
              JV2PrimaryButton(
                width: 160,
                height: 46,
                onPressed: cubit.load,
                child: Text('explore.try_again'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final (empty, children) = switch (_tab) {
      _SavedTab.listings => (
        state.listings.isEmpty,
        [
          for (final l in state.listings)
            SavedListingRow(
              key: ValueKey('l${l.property.id}'),
              item: l,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailsPage(property: l.property),
                ),
              ),
              onRemove: () =>
                  _undoable(cubit.removeListing(l), 'saved.removed'),
            ),
        ],
      ),
      _SavedTab.compounds => (
        state.compounds.isEmpty,
        [
          for (final c in state.compounds)
            SavedCompoundCard(
              key: ValueKey('c${c.project.id}'),
              item: c,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompoundPage(
                    compoundId: c.project.id,
                    name: c.project.name,
                  ),
                ),
              ),
              onUnfollow: () =>
                  _undoable(cubit.unfollowCompound(c), 'saved.unfollowed'),
              onOpenUpdate: _openNews,
            ),
        ],
      ),
      _SavedTab.developers => (
        state.developers.isEmpty,
        [
          for (final d in state.developers)
            SavedDeveloperRow(
              key: ValueKey('d${d.id}'),
              item: d,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DeveloperPage(developerId: d.id, name: d.name),
                ),
              ),
              onUnfollow: () =>
                  _undoable(cubit.unfollowDeveloper(d), 'saved.unfollowed'),
              onOpenUpdate: _openNews,
            ),
        ],
      ),
    };

    if (empty) {
      final e = switch (_tab) {
        _SavedTab.listings => (
          'saved.empty_listings_title',
          'saved.empty_listings_sub',
          Icons.bookmark_border_rounded,
        ),
        _SavedTab.compounds => (
          'saved.empty_compounds_title',
          'saved.empty_compounds_sub',
          Icons.home_outlined,
        ),
        _SavedTab.developers => (
          'saved.empty_developers_title',
          'saved.empty_developers_sub',
          Icons.business_outlined,
        ),
      };
      // still pull-to-refreshable
      return RefreshIndicator(
        color: JV2.navy,
        onRefresh: cubit.load,
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: SavedEmptyState(titleKey: e.$1, subKey: e.$2, icon: e.$3),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: JV2.navy,
      onRefresh: cubit.load,
      child: ListView(
        key: ValueKey(_tab),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        children: [
          _Summary(tab: _tab, counts: state.counts),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _SavedTab tab;
  final SavedCounts counts;
  final ValueChanged<_SavedTab> onTab;

  const _Header({required this.tab, required this.counts, required this.onTab});

  int _count(_SavedTab t) => switch (t) {
    _SavedTab.listings => counts.listings,
    _SavedTab.compounds => counts.compounds,
    _SavedTab.developers => counts.developers,
  };

  String _label(_SavedTab t) => switch (t) {
    _SavedTab.listings => 'saved.tab_listings'.tr(),
    _SavedTab.compounds => 'saved.tab_compounds'.tr(),
    _SavedTab.developers => 'saved.tab_developers'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE6FAFBFD),
            border: Border(bottom: BorderSide(color: JV2.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 12,
                  20,
                  14,
                ),
                child: Text(
                  'saved.title'.tr(),
                  style: JV2.display(context, 26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (final t in _SavedTab.values)
                      GestureDetector(
                        onTap: () => onTab(t),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(end: 20),
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: t == tab
                                    ? JV2.goldHi
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _label(t),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: t == tab
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: t == tab ? JV2.ink : JV2.inkSub,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: t == tab
                                      ? JV2.goldFilm
                                      : JV2.fillFaint,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${_count(t)}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: t == tab ? JV2.gold : JV2.inkSub,
                                  ),
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
          ),
        ),
      ),
    );
  }
}

/// "**4 listings** · 1 price drop, 1 sold"
class _Summary extends StatelessWidget {
  final _SavedTab tab;
  final SavedCounts counts;

  const _Summary({required this.tab, required this.counts});

  @override
  Widget build(BuildContext context) {
    final (lead, rest) = switch (tab) {
      _SavedTab.listings => (
        'saved.n_listings'.plural(counts.listings),
        [
          if (counts.priceDrops > 0)
            'saved.n_price_drops'.plural(counts.priceDrops),
          if (counts.sold > 0) 'saved.n_sold'.plural(counts.sold),
          if (counts.unavailable > 0)
            'saved.n_unavailable'.plural(counts.unavailable),
        ],
      ),
      _SavedTab.compounds => (
        'saved.n_compounds'.plural(counts.compounds),
        [
          if (counts.freshCompounds > 0)
            'saved.n_new_releases'.plural(counts.freshCompounds),
        ],
      ),
      _SavedTab.developers => (
        'saved.n_developers'.plural(counts.developers),
        [
          if (counts.developerProjects > 0)
            'saved.compounds_between'.tr(args: ['${counts.developerProjects}']),
        ],
      ),
    };
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
        children: [
          TextSpan(
            text: lead,
            style: const TextStyle(fontWeight: FontWeight.w800, color: JV2.ink),
          ),
          if (rest.isNotEmpty) TextSpan(text: ' · ${rest.join(', ')}'),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9EEF4),
      highlightColor: const Color(0xFFF6F8FB),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        children: [
          row(),
          const SizedBox(height: 10),
          row(),
          const SizedBox(height: 10),
          row(),
        ],
      ),
    );
  }
}
