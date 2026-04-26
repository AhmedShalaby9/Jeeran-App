import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum _AppLoadingType { circular, cupertino }

class AppLoading extends StatelessWidget {
  final _AppLoadingType _type;
  final double size;
  final Color? color;

  const AppLoading._({
    required _AppLoadingType type,
    this.size = 24,
    this.color,
  }) : _type = type;

  factory AppLoading.circular({double size = 24, Color? color}) =>
      AppLoading._(type: _AppLoadingType.circular, size: size, color: color);

  factory AppLoading.cupertino({double size = 20, Color? color}) =>
      AppLoading._(type: _AppLoadingType.cupertino, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    return switch (_type) {
      _AppLoadingType.circular => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? AppColors.primary,
        ),
      ),
      _AppLoadingType.cupertino => CupertinoActivityIndicator(
        radius: size / 2,
        color: color,
      ),
    };
  }
}
