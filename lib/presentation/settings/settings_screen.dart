import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/settings/kitchen_settings_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _dineInSeatHandling;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final v = await AppSettingsPrefs.getDineInSeatHandlingEnabled();
    if (!mounted) return;
    setState(() {
      _dineInSeatHandling = v;
      _prefsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Settings',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_prefsLoaded && _dineInSeatHandling != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Dine In seat handling', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                    subtitle: Text(
                      _dineInSeatHandling!
                          ? 'Assign seats per order; capacity follows table chairs.'
                          : 'Tables can have multiple active orders without seat allocation.',
                      style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                    ),
                    value: _dineInSeatHandling!,
                    activeThumbColor: AppColors.primaryColor,
                    onChanged: (v) async {
                      setState(() => _dineInSeatHandling = v);
                      await AppSettingsPrefs.setDineInSeatHandlingEnabled(v);
                    },
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              CustomButton(
                width: 200,
                onPressed: () => _sync(context),
                text: 'Sync',
              ),
              const SizedBox(height: 16),
              CustomButton(
                width: 200,
                onPressed: () => _showKitchenPopup(context),
                text: 'Kitchens',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sync(BuildContext context) async {
    try {
      final db = locator<AppDatabase>();
      final serverUrl = locator<UserRepository>().getServerUrl();
      await SyncService.instance.start(db, serverUrl: serverUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, e);
      }
    }
  }

  void _showKitchenPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const KitchenSettingsDialog(),
    );
  }
}
