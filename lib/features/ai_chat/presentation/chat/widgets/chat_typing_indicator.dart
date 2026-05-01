import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import 'chat_message_bubble.dart';

class ChatTypingIndicator extends StatelessWidget {
  final AnimationController animCtrl;
  const ChatTypingIndicator({super.key, required this.animCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: animCtrl,
                  builder: (_, __) {
                    final phase =
                        (animCtrl.value - i * 0.2).clamp(0.0, 1.0);
                    final opacity = (0.3 +
                            0.7 *
                                (phase < 0.5
                                    ? phase * 2
                                    : (1 - phase) * 2))
                        .clamp(0.0, 1.0);
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
