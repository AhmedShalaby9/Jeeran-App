import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../domain/entities/chat_session.dart';
import '../bloc/chat_sessions_bloc.dart';
import '../bloc/chat_sessions_event.dart';
import '../bloc/chat_sessions_state.dart';
import '../../chat/pages/ai_chat_page.dart';

class AiChatHistoryPage extends StatelessWidget {
  const AiChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ChatSessionsBloc>()..add(const LoadChatSessions()),
      child: const _AiChatHistoryView(),
    );
  }
}

class _AiChatHistoryView extends StatefulWidget {
  const _AiChatHistoryView();

  @override
  State<_AiChatHistoryView> createState() => _AiChatHistoryViewState();
}

class _AiChatHistoryViewState extends State<_AiChatHistoryView> {
  Future<void> _openSession(ChatSession session) async {
    await Navigator.push(
      context,
      _slideRoute(AiChatPage(session: session)),
    );
    if (mounted) {
      context.read<ChatSessionsBloc>().add(const LoadChatSessions());
    }
  }

  Future<void> _openNewSession() async {
    await Navigator.push(
      context,
      _slideRoute(const AiChatPage(session: null)),
    );
    if (mounted) {
      context.read<ChatSessionsBloc>().add(const LoadChatSessions());
    }
  }

  void _confirmDelete(ChatSession session) {
    showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(title: session.title),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<ChatSessionsBloc>().add(DeleteChatSession(session.id));
      }
    });
  }

  PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _HistoryHeader(onNewChat: _openNewSession),
          Expanded(
            child: BlocBuilder<ChatSessionsBloc, ChatSessionsState>(
              builder: (context, state) {
                if (state is ChatSessionsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                if (state is ChatSessionsError) {
                  return _ErrorState(
                    message: state.message,
                    onRetry: () => context
                        .read<ChatSessionsBloc>()
                        .add(const LoadChatSessions()),
                  );
                }

                final sessions = state is ChatSessionsLoaded
                    ? state.sessions
                    : state is ChatSessionDeleting
                        ? state.sessions
                        : <ChatSession>[];

                if (sessions.isEmpty) {
                  return _EmptyState(onNewChat: _openNewSession);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isDeleting = state is ChatSessionDeleting &&
                        state.deletingId == session.id;
                    return _SessionCard(
                      session: session,
                      isDeleting: isDeleting,
                      onTap: () => _openSession(session),
                      onDelete: () => _confirmDelete(session),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _NewChatFab(onTap: _openNewSession),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HistoryHeader extends StatelessWidget {
  final VoidCallback onNewChat;
  const _HistoryHeader({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1A2E4A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, Color(0xFF1D8FC0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jeeran AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Chat History',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_note_rounded,
                      color: Colors.white, size: 22),
                  tooltip: 'New Chat',
                  onPressed: onNewChat,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isDeleting ? 0.45 : 1.0,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.hardEdge,
          elevation: 1.5,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: isDeleting ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.secondary, Color(0xFF1D8FC0)],
                      ),
                    ),
                    child: isDeleting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(session.updatedAt),
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5, top: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text(
                              'Tap to continue conversation',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkMute,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  if (!isDeleting) _SessionMenuButton(onDelete: onDelete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Session Card Menu ─────────────────────────────────────────────────────────
class _SessionMenuButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _SessionMenuButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.inkMute, size: 20),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 8),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 20),
              SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.secondary, Color(0xFF1D8FC0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new chat and let Jeeran AI\nhelp you find your perfect property.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.inkMute, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Start New Chat',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.grey, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.inkMute, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── New Chat FAB ──────────────────────────────────────────────────────────────
class _NewChatFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NewChatFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text('New Chat',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}

// ── Delete Confirm Dialog ─────────────────────────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  const _DeleteConfirmDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Conversation',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackground),
            ),
            const SizedBox(height: 8),
            Text(
              '"$title" will be permanently deleted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.inkMute, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkSub,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
