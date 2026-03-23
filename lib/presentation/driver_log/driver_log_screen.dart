import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class DriverLogScreen extends StatelessWidget {
  const DriverLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Driver Log',
      appBarScreen: 'driver_log',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Driver Log',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
