import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../seller_request/data/models/seller_request_model.dart';
import '../../../seller_request/presentation/bloc/seller_request_bloc.dart';
import '../../../seller_request/presentation/bloc/seller_request_event.dart';
import '../../../seller_request/presentation/bloc/seller_request_state.dart';

class AdminSellerRequestsPage extends StatelessWidget {
  const AdminSellerRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SellerRequestBloc>()
        ..add(const FetchSellerRequestsEvent()),
      child: const _AdminSellerRequestsView(),
    );
  }
}

class _AdminSellerRequestsView extends StatefulWidget {
  const _AdminSellerRequestsView();

  @override
  State<_AdminSellerRequestsView> createState() =>
      _AdminSellerRequestsViewState();
}

class _AdminSellerRequestsViewState extends State<_AdminSellerRequestsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _tabs = const ['all', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _tabs[_tabController.index] == 'all'
            ? null
            : _tabs[_tabController.index];
        context.read<SellerRequestBloc>().add(
              FetchSellerRequestsEvent(status: status),
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmAction({
    required BuildContext context,
    required bool isApprove,
    required SellerRequestModel request,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isApprove ? 'admin.approve'.tr() : 'admin.reject'.tr(),
        ),
        content: Text(
          isApprove
              ? 'admin.approve_confirm'.tr(
                  namedArgs: {'name': request.user.name ?? request.user.phone ?? ''},
                )
              : 'admin.reject_confirm'.tr(
                  namedArgs: {'name': request.user.name ?? request.user.phone ?? ''},
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('actions.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isApprove) {
                context
                    .read<SellerRequestBloc>()
                    .add(ApproveSellerRequestEvent(request.id));
              } else {
                context
                    .read<SellerRequestBloc>()
                    .add(RejectSellerRequestEvent(request.id));
              }
            },
            child: Text(
              isApprove ? 'admin.approve'.tr() : 'admin.reject'.tr(),
              style: TextStyle(
                color: isApprove ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshCurrentTab(BuildContext context) {
    final status = _tabs[_tabController.index] == 'all'
        ? null
        : _tabs[_tabController.index];
    context.read<SellerRequestBloc>().add(
          FetchSellerRequestsEvent(status: status),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('admin.seller_requests'.tr()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs
              .map((t) => Tab(text: 'admin.tab_$t'.tr()))
              .toList(),
        ),
      ),
      body: BlocConsumer<SellerRequestBloc, SellerRequestState>(
        listener: (context, state) {
          if (state is SellerRequestActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('admin.action_success'.tr())),
            );
            _refreshCurrentTab(context);
          } else if (state is SellerRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is SellerRequestLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerRequestError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _refreshCurrentTab(context),
                    child: Text('actions.retry'.tr()),
                  ),
                ],
              ),
            );
          }
          if (state is SellerRequestsLoaded) {
            if (state.requests.isEmpty) {
              return Center(child: Text('admin.no_requests'.tr()));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final req = state.requests[index];
                return _SellerRequestTile(
                  request: req,
                  onApprove: req.status == 'pending'
                      ? () => _confirmAction(
                            context: context,
                            isApprove: true,
                            request: req,
                          )
                      : null,
                  onReject: req.status == 'pending'
                      ? () => _confirmAction(
                            context: context,
                            isApprove: false,
                            request: req,
                          )
                      : null,
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

class _SellerRequestTile extends StatelessWidget {
  final SellerRequestModel request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _SellerRequestTile({
    required this.request,
    this.onApprove,
    this.onReject,
  });

  Color _statusColor() => switch (request.status) {
        'approved' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => AppColors.gold,
      };

  String _statusLabel() => switch (request.status) {
        'approved' => 'admin.approved'.tr(),
        'rejected' => 'admin.rejected'.tr(),
        _ => 'admin.pending'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tagPrimaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? '—',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (user.phone != null)
                      Text(
                        user.phone!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSub,
                        ),
                      ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMute,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(),
                  ),
                ),
              ),
            ],
          ),
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('admin.reject'.tr()),
                    ),
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: 8),
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('admin.approve'.tr()),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
