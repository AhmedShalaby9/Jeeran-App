import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../news/domain/entities/news.dart';
import '../../../../news/presentation/pages/news_details_page.dart';
import '../../../../properties/domain/entities/property.dart';
import '../../../../properties/presentation/pages/property_details_page.dart';
import '../../../../properties/presentation/widgets/property_card.dart';
import '../../../../projects/domain/entities/project.dart';
import '../../../../projects/presentation/pages/project_details_page.dart';
import '../../../domain/entities/chat_references.dart';

class ChatReferenceCards extends StatelessWidget {
  final ChatReferences references;
  const ChatReferenceCards({super.key, required this.references});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (references.properties.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionLabel(label: 'ai_chat.references_properties'.tr()),
          const SizedBox(height: 6),
          _PropertyScroll(properties: references.properties),
        ],
        if (references.projects.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SectionLabel(label: 'ai_chat.references_projects'.tr()),
          const SizedBox(height: 6),
          _ProjectChips(projects: references.projects),
        ],
        if (references.news.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SectionLabel(label: 'ai_chat.references_news'.tr()),
          const SizedBox(height: 6),
          _NewsRows(newsRefs: references.news),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.inkSub,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Properties ────────────────────────────────────────────────────────────────

class _PropertyScroll extends StatelessWidget {
  final List<Property> properties;
  const _PropertyScroll({required this.properties});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final property = properties[i];
          return PropertyCard.similar(
            property: property,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsPage(property: property),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Projects ──────────────────────────────────────────────────────────────────

class _ProjectChips extends StatelessWidget {
  final List<Project> projects;
  const _ProjectChips({required this.projects});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: projects.map((p) => _ProjectChip(project: p)).toList(),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final Project project;
  const _ProjectChip({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailsPage(project: project),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── News ──────────────────────────────────────────────────────────────────────

class _NewsRows extends StatelessWidget {
  final List<ChatNewsRef> newsRefs;
  const _NewsRows({required this.newsRefs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: newsRefs
          .map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _NewsRow(newsRef: ref),
              ))
          .toList(),
    );
  }
}

class _NewsRow extends StatelessWidget {
  final ChatNewsRef newsRef;
  const _NewsRow({required this.newsRef});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return GestureDetector(
      onTap: () {
        final news = News(
          id: newsRef.id,
          title: newsRef.localTitle(lang),
          content: newsRef.contentAr,
          media: const [],
          isActive: true,
          publishedAt: '',
          publishedBy: '',
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailsPage(news: news)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                newsRef.localTitle(lang),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackground,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
