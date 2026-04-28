import 'package:flutter/material.dart';

/// Builds children lazily: a child is only built the first time its
/// index becomes active, then it stays alive (state & scroll position
/// are preserved). Inactive children are off-staged and their tickers
/// are paused so animations don't run in the background.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _loaded;

  @override
  void initState() {
    super.initState();
    _loaded = List.generate(widget.children.length, (i) => i == widget.index);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index && !_loaded[widget.index]) {
      setState(() => _loaded[widget.index] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (i) {
        if (!_loaded[i]) return const SizedBox.shrink();
        return Offstage(
          offstage: i != widget.index,
          child: TickerMode(
            enabled: i == widget.index,
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}
