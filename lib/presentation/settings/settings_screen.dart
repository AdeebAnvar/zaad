import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/settings/kitchen_settings_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Settings',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
      await SyncService.instance.start(db);
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
