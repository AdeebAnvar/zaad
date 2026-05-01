import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:pos/presentation/counter/counter_home.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static Future<({Session? session, UserModel? user})> _sessionAndProfile() async {
    final db = locator<AppDatabase>();
    final session = await db.sessionDao.getActiveSession();
    if (session == null) return (session: null, user: null);
    final user = await db.usersDao.findUserById(session.userId);
    return (session: session, user: user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sessionAndProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data;
        final session = data?.session;

        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        final profile = data?.user;

        if (session.role == 'admin') {
          return const AdminHome();
        } else {
          return CounterHome(sessionUser: profile);
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
