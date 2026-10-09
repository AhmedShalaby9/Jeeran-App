import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import '../presentation/pages/news_details_page.dart' show NewsVideoPage;
import 'news_api.dart';
import 'news_widgets.dart';

const double _pad = 20;

/// One story. Pass the [item] you already have (list/rail) or just an [id] (notification, link) and
/// it is fetched. The article body always comes from `/news/:id`; the list rows only carry excerpts.
class NewsArticlePage extends StatefulWidget {
  final NewsItem? item;
  final int? id;
  final NewsApi? api;
  const NewsArticlePage({super.key, this.item, this.id, this.api})
    : assert(item != null || id != null);

  @override
  State<NewsArticlePage> createState() => _NewsArticlePageState();
}

class _NewsArticlePageState extends State<NewsArticlePage> {
  late final NewsApi _api = widget.api ?? NewsApi(sl<ApiClient>());
  NewsItem? _a;
  List<NewsItem> _more = const [];
  bool _failed = false;
  int _slide = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final a = await _api.byId(widget.item?.id ?? widget.id!);
      if (mounted) setState(() => _a = a);
      final others = await _api.list();
      if (mounted) {
        setState(
          () => _more = others.where((n) => n.id != a.id).take(3).toList(),
        );
      }
    } catch (_) {
      if (mounted && _a == null) setState(() => _failed = true);
    }
  }

  void _openMedia(String url) {
    if (NewsItem.isVideo(url)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsVideoPage(url: url)),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: a == null
          ? Stack(
              children: [
                Center(
                  child: _failed
                      ? TextButton(
                          onPressed: _load,
                          child: Text('news.retry'.tr()),
                        )
                      : const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JV2.goldHi,
                        ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: _pad,
                  child: const JV2BackButton(),
                ),
              ],
            )
          : _article(context, a),
    );
  }

  Widget _article(BuildContext context, NewsItem a) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            if (a.media.isNotEmpty) _gallery(a) else SizedBox(height: top + 60),
            Transform.translate(
              offset: Offset(0, a.media.isNotEmpty ? -26 : 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(_pad, 22, _pad, 34),
                decoration: const BoxDecoration(
                  color: JV2.bgDeep,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: JV2.display(context, 29)),
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: JV2.line)),
                      ),
                      child: Text(
                        [
                          newsDate(context, a.publishedAt),
                          if (a.media.isNotEmpty)
                            a.media.length == 1
                                ? 'news.one_photo'.tr()
                                : 'news.n_media'.tr(
                                    args: ['${a.media.length}'],
                                  ),
                        ].where((s) => s.isNotEmpty).join('  ·  '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: JV2.inkMute,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final p in a.paragraphs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          p,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.62,
                            color: JV2.ink,
                          ),
                        ),
                      ),
                    if (_more.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'news.more'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: JV2.inkMute,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final n in _more)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NewsRow(
                            item: n,
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NewsArticlePage(item: n, api: _api),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(top: top + 8, left: _pad, child: const JV2BackButton()),
      ],
    );
  }

  /// Images and videos in one pager; a video slide is a poster with a play button.
  Widget _gallery(NewsItem a) {
    return SizedBox(
      height: 272,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: a.media.length,
            onPageChanged: (i) => setState(() => _slide = i),
            itemBuilder: (_, i) {
              final m = a.media[i];
              final video = NewsItem.isVideo(m);
              return GestureDetector(
                onTap: () => _openMedia(m),
                child: Photo(
                  url: video ? null : m,
                  radius: 0,
                  child: video ? const PlayDot(size: 58) : null,
                ),
              );
            },
          ),
          if (a.media.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < a.media.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _slide ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _slide
                            ? Colors.white
                            : const Color(0x80FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
