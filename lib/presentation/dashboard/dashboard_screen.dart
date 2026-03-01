import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/counter/counter_home.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: locator<AppDatabase>().sessionDao.getActiveSession(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data;

        if (session == null) {
          // safety fallback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        if (session.role == "admin") {
          return const AdminHome();
        } else {
          return CounterHome(id: session.id);
        }
      },
    );
  }
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Admin Dashboard (Admin Module Coming Soon)"),
      ),
    );
  }
}
