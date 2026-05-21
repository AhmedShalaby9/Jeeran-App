import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../news/domain/entities/news.dart';
import '../../../news/presentation/bloc/news_bloc.dart';
import '../../../news/presentation/bloc/news_event.dart';
import '../../../news/presentation/bloc/news_state.dart';
import 'admin_news_form_page.dart';

class AdminNewsListPage extends StatelessWidget {
  const AdminNewsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<NewsBloc>()..add(const RefreshNewsEvent()),
      child: const _AdminNewsListView(),
    );
  }
}

class _AdminNewsListView extends StatelessWidget {
  const _AdminNewsListView();

  Future<void> _openForm(BuildContext context, {News? news}) async {
    final bloc = context.read<NewsBloc>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AdminNewsFormPage(news: news),
        ),
      ),
    );
    if (result == true && context.mounted) {
      bloc.add(const RefreshNewsEvent());
    }
  }

  void _confirmDelete(BuildContext context, News news) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('admin.delete_news'.tr()),
        content: Text('admin.confirm_delete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('actions.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NewsBloc>().add(DeleteNewsEvent(news.id));
            },
            child: Text(
              'actions.delete'.tr(),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('admin.manage_news'.tr())),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<NewsBloc, NewsState>(
        listener: (context, state) {
          if (state is NewsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('admin.action_success'.tr())),
            );
            context.read<NewsBloc>().add(const RefreshNewsEvent());
          } else if (state is NewsActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is NewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NewsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<NewsBloc>().add(const RefreshNewsEvent()),
                    child: Text('actions.retry'.tr()),
                  ),
                ],
              ),
            );
          }
          if (state is NewsLoaded) {
            if (state.news.isEmpty) {
              return Center(child: Text('admin.no_news'.tr()));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.news.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = state.news[index];
                return _NewsAdminTile(
                  news: item,
                  onEdit: () => _openForm(context, news: item),
                  onDelete: () => _confirmDelete(context, item),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NewsAdminTile extends StatelessWidget {
  final News news;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsAdminTile({
    required this.news,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: news.isActive
                ? AppColors.tagSuccessBg
                : AppColors.tagNeutralBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.article_outlined,
            color: news.isActive ? AppColors.success : AppColors.grey,
            size: 20,
          ),
        ),
        title: Text(
          news.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(
          news.isActive ? 'admin.active'.tr() : 'admin.inactive'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: news.isActive ? AppColors.success : AppColors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.secondary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.danger,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
