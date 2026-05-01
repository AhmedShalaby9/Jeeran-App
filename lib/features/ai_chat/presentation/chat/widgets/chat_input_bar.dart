import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && widget.enabled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              // Attachment placeholder
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navButtonBg,
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.inkSub, size: 22),
              ),
              const SizedBox(width: 8),
              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.chatBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: widget.enabled,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        fontSize: 14.5, color: AppColors.onBackground),
                    decoration: InputDecoration(
                      hintText: 'ai_chat.ask_hint'.tr(),
                      hintStyle: const TextStyle(
                          color: AppColors.grey, fontSize: 14.5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) {
                      if (canSend) widget.onSend();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: canSend
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.secondary, AppColors.secondaryDark],
                        )
                      : null,
                  color: canSend ? null : AppColors.navButtonBg,
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color:
                                AppColors.secondary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: InkWell(
                  onTap: canSend ? widget.onSend : null,
                  borderRadius: BorderRadius.circular(21),
                  child: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: canSend ? Colors.white : AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
