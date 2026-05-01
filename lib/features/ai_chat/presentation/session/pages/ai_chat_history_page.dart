import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../domain/entities/chat_session.dart';
import '../bloc/chat_sessions_bloc.dart';
import '../bloc/chat_sessions_event.dart';
import '../bloc/chat_sessions_state.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_error_state.dart';
import '../widgets/chat_history_header.dart';
import '../widgets/chat_new_fab.dart';
import '../widgets/chat_session_card.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../../chat/pages/ai_chat_page.dart';

class AiChatHistoryPage extends StatelessWidget {
  const AiChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ChatSessionsBloc>()..add(const LoadChatSessions()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _openSession(ChatSession session) async {
    await Navigator.push(context, _slideRight(AiChatPage(session: session)));
    _reload();
  }

  Future<void> _openNewSession() async {
    await Navigator.push(context, _slideRight(const AiChatPage(session: null)));
    _reload();
  }

  void _reload() {
    if (mounted) {
      context.read<ChatSessionsBloc>().add(const LoadChatSessions());
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  void _confirmDelete(ChatSession session) {
    showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmDialog(sessionTitle: session.title),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<ChatSessionsBloc>().add(DeleteChatSession(session.id));
      }
    });
  }

  // ── Route helper ────────────────────────────────────────────────────────────

  PageRouteBuilder _slideRight(Widget page) => PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 350),
  );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Column(
        children: [
          ChatHistoryHeader(onNewChat: _openNewSession),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: ChatNewFab(onTap: _openNewSession),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ChatSessionsBloc, ChatSessionsState>(
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
          return ChatErrorState(
            message: state.message,
            onRetry: () =>
                context.read<ChatSessionsBloc>().add(const LoadChatSessions()),
          );
        }

        final sessions = state is ChatSessionsLoaded
            ? state.sessions
            : state is ChatSessionDeleting
            ? state.sessions
            : <ChatSession>[];

        if (sessions.isEmpty) return ChatEmptyState(onNewChat: _openNewSession);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final isDeleting =
                state is ChatSessionDeleting && state.deletingId == session.id;
            return ChatSessionCard(
              session: session,
              isDeleting: isDeleting,
              onTap: () => _openSession(session),
              onDelete: () => _confirmDelete(session),
            );
          },
        );
      },
    );
  }
}
