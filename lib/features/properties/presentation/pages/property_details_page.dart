import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';

const _kInk = Color(0xFF0E1726);
const _kInkSub = Color(0xFF5B6474);
const _kInkMute = Color(0xFF8A93A3);
const _kBg = Color(0xFFF5F6F8);
const _kHairline = Color(0x14081E3C);
const _kDanger = Color(0xFFFF4A6B);
const _kWhatsApp = Color(0xFF25D366);
const _kPrimarySoft = Color(0xFFEAF0F7);

class PropertyDetailsPage extends StatefulWidget {
  final Property property;
  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  int _photoIdx = 0;
  bool _saved = false;
  int _tab = 0;
  late final PageController _pageController;

  Property get _p => widget.property;

  @override
  void initState() {
    super.initState();
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
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return raw;
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
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
              SliverToBoxAdapter(child: _buildSimilarSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  // ── Hero (gallery + floating price card) ─────────────────────────────────

  Widget _buildHeroSection() {
    final images = _p.images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gallery shrunk by 22px so the price card visually overlaps it
        SizedBox(
          height: 238,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: 260,
            minWidth: 0,
            maxWidth: double.infinity,
            child: SizedBox(height: 260, child: _buildGallery(images)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPriceCard(),
        ),
      ],
    );
  }

  Widget _buildGallery(List<String> images) {
    return Stack(
      children: [
        if (images.isNotEmpty)
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _photoIdx = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => const _Placeholder(),
              errorWidget: (_, __, ___) => const _Placeholder(),
            ),
          )
        else
          const _Placeholder(),
        // Frosted top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 54, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x00000000)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassBtn(
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    _GlassBtn(
                      onTap: () {},
                      child: const Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassBtn(
                      onTap: () => setState(() => _saved = !_saved),
                      child: Icon(
                        _saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: _saved ? _kDanger : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Dot indicator
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _photoIdx;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active ? Colors.white : const Color(0x73FFFFFF),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  // ── Floating price card ───────────────────────────────────────────────────

  Widget _buildPriceCard() {
    final hasStats =
        _p.bedrooms != null ||
        _p.bathrooms != null ||
        (_p.size != null && _p.size!.isNotEmpty);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kHairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E0B2A4A),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                    if (_p.propertyStatus?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _p.propertyStatus!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Text(
                      _p.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                        color: _kInk,
                      ),
                    ),
                    if (_p.project?.name != null ||
                        _p.state?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: _kInkSub,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                [_p.project?.name, _p.state]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kInkSub,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (_p.price?.isNotEmpty == true)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(_p.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: _kInk,
                        ),
                      ),
                      const Text(
                        'JOD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasStats) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: _kHairline),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_p.bedrooms != null) ...[
                  _StatPill(
                    icon: Icons.bed_rounded,
                    label: '${_p.bedrooms} Beds',
                  ),
                  const SizedBox(width: 6),
                ],
                if (_p.bathrooms != null) ...[
                  _StatPill(
                    icon: Icons.bathtub_rounded,
                    label: '${_p.bathrooms} Baths',
                  ),
                  const SizedBox(width: 6),
                ],
                if (_p.size?.isNotEmpty == true)
                  _StatPill(
                    icon: Icons.crop_square_rounded,
                    label: '${_p.size} m²',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    const labels = ['Overview', 'Details', 'Agent'];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kBg,
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
                      ? const [
                          BoxShadow(
                            color: Color(0x140B2A4A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
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
                      color: active ? _kInk : _kInkSub,
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
          0 => _buildOverviewTab(),
          1 => _buildDetailsTab(),
          2 => _buildAgentTab(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_p.content?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              _p.content!,
              style: const TextStyle(
                fontSize: 14,
                color: _kInkSub,
                height: 1.65,
              ),
            ),
          ),
        Row(
          children: [
            if (_p.legacyCode?.isNotEmpty == true) ...[
              Expanded(
                child: _InfoChip(label: 'REF', value: _p.legacyCode!),
              ),
              const SizedBox(width: 8),
            ],
            if (_p.publishedAt?.isNotEmpty == true)
              Expanded(
                child: _InfoChip(
                  label: 'YEAR',
                  value: _p.publishedAt!.length >= 4
                      ? _p.publishedAt!.substring(0, 4)
                      : _p.publishedAt!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    final rows = <(String, String?)>[
      ('Property type', _p.propertyType),
      ('Area', _p.size != null ? '${_p.size} m²' : null),
      ('Bedrooms', _p.bedrooms?.toString()),
      ('Bathrooms', _p.bathrooms?.toString()),
      ('Purpose', _p.propertyStatus),
      ('Reference', _p.legacyCode),
      ('Country', _p.country),
      ('City / State', _p.state),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No details available.',
            style: TextStyle(color: _kInkMute),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kHairline),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(rows.length, (i) {
          final last = i == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(bottom: BorderSide(color: _kHairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: const TextStyle(fontSize: 14, color: _kInkSub),
                  ),
                ),
                Text(
                  rows[i].$2!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAgentTab() {
    final name = _p.agentName;
    if (name == null || name.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No agent info available.',
            style: TextStyle(color: _kInkMute),
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPrimarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF1E5A9E)],
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Agent',
                      style: TextStyle(fontSize: 12, color: _kInkSub),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_p.agentMobile?.isNotEmpty == true)
                    _ContactCircle(
                      color: AppColors.primary,
                      icon: Icons.phone_rounded,
                      onTap: () {},
                    ),
                  if (_p.agentWhatsapp?.isNotEmpty == true) ...[
                    const SizedBox(width: 8),
                    _ContactCircle(
                      color: _kWhatsApp,
                      icon: Icons.chat_rounded,
                      onTap: () {},
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: _kInkSub,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'This listing is managed by '),
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const TextSpan(
                  text:
                      '. Contact them directly for viewings, pricing, or any questions about the property.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Similar properties ────────────────────────────────────────────────────

  Widget _buildSimilarSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Similar Properties',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: _kInk,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _SimilarCard(property: _p),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom CTA bar ────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kHairline)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      child: Row(
        children: [
          _SquareBtn(
            onTap: () => setState(() => _saved = !_saved),
            child: Icon(
              _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: _saved ? _kDanger : _kInkSub,
            ),
          ),
          const SizedBox(width: 8),
          _SquareBtn(
            onTap: () {},
            child: const Icon(Icons.share_rounded, size: 18, color: _kInkSub),
          ),
          const SizedBox(width: 8),
          if (_p.agentWhatsapp?.isNotEmpty == true) ...[
            Expanded(
              child: _CTABtn(
                label: 'WhatsApp',
                icon: Icons.chat_rounded,
                color: _kWhatsApp,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _CTABtn(
              label: 'Call',
              icon: Icons.phone_rounded,
              color: AppColors.primary,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GlassBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x59000000),
      ),
      child: Center(child: child),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _kBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kInkSub,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
      ],
    ),
  );
}

class _ContactCircle extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ContactCircle({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 16, color: Colors.white),
    ),
  );
}

class _SquareBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _SquareBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kHairline, width: 1.5),
      ),
      child: Center(child: child),
    ),
  );
}

class _CTABtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CTABtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SimilarCard extends StatelessWidget {
  final Property property;
  const _SimilarCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kHairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B2A4A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (property.coverImage != null)
                  CachedNetworkImage(
                    imageUrl: property.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const _Placeholder(),
                    errorWidget: (_, __, ___) => const _Placeholder(),
                  )
                else
                  const _Placeholder(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x52000000),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (property.price?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          property.price!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'JOD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kInkSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1, thickness: 1, color: _kHairline),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (property.bedrooms != null)
                      _MiniStat(
                        icon: Icons.bed_rounded,
                        label: '${property.bedrooms}',
                      ),
                    if (property.bathrooms != null) ...[
                      const SizedBox(width: 10),
                      _MiniStat(
                        icon: Icons.bathtub_rounded,
                        label: '${property.bathrooms}',
                      ),
                    ],
                    if (property.size?.isNotEmpty == true) ...[
                      const SizedBox(width: 10),
                      _MiniStat(
                        icon: Icons.crop_square_rounded,
                        label: '${property.size}',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: _kInkSub),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kInkSub,
        ),
      ),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFD8E0EA),
    child: const Center(
      child: Icon(Icons.image_rounded, color: Color(0xFF9AAABB), size: 40),
    ),
  );
}
