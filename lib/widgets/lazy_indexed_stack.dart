import 'package:flutter/material.dart';

/// Like [IndexedStack], but only builds a child the first time it is selected.
/// Keeps visited tabs alive so forms are not reset.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _activated = List<bool>.generate(
    widget.children.length,
    (i) => i == widget.index,
  );

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activated.length != widget.children.length) {
      _activated = List<bool>.generate(
        widget.children.length,
        (i) => i < _activated.length ? _activated[i] : i == widget.index,
      );
    }
    if (!_activated[widget.index]) {
      _activated[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _activated[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
