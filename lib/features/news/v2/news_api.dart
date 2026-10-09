import '../../../core/network/api_client.dart';

/// One story as the v2 screens read it: title, text, media (images and videos), date.
class NewsItem {
  final int id;
  final String title;
  final String body; // full text on the article, a short excerpt in lists
  final List<String> media;
  final DateTime? publishedAt;

  const NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.media,
    required this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) {
    final raw = j['media'];
    final text = (j['content'] ?? j['excerpt']) as String? ?? '';
    return NewsItem(
      id: (j['id'] as num).toInt(),
      title: (j['title'] as String? ?? '').trim(),
      body: text.trim(),
      media: raw is List
          ? raw.whereType<String>().where((u) => u.startsWith('http')).toList()
          : const [],
      publishedAt: DateTime.tryParse(j['published_at'] as String? ?? ''),
    );
  }

  static bool isVideo(String url) {
    final u = url.toLowerCase().split('?').first;
    return const ['.mp4', '.mov', '.avi', '.mkv', '.webm'].any(u.endsWith);
  }

  bool get hasVideo => media.any(isVideo);

  /// First image if there is one; otherwise nothing (a video url is not a picture).
  String? get cover {
    for (final m in media) {
      if (!isVideo(m)) return m;
    }
    return null;
  }

  /// The article text as paragraphs: blank lines separate them.
  List<String> get paragraphs => body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  /// Single-line preview for rows.
  String get excerpt {
    final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length > 160 ? '${t.substring(0, 157)}…' : t;
  }
}

class NewsApi {
  static const pageSize = 12;
  final ApiClient client;
  NewsApi(this.client);

  Future<List<NewsItem>> list({int page = 1}) async {
    final res = await client.get(
      '/news',
      queryParams: {'summary': 'true', 'limit': pageSize, 'page': page},
    );
    final rows = (res.data['data'] as List?) ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(NewsItem.fromJson)
        .toList();
  }

  Future<NewsItem> byId(int id) async {
    final res = await client.get('/news/$id');
    return NewsItem.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
