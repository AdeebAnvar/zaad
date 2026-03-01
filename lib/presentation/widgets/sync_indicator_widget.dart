import 'package:flutter/material.dart';
import 'package:pos/core/constants/enums.dart';

class SyncIndicator extends StatelessWidget {
  final SyncPhase status;

  const SyncIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case SyncPhase.categories || SyncPhase.items:
        color = Colors.orange;
        icon = Icons.sync;
        text = "Syncing";
        break;
      case SyncPhase.failed:
        color = Colors.red;
        icon = Icons.cloud_off;
        text = "Offline";
        break;
      case SyncPhase.success:
      default:
        color = Colors.green;
        icon = Icons.cloud_done;
        text = "Synced";
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
