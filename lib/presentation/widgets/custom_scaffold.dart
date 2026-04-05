import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/custom_app_bar.dart';
import 'package:pos/presentation/widgets/custom_drawer.dart';

class CustomScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// 'dashboard' | 'take_away' | 'take_away_log' — drives app bar nav icons to other screens.
  final String? appBarScreen;

  /// When set (e.g. counter opened from Dine In floor plan), shows a leading back arrow that runs this callback.
  final VoidCallback? onBack;

  const CustomScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBarScreen,
    this.onBack,
  });

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  User? user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      // Get user from active session
      final session = await locator<AppDatabase>().sessionDao.getActiveSession();
      if (session != null && mounted) {
        final loadedUser = await locator<AppDatabase>().usersDao.findUserById(session.userId);
        if (mounted) {
          setState(() {
            user = loadedUser;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final drawerWidth = size.width > 600 ? size.width / 5 : size.width / 1.4;

    return Scaffold(
      appBar: CustomAppBar(title: widget.title, screen: widget.appBarScreen, onBack: widget.onBack),
      drawer: PosDrawer(
        width: drawerWidth,
        companyLogo: user?.companyLogoLocal ?? "",
        userName: user?.username ?? "",
        role: user?.role ?? "",
        companyName: user?.companyName ?? "",
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      body: widget.body,
    );
  }
}
