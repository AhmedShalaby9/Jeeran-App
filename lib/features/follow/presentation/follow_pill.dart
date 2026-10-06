import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/widgets/jv2.dart';
import '../data/follow_service.dart';

/// The Follow / Following pill. `compact` collapses "Following" to a check circle
/// so long developer names keep their width.
class FollowPill extends StatelessWidget {
  final bool following;
  final bool compact;
  final bool busy;
  final VoidCallback? onTap;

  const FollowPill({super.key, required this.following, this.compact = false, this.busy = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (compact && following) {
      return GestureDetector(
        onTap: busy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: JV2.fillFaint,
            border: Border.all(color: JV2.line),
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: JV2.inkSub),
        ),
      );
    }
    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: following ? JV2.fillFaint : JV2.navy,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: following ? JV2.line : JV2.navy),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (following) ...[
              const Icon(Icons.check_rounded, size: 12, color: JV2.inkSub),
              const SizedBox(width: 5),
            ],
            Text(
              following ? 'saved.following'.tr() : 'saved.follow'.tr(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: following ? JV2.inkSub : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A self-contained Follow button for compound and developer pages:
/// checks the current state, then toggles it optimistically.
class FollowButton extends StatefulWidget {
  final FollowType type;
  final int id;
  final bool compact;

  const FollowButton({super.key, required this.type, required this.id, this.compact = false});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final _service = sl<FollowService>();
  bool? _following; // null until we know
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service.isFollowing(widget.type, widget.id).then((v) {
      if (mounted) setState(() => _following = v);
    }).catchError((_) {
      if (mounted) setState(() => _following = false);
    });
  }

  Future<void> _toggle() async {
    final was = _following ?? false;
    setState(() {
      _following = !was;
      _busy = true;
    });
    try {
      was ? await _service.unfollow(widget.type, widget.id) : await _service.follow(widget.type, widget.id);
    } catch (_) {
      if (mounted) {
        setState(() => _following = was);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('saved.follow_failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_following == null) return const SizedBox(width: 74, height: 30);
    return FollowPill(following: _following!, compact: widget.compact, busy: _busy, onTap: _toggle);
  }
}
