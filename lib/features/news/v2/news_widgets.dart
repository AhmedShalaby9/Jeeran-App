import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import 'news_api.dart';

String newsAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'notif.ago_now'.tr();
  if (d.inMinutes < 60) return 'notif.ago_m'.tr(args: ['${d.inMinutes}']);
  if (d.inHours < 24) return 'notif.ago_h'.tr(args: ['${d.inHours}']);
  if (d.inDays < 7) return 'notif.ago_d'.tr(args: ['${d.inDays}']);
  return 'notif.ago_w'.tr(args: ['${d.inDays ~/ 7}']);
}

String newsDate(BuildContext context, DateTime? t) => t == null
    ? ''
    : DateFormat.yMMMd(context.locale.toString()).format(t.toLocal());

class PlayDot extends StatelessWidget {
  final double size;
  const PlayDot({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xC7FFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.play_arrow_rounded, size: size * .6, color: JV2.navy),
    ),
  );
}

/// The newest story, large.
class NewsLead extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;
  const NewsLead({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
          boxShadow: JV2.shadowMd,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Photo(
              url: item.cover,
              height: 182,
              radius: 0,
              child: item.hasVideo ? const PlayDot(size: 48) : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: JV2.display(context, 24)),
                  if (item.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      item.excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: JV2.inkSub,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '${newsDate(context, item.publishedAt)} · ${newsAgo(item.publishedAt)}',
                    style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsRow extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;
  const NewsRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JV2.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Photo(
              url: item.cover,
              width: 94,
              height: 84,
              radius: 12,
              child: item.hasVideo ? const PlayDot(size: 28) : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.32,
                      color: JV2.ink,
                    ),
                  ),
                  if (item.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.42,
                        color: JV2.inkSub,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    newsAgo(item.publishedAt),
                    style: const TextStyle(fontSize: 11, color: JV2.inkMute),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
