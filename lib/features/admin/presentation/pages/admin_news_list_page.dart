import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../news/data/models/news_model.dart';
import '../../../news/domain/entities/news.dart';
import '../../../news/presentation/bloc/news_bloc.dart';
import '../../../news/presentation/bloc/news_event.dart';
import 'admin_news_form_page.dart';

/// News for admins: every article, including the ones switched off (the public feed hides those).
/// Add, edit, switch on/off, delete.
class AdminNewsListPage extends StatefulWidget {
  final Future<List<News>> Function()? load; // tests inject a fake
  final Future<void> Function(int id, bool active)? setActive; // tests inject a fake
  final Future<void> Function(int id)? remove; // tests inject a fake
  const AdminNewsListPage({super.key, this.load, this.setActive, this.remove});

  @override
  State<AdminNewsListPage> createState() => _AdminNewsListPageState();
}

class _AdminNewsListPageState extends State<AdminNewsListPage> {
  List<News>? _items;
  bool _failed = false;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<List<News>> _load() async {
    final res = await sl<ApiClient>().get(ApiEndpoints.news, queryParams: {'active': 'all', 'limit': 100});
    final d = res.data['data'];
    return [for (final m in (d is List ? d : const []).whereType<Map<String, dynamic>>()) NewsModel.fromJson(m)];
  }

  Future<void> _setActive(int id, bool active) async {
    await sl<ApiClient>().put(ApiEndpoints.newsById(id), data: {'is_active': active});
  }

  Future<void> _remove(int id) async {
    await sl<ApiClient>().delete(ApiEndpoints.newsById(id));
  }

  Future<void> _fetch() async {
    setState(() => _failed = false);
    try {
      final items = await (widget.load ?? _load)();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _toast(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  /// The public News tab reads the shared bloc: keep it in step with what the admin just changed.
  void _syncPublic() {
    if (widget.load == null) sl<NewsBloc>().add(const RefreshNewsEvent());
  }

  Future<void> _toggle(News n, bool value) async {
    if (_busy.contains(n.id)) return;
    setState(() => _busy.add(n.id));
    try {
      await (widget.setActive ?? _setActive)(n.id, value);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final x in _items!)
            if (x.id == n.id)
              NewsModel(id: x.id, title: x.title, content: x.content, media: x.media, isActive: value, publishedAt: x.publishedAt, publishedBy: x.publishedBy, titleAr: x.titleAr, titleEn: x.titleEn, contentAr: x.contentAr, contentEn: x.contentEn)
            else
              x,
        ];
      });
      _syncPublic();
    } catch (_) {
      if (mounted) _toast('admin.action_failed');
    } finally {
      if (mounted) setState(() => _busy.remove(n.id));
    }
  }

  Future<void> _delete(News n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin.delete_news'.tr()),
        content: Text('admin.confirm_delete'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('actions.cancel'.tr())),
          TextButton(
            key: const Key('news-confirm-delete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('actions.delete'.tr(), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy.add(n.id));
    try {
      await (widget.remove ?? _remove)(n.id);
      if (!mounted) return;
      setState(() => _items = _items!.where((x) => x.id != n.id).toList());
      _syncPublic();
    } catch (_) {
      if (mounted) _toast('admin.action_failed');
    } finally {
      if (mounted) setState(() => _busy.remove(n.id));
    }
  }

  Future<void> _openForm({News? news}) async {
    final bloc = sl<NewsBloc>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BlocProvider.value(value: bloc, child: AdminNewsFormPage(news: news))),
    );
    if (result == true && mounted) {
      _fetch();
      _syncPublic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('admin.manage_news'.tr())),
      floatingActionButton: FloatingActionButton(
        key: const Key('news-add'),
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _failed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('admin.load_failed'.tr(), style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _fetch, child: Text('actions.retry'.tr())),
                ],
              ),
            )
          : items == null
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? Center(child: Text('admin.no_news'.tr()))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _NewsAdminTile(
                          news: items[i],
                          busy: _busy.contains(items[i].id),
                          onToggle: (v) => _toggle(items[i], v),
                          onEdit: () => _openForm(news: items[i]),
                          onDelete: () => _delete(items[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _NewsAdminTile extends StatelessWidget {
  final News news;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsAdminTile({required this.news, required this.busy, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('news-${news.id}'),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: news.isActive ? AppColors.tagSuccessBg : AppColors.tagNeutralBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.article_outlined, color: news.isActive ? AppColors.success : AppColors.grey, size: 20),
        ),
        title: Text(
          news.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: news.isActive ? AppColors.ink : AppColors.inkMute,
          ),
        ),
        subtitle: Text(
          news.isActive ? 'admin.active'.tr() : 'admin.inactive'.tr(),
          style: TextStyle(fontSize: 12, color: news.isActive ? AppColors.success : AppColors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(key: Key('news-switch-${news.id}'), value: news.isActive, onChanged: busy ? null : onToggle),
            IconButton(key: Key('news-edit-${news.id}'), icon: const Icon(Icons.edit_outlined, size: 20), color: AppColors.secondary, onPressed: busy ? null : onEdit),
            IconButton(key: Key('news-delete-${news.id}'), icon: const Icon(Icons.delete_outline, size: 20), color: AppColors.danger, onPressed: busy ? null : onDelete),
          ],
        ),
      ),
    );
  }
}
