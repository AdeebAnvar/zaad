import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/user_model.dart';
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
  BranchModel? branchModel;
  UserModel? user;
  int? branchId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final cached = locator<CurrentCounterSession>();
      if (cached.user != null && cached.branch != null) {
        if (mounted) {
          setState(() {
            branchModel = cached.branch;
            user = cached.user;
            _isLoading = false;
          });
        }
        return;
      }

      final session =
          await locator<AppDatabase>().sessionDao.getActiveSession();
      if (session != null && mounted) {
        final loadedBranch = await locator<AppDatabase>()
            .branchesDao
            .getBranchById(session.branchId);
        final loadedUser =
            await locator<AppDatabase>().usersDao.findUserById(session.userId);

        if (mounted) {
          cached.setProfile(u: loadedUser, b: loadedBranch);
          setState(() {
            branchModel = loadedBranch;
            user = loadedUser;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        cached.clear();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        locator<CurrentCounterSession>().clear();
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

    final branchName = (branchModel?.branchName ?? '').trim();
    final screenTitle = widget.title.trim();
    final appBarTitle = [
      if (branchName.isNotEmpty) branchName,
      if (screenTitle.isNotEmpty &&
          screenTitle.toLowerCase() != branchName.toLowerCase())
        screenTitle,
    ].join(' - ');

    return Scaffold(
      appBar: CustomAppBar(
        title: appBarTitle,
        screen: widget.appBarScreen,
        onBack: widget.onBack,
      ),
      drawer: PosDrawer(
        width: drawerWidth,
        companyLogo: branchModel?.localImage ?? '',
        userName: user?.name ?? "",
        role: user?.type.name ?? "",
        companyName: branchModel?.branchName ?? "",
        sessionUser: user,
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      body: widget.body,
    );
  }
}
