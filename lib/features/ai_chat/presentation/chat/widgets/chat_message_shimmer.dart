import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatMessageShimmerList extends StatelessWidget {
  const ChatMessageShimmerList({super.key});

  // Alternating pattern: AI (left), User (right), AI, User, AI
  static const List<_BubbleShape> _shapes = [
    _BubbleShape(isUser: false, lines: 3, width: 0.72),
    _BubbleShape(isUser: true,  lines: 1, width: 0.40),
    _BubbleShape(isUser: false, lines: 2, width: 0.60),
    _BubbleShape(isUser: true,  lines: 2, width: 0.55),
    _BubbleShape(isUser: false, lines: 4, width: 0.75),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _shapes.length,
      itemBuilder: (context, index) {
        final shape = _shapes[index];
        return _ShimmerBubble(
          isUser: shape.isUser,
          lines: shape.lines,
          widthFactor: shape.width,
        );
      },
    );
  }
}

class _BubbleShape {
  final bool isUser;
  final int lines;
  final double width;
  const _BubbleShape({
    required this.isUser,
    required this.lines,
    required this.width,
  });
}

class _ShimmerBubble extends StatelessWidget {
  final bool isUser;
  final int lines;
  final double widthFactor;

  const _ShimmerBubble({
    required this.isUser,
    required this.lines,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * widthFactor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI avatar circle
            Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: const Color(0xFFF8FAFC),
            child: Container(
              width: maxWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines, (i) {
                  final isLast = i == lines - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                    child: Container(
                      width: isLast && lines > 1 ? maxWidth * 0.55 : double.infinity,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar circle
            Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navButtonBg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
