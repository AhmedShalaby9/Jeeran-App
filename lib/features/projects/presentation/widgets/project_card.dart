import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jeeran_flutter/core/widgets/app_loading.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/project.dart';
import '../pages/project_details_page.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailsPage(project: project)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              project.coverImage != null
                  ? CachedNetworkImage(
                      imageUrl: project.coverImage!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => AppLoading.cupertino(),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.business,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.business,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Text(
                  project.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
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
