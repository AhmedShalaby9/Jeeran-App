import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../domain/entities/property.dart';
import '../widgets/property_bottom_bar.dart';
import '../widgets/property_gallery.dart';
import '../widgets/property_price_card.dart';

import 'property_image_viewer_page.dart';
import '../widgets/property_agent_tab.dart';
import '../widgets/property_details_tab.dart';
import '../widgets/property_overview_tab.dart';

class PropertyDetailsPage extends StatefulWidget {
  final Property property;
  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  int _photoIdx = 0;
  late bool _saved;
  int _tab = 0;
  late final PageController _pageController;

  Property get _p => widget.property;

  @override
  void initState() {
    super.initState();
    // Prefer the in-session cache; fall back to the server-returned value
    _saved = sl<FavoritesBloc>().isFavorited(widget.property.id) ||
        widget.property.isFavorited;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatPrice(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final n = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (n == null) return raw;
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}K';
    }
    return raw;
  }

  void _toggleSave() {
    setState(() => _saved = !_saved);
    if (_saved) {
      sl<FavoritesBloc>().add(AddFavoriteEvent(_p.id));
      // bottom bar height ≈ 72px + safe area; add a small buffer
      final bottomOffset =
          72 + MediaQuery.of(context).padding.bottom + 12.0;
      AppSnackbar.favoriteAdded(context, bottomMargin: bottomOffset);
    } else {
      sl<FavoritesBloc>().add(RemoveFavoriteEvent(_p.id));
      final bottomOffset =
          72 + MediaQuery.of(context).padding.bottom + 12.0;
      AppSnackbar.favoriteRemoved(context, bottomMargin: bottomOffset);
    }
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroSection()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildTabs()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildTabContent()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PropertyBottomBar(
              property: _p,
              saved: _saved,
              onToggleSave: _toggleSave,
              onShare: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final images = _p.images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 238,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: 260,
            child: SizedBox(
              height: 260,
              child: PropertyGallery(
                images: images,
                photoIdx: _photoIdx,
                saved: _saved,
                pageController: _pageController,
                onPageChanged: (i) => setState(() => _photoIdx = i),
                onImageTap: (i) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyImageViewerPage(
                      images: images,
                      initialIndex: i,
                    ),
                  ),
                ),
                onToggleSave: _toggleSave,
                onShare: () {},
                onBack: () => Navigator.maybePop(context),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PropertyPriceCard(
            property: _p,
            formatPrice: _formatPrice,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    const labels = ['Overview', 'Details', 'Agent'];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0B2A4A).withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? const Color(0xFF0E1726) : const Color(0xFF5B6474),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey(_tab),
        child: switch (_tab) {
          0 => PropertyOverviewTab(property: _p),
          1 => PropertyDetailsTab(property: _p),
          2 => PropertyAgentTab(property: _p, initials: _initials),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
