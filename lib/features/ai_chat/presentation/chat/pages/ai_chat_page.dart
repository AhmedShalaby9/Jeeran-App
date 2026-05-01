import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/chat_session.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/ai_chat_header.dart';
import '../widgets/chat_error_widgets.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_message_shimmer.dart';
import '../widgets/chat_typing_indicator.dart';
import '../../session/pages/ai_chat_history_page.dart';

class AiChatPage extends StatelessWidget {
  /// Null → brand-new session (created on first message send).
  final ChatSession? session;

  const AiChatPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<ChatBloc>();
        if (session != null) bloc.add(LoadChat(session!));
        return bloc;
      },
      child: _ChatView(initialSession: session),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ChatSession? initialSession;
  const _ChatView({required this.initialSession});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _typingAnimCtrl;

  @override
  void initState() {
    super.initState();
    _typingAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _send(ChatSession? currentSession) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context
        .read<ChatBloc>()
        .add(SendChatMessage(content: text, session: currentSession));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMenuSelected(String value) {
    if (value == 'new_session') {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const AiChatPage(session: null),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else if (value == 'history') {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const AiChatHistoryPage()),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (_, state) {
        if (state is ChatReady) _scrollToBottom();
      },
      builder: (context, state) {
        final ChatSession? currentSession =
            state is ChatReady ? state.session : widget.initialSession;
        final List<ChatMessage> messages =
            state is ChatReady ? state.messages : [];
        final bool isSending = state is ChatReady && state.isSending;
        final String? sendError =
            state is ChatReady ? state.sendError : null;
        final bool isLoading = state is ChatLoading;
        final String? loadError =
            state is ChatError ? state.message : null;

        final sessionTitle = currentSession?.title ??
            (widget.initialSession == null
                ? 'ai_chat.new_conversation'.tr()
                : '…');

        return Scaffold(
          backgroundColor: AppColors.chatBackground,
          body: Column(
            children: [
              AiChatHeader(
                sessionTitle: sessionTitle,
                onMenuSelected: _onMenuSelected,
              ),
              if (isLoading)
                const Expanded(child: ChatMessageShimmerList())
              else if (loadError != null)
                Expanded(child: ChatLoadError(message: loadError))
              else
                Expanded(child: _MessageList(
                  messages: messages,
                  isSending: isSending,
                  scrollController: _scrollController,
                  typingAnimCtrl: _typingAnimCtrl,
                )),
              if (sendError != null) ChatSendErrorBanner(message: sendError),
              ChatInputBar(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isSending && loadError == null,
                onSend: () => _send(currentSession),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Message list (extracted to keep _ChatViewState lean) ─────────────────────
class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isSending;
  final ScrollController scrollController;
  final AnimationController typingAnimCtrl;

  const _MessageList({
    required this.messages,
    required this.isSending,
    required this.scrollController,
    required this.typingAnimCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (isSending && index == messages.length) {
          return ChatTypingIndicator(animCtrl: typingAnimCtrl);
        }
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}
