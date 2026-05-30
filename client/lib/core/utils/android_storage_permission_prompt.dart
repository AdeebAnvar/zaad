import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time (per install) prompt so Android can store data under **Documents/ZaadPOS**.
class AndroidStoragePermissionPrompt extends StatefulWidget {
  const AndroidStoragePermissionPrompt({super.key, required this.child});

  final Widget child;

  static const _declinedKey = 'zaadpos_android_storage_prompt_declined';

  @override
  State<AndroidStoragePermissionPrompt> createState() => _AndroidStoragePermissionPromptState();
}

class _AndroidStoragePermissionPromptState extends State<AndroidStoragePermissionPrompt> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
    } else {
      _checked = true;
    }
  }

  Future<void> _maybePrompt() async {
    if (!mounted || _checked) return;
    _checked = true;

    if (AppDirectories.temporaryForceAndroidInternalStorage) return;

    if (await AppDirectories.androidHasAllFilesAccess()) return;
    if (await AppDirectories.androidPublicDocumentsReady) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AndroidStoragePermissionPrompt._declinedKey) == true) return;
    if (!mounted) return;

    await _showPrompt(prefs);
  }

  Future<void> _showPrompt(SharedPreferences prefs) async {
    if (!mounted) return;

    final allow = await showAppConfirmDialog(
      context,
      title: 'Storage access',
      message:
          'Allow Zaad POS to save data in Documents/ZaadPOS?\n\n'
          'On Android 11+, this is not under normal Permissions. '
          'The next screen is Special app access → All files access → turn ON for Zaad POS.',
      confirmText: 'Allow',
      cancelText: 'Not now',
    );

    if (!mounted) return;

    if (allow != true) {
      await prefs.setBool(AndroidStoragePermissionPrompt._declinedKey, true);
      return;
    }

    final granted = await AppDirectories.requestAndroidPublicStorageAccess();
    if (!mounted) return;

    if (granted) {
      await prefs.remove(AndroidStoragePermissionPrompt._declinedKey);
      await AppDirectories.migrateAndroidInternalToPublicDocumentsIfNeeded();
      return;
    }

    final openSettings = await showAppConfirmDialog(
      context,
      title: 'Permission needed',
      message:
          'Storage was not granted. Zaad POS will keep data in app storage. '
          'You can enable "All files access" in system settings to use Documents/ZaadPOS.',
      confirmText: 'Open settings',
      cancelText: 'Continue',
    );

    if (openSettings == true) {
      await AppDirectories.openAndroidAllFilesAccessSettings();
    } else {
      await prefs.setBool(AndroidStoragePermissionPrompt._declinedKey, true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
