import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[const AiAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.userBubbleEnd,
                            ],
                          )
                        : null,
                    color: isUser ? null : AppColors.surface,
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.5,
                          ),
                        )
                      : _AiMarkdownBody(content: message.content),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), const UserAvatar()],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Markdown renderer for AI replies ─────────────────────────────────────────
class _AiMarkdownBody extends StatelessWidget {
  final String content;
  const _AiMarkdownBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 14.5,
          height: 1.55,
        ),
        strong: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
        em: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 14.5,
          fontStyle: FontStyle.italic,
        ),
        listBullet: const TextStyle(
          color: AppColors.secondary,
          fontSize: 14.5,
        ),
        orderedListAlign: WrapAlignment.start,
        unorderedListAlign: WrapAlignment.start,
        listIndent: 16,
        blockSpacing: 6,
        h1: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        h2: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        h3: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        code: const TextStyle(
          color: AppColors.secondary,
          fontSize: 13.5,
          fontFamily: 'monospace',
          backgroundColor: AppColors.chatBackground,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.chatBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
      ),
    );
  }
}

// ── Shared avatars (used by bubble & typing indicator) ────────────────────────

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 16),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navButtonBg,
      ),
      child: const Icon(Icons.person_rounded,
          color: AppColors.inkSub, size: 18),
    );
  }
}
