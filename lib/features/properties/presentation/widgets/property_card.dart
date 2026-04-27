import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/property.dart';

enum _CardType { featured, horizontal, vertical }

class PropertyCard extends StatelessWidget {
  final Property property;
  final _CardType _type;
  final VoidCallback? onTap;

  const PropertyCard._({
    required this.property,
    required _CardType type,
    this.onTap,
  }) : _type = type;

  factory PropertyCard.featured({
    required Property property,
    VoidCallback? onTap,
  }) => PropertyCard._(
    property: property,
    type: _CardType.featured,
    onTap: onTap,
  );

  factory PropertyCard.horizontalCard({
    required Property property,
    VoidCallback? onTap,
  }) => PropertyCard._(
    property: property,
    type: _CardType.horizontal,
    onTap: onTap,
  );

  factory PropertyCard.verticalCard({
    required Property property,
    VoidCallback? onTap,
  }) => PropertyCard._(
    property: property,
    type: _CardType.vertical,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    return switch (_type) {
      _CardType.featured => _FeaturedCard(property: property, onTap: onTap),
      _CardType.horizontal => _HorizontalCard(property: property, onTap: onTap),
      _CardType.vertical => _VerticalCard(property: property, onTap: onTap),
    };
  }
}

// ───────────────────────── Featured Card ─────────────────────────

class _FeaturedCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const _FeaturedCard({required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (property.isFeatured) ...[
                            const _FeaturedBadge(),
                            const SizedBox(height: 8),
                          ],
                          _StatusBadge(text: property.propertyStatus ?? ''),
                        ],
                      ),
                    ),
                    Positioned(top: 12, right: 12, child: _FavoriteButton()),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.price ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property.state ?? ''}${property.state != null && property.country != null ? ', ' : ''}${property.country ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SpecsRow(property: property, light: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = property.coverImage;
    if (url != null && url.isNotEmpty) {
      return AppImage.network(url, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.apartment, color: AppColors.primary, size: 48),
      ),
    );
  }
}

// ───────────────────────── Horizontal Card ─────────────────────────

class _HorizontalCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const _HorizontalCard({required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
                child: SizedBox(width: 130, child: _buildThumbnail()),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (property.propertyStatus != null &&
                              property.propertyStatus!.isNotEmpty)
                            _TagChip(
                              label: _statusLabel(property.propertyStatus),
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.08,
                              ),
                              textColor: AppColors.primary,
                            ),
                          if (property.isFeatured)
                            _TagChip(
                              label: 'properties.featured_badge'.tr(),
                              backgroundColor: Color(0xFFFFF8E1),
                              textColor: Color(0xFFFFB800),
                              icon: Icons.star,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property.price ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.state ?? ''}${property.state != null && property.country != null ? ', ' : ''}${property.country ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SpecsRow(property: property, light: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = property.coverImage;
    if (url != null && url.isNotEmpty) {
      return AppImage.network(url, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.apartment, color: AppColors.primary, size: 32),
    );
  }
}

// ───────────────────────── Vertical Card ─────────────────────────

class _VerticalCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const _VerticalCard({required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Stack(
                children: [
                  _buildImage(),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StatusBadge(
                      text: _statusLabel(property.propertyStatus),
                    ),
                  ),
                  Positioned(top: 10, right: 10, child: _FavoriteButton()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.price ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (property.propertyStatus != null &&
                          property.propertyStatus!.isNotEmpty)
                        _TagChip(
                          label: _statusLabel(property.propertyStatus),
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          textColor: AppColors.primary,
                        ),
                      if (property.isFeatured)
                        _TagChip(
                          label: 'properties.featured_badge'.tr(),
                          backgroundColor: Color(0xFFFFF8E1),
                          textColor: Color(0xFFFFB800),
                          icon: Icons.star,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property.state ?? ''}${property.state != null && property.country != null ? ', ' : ''}${property.country ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SpecsRow(property: property, light: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = property.coverImage;
    if (url != null && url.isNotEmpty) {
      return AppImage.network(
        url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 150,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.apartment, color: AppColors.primary, size: 40),
      ),
    );
  }
}

// ───────────────────────── Shared Widgets ─────────────────────────

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'properties.featured_badge'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String? key) => switch (key) {
  'for_sale' => 'status.for_sale'.tr(),
  'for_rent' => 'status.for_rent'.tr(),
  'for_rent_furnished' => 'status.for_rent_furnished'.tr(),
  _ => key ?? '',
};

class _TagChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  const _StatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.favorite_border,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }
}

class _SpecsRow extends StatelessWidget {
  final Property property;
  final bool light;

  const _SpecsRow({required this.property, required this.light});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : AppColors.grey;

    return Row(
      children: [
        if (property.bedrooms != null) ...[
          _SpecItem(
            icon: Icons.bed_outlined,
            label: '${property.bedrooms}',
            color: color,
          ),
          const SizedBox(width: 14),
        ],
        if (property.bathrooms != null) ...[
          _SpecItem(
            icon: Icons.bathtub_outlined,
            label: '${property.bathrooms}',
            color: color,
          ),
          const SizedBox(width: 14),
        ],
        if (property.size != null)
          _SpecItem(
            icon: Icons.square_foot_outlined,
            label: '${property.size}${'properties.unit_sqm'.tr()}',
            color: color,
          ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
