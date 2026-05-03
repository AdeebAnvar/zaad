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
    _startTicker();
  }

  @override
  void didUpdateWidget(RelativeTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.at != widget.at) {
      _startTicker();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _refreshInterval() {
    final age = DateTime.now().difference(widget.at);
    if (age.inHours < 1) return const Duration(seconds: 1);
    return const Duration(minutes: 1);
  }

  void _startTicker() {
    _timer?.cancel();
    final interval = _refreshInterval();
    _timer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      setState(() {});
    });
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
