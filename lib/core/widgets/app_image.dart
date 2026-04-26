import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_loading.dart';

enum _AppImageType { asset, svg, network }

class AppImage extends StatelessWidget {
  final _AppImageType _type;
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BorderRadius? borderRadius;

  const AppImage._({
    required _AppImageType type,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.color,
    this.borderRadius,
  }) : _type = type;

  factory AppImage.asset(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
    BorderRadius? borderRadius,
  }) => AppImage._(
    type: _AppImageType.asset,
    source: path,
    width: width,
    height: height,
    fit: fit,
    color: color,
    borderRadius: borderRadius,
  );

  factory AppImage.svg(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    BorderRadius? borderRadius,
  }) => AppImage._(
    type: _AppImageType.svg,
    source: path,
    width: width,
    height: height,
    fit: fit,
    color: color,
    borderRadius: borderRadius,
  );

  factory AppImage.network(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) => AppImage._(
    type: _AppImageType.network,
    source: url,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
  );

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage() {
    return switch (_type) {
      _AppImageType.asset => Image.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        color: color,
      ),
      _AppImageType.svg => SvgPicture.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      ),
      _AppImageType.network => CachedNetworkImage(
        imageUrl: source,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => Center(child: AppLoading.cupertino(size: 18)),
        errorWidget: (_, _, _) => const Icon(
          Icons.image_not_supported_outlined,
          size: 24,
          color: Colors.grey,
        ),
      ),
    };
  }
}
