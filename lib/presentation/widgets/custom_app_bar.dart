import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import '../../core/constants/colors.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  /// Current screen: 'dashboard' | 'take_away' | 'take_away_log'. Used to show nav icons to the other screens.
  final String? screen;

  /// Back arrow (e.g. return to Dine In floor plan from counter).
  final VoidCallback? onBack;

  const CustomAppBar({super.key, required this.title, this.screen, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  DateTime? _lastSyncAt;
  int? _expiryDaysLeft;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  Future<void> _loadMeta() async {
    final value = await AppSettingsPrefs.getLastManualSyncAt();
    int? daysLeft;
    try {
      final db = locator<AppDatabase>();
      final session = await db.sessionDao.getActiveSession();
      if (session != null) {
        final branch = await db.branchesDao.getBranchById(session.branchId);
        if (branch != null) {
          daysLeft = _daysUntil(branch.expiryDate.toLocal());
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _lastSyncAt = value;
      _expiryDaysLeft = daysLeft;
    });
  }

  Future<void> _runManualSync() async {
    await AppNavigator.pushNamed(
      Routes.autoSyncScreen,
      args: {'manual': true},
    );
    await _loadMeta();
  }

  String _lastSyncLabel() {
    if (_lastSyncAt == null) return 'Not synced';
    return RuntimeAppSettings.formatDateTime(_lastSyncAt!.toLocal());
  }

  Widget? _buildExpiryBadge() {
    final days = _expiryDaysLeft;
    if (days == null || days < 0 || days > 10) return null;
    final isCritical = days <= 5;
    final bg = isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1);
    final border = isCritical ? const Color(0xFFE53935) : const Color(0xFFF9A825);
    final text = days == 0 ? 'Expires today' : 'Expires in $days day${days == 1 ? '' : 's'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: border),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppStyles.getMediumTextStyle(fontSize: 11, color: border),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDashboard = widget.screen == 'dashboard';
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 560;
    final showSyncText = w >= 760;
    final iconPad = compact ? 5.0 : 6.0;
    final iconSize = compact ? 20.0 : 22.0;
    final leftWidth = widget.onBack != null ? (compact ? 136.0 : 168.0) : (compact ? 84.0 : 95.0);
    final expiryBadge = _buildExpiryBadge();

    return AppBar(
      backgroundColor: Colors.white,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      centerTitle: true,
      leadingWidth: leftWidth,
      leading: Row(
        children: [
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                margin: EdgeInsets.fromLTRB(10, compact ? 12 : 10, 4, compact ? 12 : 10),
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
              ),
            ),
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              margin: EdgeInsets.all(widget.onBack != null ? 4 : (compact ? 9 : 10)),
              padding: EdgeInsets.all(iconPad),
              decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(6)),
              child: Icon(Icons.menu, color: Colors.white, size: iconSize),
            ),
          ),
          if (!isDashboard)
            GestureDetector(
              onTap: () => AppNavigator.pushReplacementNamed(Routes.dashboard),
              child: Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.home_filled, color: Colors.white, size: iconSize),
              ),
            ),
        ],
      ),
      title: Text(
        widget.title,
        // '${MediaQuery.sizeOf(context).width}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyles.getSemiBoldTextStyle(fontSize: compact ? 16 : 18),
      ),
      actions: [
        if (expiryBadge != null) ...[
          expiryBadge,
          const SizedBox(width: 8),
        ],
        if (showSyncText) ...[
          Text(
            _lastSyncLabel(),
            style: AppStyles.getRegularTextStyle(
              fontSize: 11,
              color: AppColors.hintFontColor,
            ),
          ),
          const SizedBox(width: 6),
        ],
        const SizedBox(width: 6),
        Text(
          'Sync',
          style: AppStyles.getSemiBoldTextStyle(fontSize: 13),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Sync now',
          onPressed: _runManualSync,
          icon: const Icon(Icons.sync),
          color: AppColors.primaryColor,
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        ),
        SizedBox(width: compact ? 4 : 8),
      ],
    );
  }
}
