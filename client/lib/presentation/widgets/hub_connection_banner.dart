import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/network/hub_connection_status_service.dart';

/// LOCAL-mode banner for offline / syncing hub connectivity.
class HubConnectionBanner extends StatelessWidget {
  const HubConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!locator.isRegistered<HubConnectionStatusService>()) {
      return const SizedBox.shrink();
    }
    final svc = locator<HubConnectionStatusService>();
    return AnimatedBuilder(
      animation: svc,
      builder: (context, _) {
        switch (svc.status) {
          case HubConnectionUiStatus.online:
            return const SizedBox.shrink();
          case HubConnectionUiStatus.offline:
            return Material(
              color: const Color(0xFFFFF3E0),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 18, color: Colors.orange.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline mode — LAN sync paused. Orders save locally and sync when the server is back.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          case HubConnectionUiStatus.syncing:
            return Material(
              color: const Color(0xFFE8F5E9),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Syncing with POS server…',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
