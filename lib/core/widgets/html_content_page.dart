import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../utils/app_colors.dart';

class HtmlContentPage extends StatelessWidget {
  final String title;
  final String? html;

  const HtmlContentPage({super.key, required this.title, this.html});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: html != null && html!.isNotEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Html(
                data: html!,
                style: {
                  'body': Style(
                    fontSize: FontSize(14),
                    color: AppColors.inkSub,
                    lineHeight: LineHeight(1.65),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  'h1, h2, h3': Style(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  'a': Style(color: AppColors.secondary),
                },
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 56,
                    color: AppColors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Content coming soon',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
