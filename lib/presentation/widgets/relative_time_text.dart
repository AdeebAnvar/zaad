import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos/core/utils/relative_time.dart';

/// Shows [formatRelativeTimeAgo] for [at] and rebuilds every second so the label stays live.
class RelativeTimeText extends StatefulWidget {
  const RelativeTimeText({
    super.key,
    required this.at,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final DateTime at;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  State<RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<RelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(RelativeTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.at != widget.at) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatRelativeTimeAgo(widget.at),
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
