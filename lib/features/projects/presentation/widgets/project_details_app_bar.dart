import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/project.dart';

class ProjectDetailsAppBar extends StatelessWidget {
  final Project project;
  const ProjectDetailsAppBar({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          project.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            project.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: project.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.primary),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.primary,
                      child: const Icon(Icons.business, size: 80, color: Colors.white30),
                    ),
                  )
                : Container(color: AppColors.primary),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
