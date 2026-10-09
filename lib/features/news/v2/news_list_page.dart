import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/jv2.dart';
import 'news_api.dart';
import 'news_article_page.dart';
import 'news_widgets.dart';

const double _pad = 20;

/// "See all" for market news: newest as the lead story, the rest as "Earlier", loaded a page at a time.
class NewsListPage extends StatefulWidget {
  final NewsApi? api; // tests inject a fake
  const NewsListPage({super.key, this.api});

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  late final NewsApi _api = widget.api ?? NewsApi(sl<ApiClient>());
  final _scroll = ScrollController();
  final List<NewsItem> _items = [];
  int _page = 0;
  bool _loading = true, _more = true, _failed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_page > 0 && (!_more || _loading)) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final rows = await _api.list(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(rows);
        _more = rows.length >= NewsApi.pageSize;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _open(NewsItem n) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NewsArticlePage(item: n, api: _api),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              _pad,
              MediaQuery.paddingOf(context).top + 8,
              _pad,
              12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xEBFAFBFD),
              border: Border(bottom: BorderSide(color: JV2.line)),
            ),
            child: Row(
              children: [
                const JV2BackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'news.v2_title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: JV2.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: JV2.goldHi),
      );
    }
    if (_items.isEmpty && _failed) {
      return Center(
        child: TextButton(onPressed: _load, child: Text('news.retry'.tr())),
      );
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(_pad, 16, _pad, 30),
      children: [
        Text('news.v2_headline'.tr(), style: JV2.display(context, 26)),
        const SizedBox(height: 7),
        Text('news.v2_sub'.tr(), style: JV2.sub.copyWith(fontSize: 13)),
        const SizedBox(height: 18),
        if (_items.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Text(
              'news.empty_title'.tr(),
              style: JV2.display(context, 21),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'news.empty_sub'.tr(),
            textAlign: TextAlign.center,
            style: JV2.sub.copyWith(fontSize: 13),
          ),
        ] else ...[
          NewsLead(item: _items.first, onTap: () => _open(_items.first)),
          if (_items.length > 1) ...[
            const SizedBox(height: 18),
            Text(
              'news.earlier'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: JV2.inkMute,
              ),
            ),
            const SizedBox(height: 10),
            for (final n in _items.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NewsRow(item: n, onTap: () => _open(n)),
              ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: JV2.goldHi,
                ),
              ),
            )
          else if (!_more)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'news.end'.tr(),
                  style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
