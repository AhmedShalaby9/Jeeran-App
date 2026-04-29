import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A custom snackbar utility for the app.
///
/// Usage:
/// ```dart
/// AppSnackbar.favoriteAdded(context);
/// AppSnackbar.favoriteRemoved(context);
/// AppSnackbar.show(context, message: '...', icon: Icons.check, iconColor: AppColors.success);
/// ```
class AppSnackbar {
  AppSnackbar._();

  // ── Favorites ────────────────────────────────────────────────────

  static void favoriteAdded(
    BuildContext context, {
    double bottomMargin = 16,
  }) {
    _show(
      context,
      message: 'Saved to favorites',
      icon: Icons.favorite_rounded,
      iconColor: AppColors.dangerPink,
      bottomMargin: bottomMargin,
    );
  }

  static void favoriteRemoved(
    BuildContext context, {
    double bottomMargin = 16,
  }) {
    _show(
      context,
      message: 'Removed from favorites',
      icon: Icons.favorite_border_rounded,
      iconColor: AppColors.inkMute,
      bottomMargin: bottomMargin,
    );
  }

  // ── Generic ──────────────────────────────────────────────────────

  static void show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    double bottomMargin = 16,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      iconColor: iconColor,
      bottomMargin: bottomMargin,
    );
  }

  // ── Internal ─────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required double bottomMargin,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2200),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: bottomMargin,
          ),
          content: _SnackbarContent(
            message: message,
            icon: icon,
            iconColor: iconColor,
          ),
        ),
      );
  }
}

class _SnackbarContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const _SnackbarContent({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
