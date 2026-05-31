import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos/core/utils/relative_time.dart';

/// Shows [formatRelativeTimeAgo] for [at].
///
/// [liveUpdates] — when false (log tables with many rows), skips per-cell timers that
/// rebuild the whole table every second and can freeze Windows UI.
class RelativeTimeText extends StatefulWidget {
  const RelativeTimeText({
    super.key,
    required this.at,
    this.style,
    this.textAlign,
    this.maxLines,
    this.liveUpdates = true,
  });

  final DateTime at;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool liveUpdates;

  @override
  State<RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<RelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.liveUpdates) _startTicker();
  }

  @override
  void didUpdateWidget(RelativeTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.at != widget.at) {
      if (widget.liveUpdates) {
        _startTicker();
      } else {
        _timer?.cancel();
        _timer = null;
      }
      if (mounted) setState(() {});
    } else if (oldWidget.liveUpdates != widget.liveUpdates) {
      if (widget.liveUpdates) {
        _startTicker();
      } else {
        _timer?.cancel();
        _timer = null;
      }
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
